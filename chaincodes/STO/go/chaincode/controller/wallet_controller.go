package controller

import (
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"

	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ledgermanager"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/token"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/wallet"
)

func (s *SmartContract) CreateWallet(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		return nil, err
	}

	_, err = ccutils.GetID(ctx)
	if err != nil {
		logger.Errorf("failed to get client id: %v", err)
		return nil, err
	}

	// 23-02-14. web server request로 대체
	// tokenWalletId := ccutils.GetAddress([]byte(id))

	requireParameterFields := []string{token.FieldTokenWalletId, token.FieldRole, token.FieldAccountNumber}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldTokenWalletId, token.FieldRole, token.FieldAccountNumber}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// args
	tokenWalletId := args[token.FieldTokenWalletId].(string)
	role := args[token.FieldRole].(string)
	accountNumber := args[token.FieldAccountNumber].(string)

	// create wallet
	walletStruct := wallet.TokenWallet{}
	walletStruct.DocType = wallet.DocType_TokenWallet
	walletStruct.TokenWalletId = tokenWalletId
	walletStruct.Role = role
	walletStruct.AccountNumber = accountNumber
	partitionTokenMap := make(map[string][]token.PartitionToken)
	walletStruct.PartitionTokens = partitionTokenMap
	walletStruct.IsLocked = false
	walletStruct.CreatedDate = ccutils.CreateKstTimeAndSecond()
	walletStruct.UpdatedDate = walletStruct.CreatedDate

	newWallet, err := wallet.CreateWallet(ctx, walletStruct)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	retData, err := ccutils.StructToMap(newWallet)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : CreateWallet \n walletId : %v", tokenWalletId)
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], retData)
}

func (s *SmartContract) TransferByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		return nil, err
	}

	id, err := ccutils.GetID(ctx)
	if err != nil {
		logger.Errorf("failed to get client id: %v", err)
		return nil, err
	}

	requireParameterFields := []string{token.FieldRecipient, token.FieldPartition, token.FieldAmount}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldRecipient, token.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	int64ParameterFields := []string{token.FieldAmount}
	err = ccutils.CheckRequireTypeInt64(int64ParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// args
	owner := ccutils.GetAddress([]byte(id))
	recipient := args[token.FieldRecipient].(string)
	partition := args[token.FieldPartition].(string)
	amount := int64(args[token.FieldAmount].(float64))

	if amount <= 0 {
		logger.Errorf("tranfer amount must be a positive integer")
		return nil, fmt.Errorf("tranfer amount must be a positive integer")
	}

	err = _transferByPartition(ctx, owner, recipient, partition, amount)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	transferEvent := ccutils.TransferEvent{ctx.GetStub().GetTxID(), "Transfer", owner, recipient, partition, amount}
	err = transferEvent.EmitTransferEvent(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : TransferByPartition \n owner : %v, recipient : %v, token : %v, amount : %v", owner, recipient, partition, amount)
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
}

func (s *SmartContract) TransferFromByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		return nil, err
	}

	id, err := ccutils.GetID(ctx)
	if err != nil {
		logger.Errorf("failed to get client id: %v", err)
		return nil, err
	}

	requireParameterFields := []string{token.FieldFrom, token.FieldTo, token.FieldPartition, token.FieldAmount}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldFrom, token.FieldTo, token.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	int64ParameterFields := []string{token.FieldAmount}
	err = ccutils.CheckRequireTypeInt64(int64ParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// args
	spender := ccutils.GetAddress([]byte(id))
	from := args[token.FieldFrom].(string)
	to := args[token.FieldTo].(string)
	partition := args[token.FieldPartition].(string)
	amount := int64(args[token.FieldAmount].(float64))

	if amount <= 0 {
		logger.Errorf("transfer amount must be a positive integer")
		return nil, fmt.Errorf("transfer amount must be a positive integer")
	}

	allowanceByPartition, err := token.AllowanceByPartition(ctx, from, spender, partition)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	allowance := allowanceByPartition.Amount
	if allowance < amount {
		logger.Errorf("Allowance is less than value")
		return nil, fmt.Errorf("Allowance is less than value")
	}

	// Decrease the allowance
	updatedAllowance := allowance - amount
	err = _approveByPartition(ctx, from, spender, partition, updatedAllowance)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	err = _transferByPartition(ctx, from, to, partition, amount)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	transferEvent := ccutils.TransferEvent{ctx.GetStub().GetTxID(), "Transfer", from, to, partition, amount}
	err = transferEvent.EmitTransferEvent(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : TransferFromByPartition \n from : %v, to : %v, token : %v, amount : %v", from, to, partition, amount)
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
}

func _transferByPartition(ctx contractapi.TransactionContextInterface, from string, to string, partition string, value int64) error {

	transferByPartition := token.TransferByPartitionStruct{}
	transferByPartition.From = from
	transferByPartition.To = to
	transferByPartition.Partition = partition
	transferByPartition.Amount = value

	err := wallet.TransferByPartition(ctx, transferByPartition)
	if err != nil {
		logger.Error(err)
		return err
	}

	return nil
}

func (s *SmartContract) MintByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		return nil, err
	}

	_, err = ccutils.GetID(ctx)
	if err != nil {
		logger.Errorf("failed to get client id: %v", err)
		return nil, err
	}

	requireParameterFields := []string{token.FieldCaller, token.FieldPartition, token.FieldAmount}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldCaller, token.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	int64ParameterFields := []string{token.FieldAmount}
	err = ccutils.CheckRequireTypeInt64(int64ParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// args Data
	// minter := ccutils.GetAddress([]byte(id))
	minter := args[token.FieldCaller].(string)
	partition := args[token.FieldPartition].(string)
	amount := int64(args[token.FieldAmount].(float64))

	if amount <= 0 {
		logger.Errorf("mint amount must be a positive integer")
		return nil, fmt.Errorf("mint amount must be a positive integer")
	}

	mintByPartition := token.MintByPartitionStruct{Minter: minter, Partition: partition, Amount: amount}

	err = wallet.MintByPartition(ctx, mintByPartition)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	transferEvent := ccutils.TransferEvent{ctx.GetStub().GetTxID(), "Transfer", "medium", minter, partition, amount}
	err = transferEvent.EmitTransferEvent(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : MintByPartition")
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
}

func (s *SmartContract) BurnByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		return nil, err
	}

	_, err = ccutils.GetID(ctx)
	if err != nil {
		logger.Errorf("failed to get client id: %v", err)
		return nil, err
	}

	requireParameterFields := []string{token.FieldCaller, token.FieldPartition, token.FieldAmount}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldCaller, token.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	int64ParameterFields := []string{token.FieldAmount}
	err = ccutils.CheckRequireTypeInt64(int64ParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// args
	// minter := ccutils.GetAddress([]byte(id))
	minter := args[token.FieldCaller].(string)
	partition := args[token.FieldPartition].(string)
	amount := int64(args[token.FieldAmount].(float64))

	if amount <= 0 {
		logger.Errorf("burn amount must be a positive integer")
		return nil, fmt.Errorf("burn amount must be a positive integer")
	}

	burnByPartition := token.MintByPartitionStruct{Minter: minter, Partition: partition, Amount: amount}

	err = wallet.BurnByPartition(ctx, burnByPartition)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	transferEvent := ccutils.TransferEvent{ctx.GetStub().GetTxID(), "Transfer", minter, "", partition, amount}
	err = transferEvent.EmitTransferEvent(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : BurnByPartition")
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
}

func (s *SmartContract) GetTokenWalletList(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	requireParameterFields := []string{ledgermanager.PageSize, ledgermanager.Bookmark}
	err := ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{ledgermanager.Bookmark}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	int64ParameterFields := []string{ledgermanager.PageSize}
	err = ccutils.CheckTypeInt64(int64ParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	dateParameterFields := []string{ledgermanager.StartDate, ledgermanager.EndDate}
	err = ccutils.CheckFormatDate(dateParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	pageSize := int32(args[ledgermanager.PageSize].(float64))
	bookmark := args[ledgermanager.Bookmark].(string)

	var bytes []byte
	bytes, err = wallet.GetTokenWalletList(args, pageSize, bookmark, ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success Query Token Wallet List")
	return ccutils.GenerateSuccessResponseByteArray(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], bytes)
}

func (s *SmartContract) GetAdminWallet(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	requireParameterFields := []string{ledgermanager.PageSize, ledgermanager.Bookmark}
	err := ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{ledgermanager.Bookmark}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	int64ParameterFields := []string{ledgermanager.PageSize}
	err = ccutils.CheckTypeInt64(int64ParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	dateParameterFields := []string{ledgermanager.StartDate, ledgermanager.EndDate}
	err = ccutils.CheckFormatDate(dateParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	pageSize := int32(args[ledgermanager.PageSize].(float64))
	bookmark := args[ledgermanager.Bookmark].(string)

	var bytes []byte
	bytes, err = wallet.GetAdminWallet(args, pageSize, bookmark, ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success Query Admin Wallet")
	return ccutils.GenerateSuccessResponseByteArray(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], bytes)
}
