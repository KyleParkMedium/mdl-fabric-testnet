package controller

import (
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ledgermanager"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/token"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/wallet"
)

// Wallet
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

// Token
func (s *SmartContract) GetData(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

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

	requireParameterFields := []string{ledgermanager.PageSize, ledgermanager.Bookmark}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
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

	//args
	pageSize := int32(args[ledgermanager.PageSize].(float64))
	bookmark := args[ledgermanager.Bookmark].(string)

	var bytes []byte
	bytes, err = token.GetData(args, pageSize, bookmark, ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : GetData")
	return ccutils.GenerateSuccessResponseByteArray(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], bytes)
}

func (s *SmartContract) GetToken(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

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

	requireParameterFields := []string{token.FieldPartition, ledgermanager.PageSize, ledgermanager.Bookmark}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldPartition, ledgermanager.Bookmark}
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

	//args
	partition := args[token.FieldPartition].(string)
	pageSize := int32(args[ledgermanager.PageSize].(float64))
	bookmark := args[ledgermanager.Bookmark].(string)

	var bytes []byte
	bytes, err = token.GetToken(args, partition, pageSize, bookmark, ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : GetToken")
	return ccutils.GenerateSuccessResponseByteArray(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], bytes)
}

func (s *SmartContract) GetTokenList(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

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

	requireParameterFields := []string{ledgermanager.PageSize, ledgermanager.Bookmark}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
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
	bytes, err = token.GetTokenList(args, pageSize, bookmark, ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : GetTokenList")
	return ccutils.GenerateSuccessResponseByteArray(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], bytes)
}

func (s *SmartContract) GetTokenHolderList(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	requireParameterFields := []string{token.FieldPartition, ledgermanager.PageSize, ledgermanager.Bookmark}
	err := ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldPartition, ledgermanager.Bookmark}
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

	// args
	partition := args[token.FieldPartition].(string)
	pageSize := int32(args[ledgermanager.PageSize].(float64))
	bookmark := args[ledgermanager.Bookmark].(string)

	var bytes []byte
	bytes, err = token.GetTokenHolderList(args, partition, pageSize, bookmark, ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : GetTokenHolderList")
	return ccutils.GenerateSuccessResponseByteArray(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], bytes)
}
