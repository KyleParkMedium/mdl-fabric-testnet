package controller

import (
	"encoding/json"
	"fmt"
	"math/big"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"

	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ledgermanager"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/distribute"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/operator"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/token"
)

func (s *SmartContract) IsOperatorByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

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

	requireParameterFields := []string{operator.FieldOperator, operator.FieldPartition}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{operator.FieldOperator, operator.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// args
	operatorArg := args[operator.FieldOperator].(string)
	partitionArg := args[operator.FieldPartition].(string)

	checkBool, err := operator.IsOperatorByPartition(ctx, operatorArg, partitionArg)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : IsOperatorByPartition")
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], checkBool)
}

func (s *SmartContract) AuthorizeOperatorByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

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

	requireParameterFields := []string{operator.FieldOperator, operator.FieldPartition}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{operator.FieldOperator, operator.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// args
	operatorArg := args[operator.FieldOperator].(string)
	partitionArg := args[operator.FieldPartition].(string)

	err = token.IsIssuable(ctx, partitionArg)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	err = operator.AuthorizeOperatorByPartition(ctx, operatorArg, partitionArg)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : AuthorizeOperatorByPartition")
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
}

func (s *SmartContract) RevokeOperatorByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

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

	requireParameterFields := []string{operator.FieldOperator, operator.FieldPartition}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{operator.FieldOperator, operator.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// args
	operatorArg := args[operator.FieldOperator].(string)
	partitionArg := args[operator.FieldPartition].(string)

	err = token.IsIssuable(ctx, partitionArg)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	err = operator.RevokeOperatorByPartition(ctx, operatorArg, partitionArg)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : RevokeOperatorByPartition")
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
}

func (s *SmartContract) DistributeToken(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	// err := ccutils.GetMSPID(ctx)
	// if err != nil {
	// 	logger.Errorf("failed to get client msp id: %v", err)
	// 	return nil, err
	// }

	// _, err = ccutils.GetID(ctx)
	// if err != nil {
	// 	logger.Errorf("failed to get client id: %v", err)
	// 	return nil, err
	// }

	requireParameterFields := []string{operator.FieldTokenId, operator.FieldPublicOfferingAmount, operator.FieldRecipients}
	err := ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{operator.FieldTokenId}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	int64ParameterFields := []string{operator.FieldPublicOfferingAmount}
	err = ccutils.CheckRequireTypeInt64(int64ParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// args
	tokenId := args[operator.FieldTokenId].(string)
	publicOfferingAmount := int64(args[operator.FieldPublicOfferingAmount].(float64))
	recipients := args[operator.FieldRecipients].(map[string]interface{})

	// Get Holder List
	holderListKey, err := ctx.GetStub().CreateCompositeKey(token.DocType_TokenHolderList, []string{tokenId})
	if err != nil {
		logger.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_TokenHolderList, err)
		return nil, fmt.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_TokenHolderList, err)
	}

	holderListBytes, err := ledgermanager.GetState(token.DocType_TokenHolderList, holderListKey, ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	holderListStruct := token.TokenHolderList{}
	err = json.Unmarshal(holderListBytes, &holderListStruct)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	// Get Partition Token
	tokenBytes, err := ledgermanager.GetState(token.DocType_Token, tokenId, ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	tokenStruct := token.PartitionToken{}
	err = json.Unmarshal(tokenBytes, &tokenStruct)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	if tokenStruct.PublicOfferingAmount != publicOfferingAmount {
		logger.Error("publicOfferingAmount is not matched")
		return nil, fmt.Errorf("publicOfferingAmount is not matched")

	}

	var checkAmount int64
	var updateTotalSupplyAmount int64

	if holderListStruct.IsDistributed == true {
		logger.Error("token is already distributed")
		return nil, fmt.Errorf("distribution already exectued")
	} else {

		resultMap := make(map[string]int64, len(recipients))

		for address, amount := range recipients {

			holderListStruct.Recipients[address] = token.Recipient{TokenWalletId: address, TokenId: tokenId, Amount: int64(amount.(float64)) / 5000, AmountBig: big.NewInt(int64(amount.(float64)) / 5000)}

			testData := distribute.AirDropStruct{}
			testData.Recipient = address
			testData.PartitionToken = holderListStruct.TokenInfo
			testData.PartitionToken.TokenHolderID = address
			testData.PartitionToken.Amount = int64(amount.(float64)) / 5000
			testData.PartitionToken.AmountBig = big.NewInt(int64(amount.(float64)) / 5000)
			checkAmount += int64(amount.(float64))

			updateTotalSupplyAmount += testData.PartitionToken.Amount

			resultMap[address] = testData.PartitionToken.Amount

			err = distribute.DistributeToken(ctx, testData)
			if err != nil {
				logger.Error(err)
				return nil, err
			}
		}

		if checkAmount != publicOfferingAmount {
			return nil, fmt.Errorf("Recipients Total Supply does not matched PublicOfferingAmount")
		}

		err = distribute.UpdateTotalSupply(ctx, tokenId, updateTotalSupplyAmount)

		holderListStruct.IsDistributed = true
		listToMap, err := ccutils.StructToMap(holderListStruct)
		if err != nil {
			logger.Error(err)
			return nil, err
		}

		err = ledgermanager.UpdateState(token.DocType_TokenHolderList, holderListKey, listToMap, ctx)
		if err != nil {
			logger.Error(err)
			return nil, err
		}

		logger.Infof("Success function : DistributeToken")
		return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], resultMap)
	}
}

func (s *SmartContract) RedeemToken(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		return nil, err
	}

	requireParameterFields := []string{operator.FieldTokenId}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{operator.FieldTokenId}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// args
	tokenId := args[operator.FieldTokenId].(string)

	// get holder list ledger
	holderListKey, err := ctx.GetStub().CreateCompositeKey(token.DocType_TokenHolderList, []string{tokenId})
	if err != nil {
		logger.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_TokenHolderList, err)
		return nil, fmt.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_TokenHolderList, err)
	}

	holderListBytes, err := ledgermanager.GetState(token.DocType_TokenHolderList, holderListKey, ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	holderListStruct := token.TokenHolderList{}
	err = json.Unmarshal(holderListBytes, &holderListStruct)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	if holderListStruct.IsDistributed == false {
		logger.Error("This is not the time for redemption")
		return nil, fmt.Errorf("This is not the time for redemption")
	}
	if holderListStruct.IsRedeemed == true {
		logger.Error("list is already redeemed")
		return nil, fmt.Errorf("already exectued")
	} else {

		resultMap := make(map[string]int64, len(holderListStruct.Recipients))

		for _, value := range holderListStruct.Recipients {

			resultMap[value.TokenWalletId] = value.Amount

			testData := distribute.AirDropStruct{}
			testData.Recipient = value.TokenWalletId
			testData.PartitionToken = holderListStruct.TokenInfo
			testData.PartitionToken.TokenHolderID = value.TokenId
			testData.PartitionToken.Amount = value.Amount
			testData.PartitionToken.AmountBig = big.NewInt(value.Amount)

			err = distribute.RedeemToken(ctx, testData)
			if err != nil {
				logger.Error(err)
				return nil, err
			}

		}

		err = distribute.SetAdminWallet(ctx, holderListKey, &holderListStruct)

		logger.Infof("Success function : Redeem Token")
		return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], resultMap)
	}
}
