package controller

import (
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/distribute"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/token"
)

func (s *SmartContract) GetHolderList(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

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

	requireParameterFields := []string{token.FieldPartition}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	partition := args[token.FieldPartition].(string)

	asset, err := distribute.GetHolderList(ctx, partition)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	transferEvent := ccutils.TransferEvent{ctx.GetStub().GetTxID(), "tokenHolderList", "", "", partition, 0}
	err = transferEvent.EmitTransferEvent(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	retData, err := ccutils.StructToMap(asset)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : GetHolderList")
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], retData)
}
