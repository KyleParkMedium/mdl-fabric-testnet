package controller

import (
	"fmt"

	"github.com/KyleParkMedium/mdl-chaincode/chaincode/ccutils"
	"github.com/KyleParkMedium/mdl-chaincode/chaincode/ledgermanager"
	"github.com/KyleParkMedium/mdl-chaincode/chaincode/services/token"
	"github.com/KyleParkMedium/mdl-chaincode/chaincode/services/wallet"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func (s *SmartContract) CreateWallet(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	err := ccutils.GetMSPID(ctx)
	if err != nil {
		return nil, err
	}

	id, err := ccutils.GetID(ctx)
	if err != nil {
		return nil, err
	}

	// 우선 msp id 로 발급
	tokenWalletId := ccutils.GetAddress([]byte(id))

	partitionTokenMap := make(map[string][]token.PartitionToken)

	walletStruct := wallet.TokenWallet{}
	walletStruct.TokenWalletId = tokenWalletId
	walletStruct.PartitionTokens = partitionTokenMap

	newWallet, err := wallet.CreateWallet(ctx, walletStruct)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	retData, err := ccutils.StructToMap(newWallet)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], retData)
}

func (s *SmartContract) TransferByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	err := ccutils.GetMSPID(ctx)
	if err != nil {
		return nil, err
	}

	id, err := ccutils.GetID(ctx)
	if err != nil {
		return nil, err
	}

	requireParameterFields := []string{token.FieldRecipient, token.FieldPartition, token.FieldAmount}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldRecipient, token.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	int64ParameterFields := []string{token.FieldAmount}
	err = ccutils.CheckRequireTypeInt64(int64ParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	// args Data
	owner := ccutils.GetAddress([]byte(id))
	recipient := args[token.FieldRecipient].(string)
	partition := args[token.FieldPartition].(string)
	amount := int64(args[token.FieldAmount].(float64))

	if amount <= 0 {
		return nil, fmt.Errorf("mint amount must be a positive integer")
	}

	err = _transferByPartition(ctx, owner, recipient, partition, amount)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	transferEvent := ccutils.Event{ctx.GetStub().GetTxID(), "Transfer", owner, recipient, partition, amount}
	err = transferEvent.EmitTransferEvent(ctx)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
}

func (s *SmartContract) TransferFromByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	err := ccutils.GetMSPID(ctx)
	if err != nil {
		return nil, err
	}

	id, err := ccutils.GetID(ctx)
	if err != nil {
		return nil, err
	}

	requireParameterFields := []string{token.FieldFrom, token.FieldTo, token.FieldPartition, token.FieldAmount}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldFrom, token.FieldTo, token.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	int64ParameterFields := []string{token.FieldAmount}
	err = ccutils.CheckRequireTypeInt64(int64ParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	// args Data
	spender := ccutils.GetAddress([]byte(id))
	from := args[token.FieldFrom].(string)
	to := args[token.FieldTo].(string)
	partition := args[token.FieldPartition].(string)
	amount := int64(args[token.FieldAmount].(float64))

	if amount <= 0 {
		return nil, fmt.Errorf("mint amount must be a positive integer")
	}

	allowanceByPartition, err := token.AllowanceByPartition(ctx, from, spender, partition)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	allowance := allowanceByPartition.Amount
	if allowance < amount {
		return nil, fmt.Errorf("Allowance is less than value")
	}

	// Decrease the allowance
	updatedAllowance := allowance - amount
	err = _approveByPartition(ctx, from, spender, partition, updatedAllowance)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	err = _transferByPartition(ctx, from, to, partition, amount)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	transferEvent := ccutils.Event{ctx.GetStub().GetTxID(), "Transfer", from, to, partition, amount}
	err = transferEvent.EmitTransferEvent(ctx)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

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
		return err
	}

	return nil
}

func (s *SmartContract) MintByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	err := ccutils.GetMSPID(ctx)
	if err != nil {
		return nil, err
	}

	id, err := ccutils.GetID(ctx)
	if err != nil {
		return nil, err
	}

	requireParameterFields := []string{token.FieldPartition, token.FieldAmount}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	int64ParameterFields := []string{token.FieldAmount}
	err = ccutils.CheckRequireTypeInt64(int64ParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	// args Data
	minter := ccutils.GetAddress([]byte(id))
	partition := args[token.FieldPartition].(string)
	amount := int64(args[token.FieldAmount].(float64))

	if amount <= 0 {
		return nil, fmt.Errorf("mint amount must be a positive integer")
	}

	mintByPartition := token.MintByPartitionStruct{Minter: minter, Partition: partition, Amount: amount}

	err = wallet.MintByPartition(ctx, mintByPartition)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)

	}

	transferEvent := ccutils.Event{ctx.GetStub().GetTxID(), "Transfer", minter, "", partition, amount}
	err = transferEvent.EmitTransferEvent(ctx)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
}

func (s *SmartContract) BurnByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	err := ccutils.GetMSPID(ctx)
	if err != nil {
		return nil, err
	}

	id, err := ccutils.GetID(ctx)
	if err != nil {
		return nil, err
	}

	requireParameterFields := []string{token.FieldPartition, token.FieldAmount}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	int64ParameterFields := []string{token.FieldAmount}
	err = ccutils.CheckRequireTypeInt64(int64ParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	// args Data
	minter := ccutils.GetAddress([]byte(id))
	partition := args[token.FieldPartition].(string)
	amount := int64(args[token.FieldAmount].(float64))

	if amount <= 0 {
		return nil, fmt.Errorf("mint amount must be a positive integer")
	}

	burnByPartition := token.MintByPartitionStruct{Minter: minter, Partition: partition, Amount: amount}

	err = wallet.BurnByPartition(ctx, burnByPartition)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	transferEvent := ccutils.Event{ctx.GetStub().GetTxID(), "Transfer", minter, "", partition, amount}
	err = transferEvent.EmitTransferEvent(ctx)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
}

func (s *SmartContract) GetTokenWalletList(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	requireParameterFields := []string{ledgermanager.PageSize, ledgermanager.Bookmark}
	err := ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{ledgermanager.Bookmark}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	int64ParameterFields := []string{ledgermanager.PageSize}
	err = ccutils.CheckTypeInt64(int64ParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	dateParameterFields := []string{ledgermanager.StartDate, ledgermanager.EndDate}
	err = ccutils.CheckFormatDate(dateParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	pageSize := int32(args[ledgermanager.PageSize].(float64))
	bookmark := args[ledgermanager.Bookmark].(string)

	var bytes []byte
	bytes, err = wallet.GetTokenWalletList(args, pageSize, bookmark, ctx)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	return ccutils.GenerateSuccessResponseByteArray(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], bytes)
}
