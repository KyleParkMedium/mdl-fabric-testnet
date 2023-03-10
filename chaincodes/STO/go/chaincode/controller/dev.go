package controller

import (
	"github.com/hyperledger/fabric-contract-api-go/contractapi"

	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ledgermanager"
)

type AA interface {
	contractapi.TransactionContextInterface
	ledgermanager.Ledgermanager
}

// func QQQ() {
// 	// q := &ledgermanager.Ex{Name: "kyle"}

// 	// var a AA
// 	// a = q

// 	// fmt.Println(a)
// }

// func (s *SmartContract) DevDistributeToken(ctx contractapi.TransactionContextInterface, lgEx ledgermanager.Ledgermanager, args map[string]interface{}) (*ccutils.Response, error) {

// 	// dev := &ledgermanager.Ex{Name: "kyle"}

// 	// err := ccutils.GetMSPID(ctx)
// 	// if err != nil {
// 	// 	logger.Errorf("failed to get client msp id: %v", err)
// 	// 	return nil, err
// 	// }

// 	// _, err = ccutils.GetID(ctx)
// 	// if err != nil {
// 	// 	logger.Errorf("failed to get client id: %v", err)
// 	// 	return nil, err
// 	// }

// 	requireParameterFields := []string{operator.FieldTokenId, operator.FieldPublicOfferingAmount, operator.FieldRecipients}
// 	err := ccutils.CheckRequireParameter(requireParameterFields, args)
// 	if err != nil {
// 		logger.Error(err)
// 		return ccutils.GenerateErrorResponse(err)
// 	}

// 	stringParameterFields := []string{operator.FieldTokenId}
// 	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
// 	if err != nil {
// 		logger.Error(err)
// 		return ccutils.GenerateErrorResponse(err)
// 	}

// 	int64ParameterFields := []string{operator.FieldPublicOfferingAmount}
// 	err = ccutils.CheckRequireTypeInt64(int64ParameterFields, args)
// 	if err != nil {
// 		logger.Error(err)
// 		return ccutils.GenerateErrorResponse(err)
// 	}

// 	// args
// 	tokenId := args[operator.FieldTokenId].(string)
// 	publicOfferingAmount := int64(args[operator.FieldPublicOfferingAmount].(float64))
// 	recipients := args[operator.FieldRecipients].(map[string]interface{})

// 	// Get Holder List
// 	holderListKey, err := ctx.GetStub().CreateCompositeKey(token.DocType_TokenHolderList, []string{tokenId})
// 	if err != nil {
// 		logger.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_TokenHolderList, err)
// 		return nil, fmt.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_TokenHolderList, err)
// 	}

// 	holderListBytes, err := lgEx.GetState(token.DocType_TokenHolderList, holderListKey, ctx)
// 	if err != nil {
// 		logger.Error(err)
// 		return nil, err
// 	}

// 	// holderListBytes, err := ledgermanager.GetState(token.DocType_TokenHolderList, holderListKey, ctx)
// 	// if err != nil {
// 	// 	logger.Error(err)
// 	// 	return nil, err
// 	// }

// 	holderListStruct := token.TokenHolderList{}
// 	err = json.Unmarshal(holderListBytes, &holderListStruct)
// 	if err != nil {
// 		logger.Error(err)
// 		return nil, err
// 	}

// 	// Get Partition Token
// 	tokenBytes, err := ledgermanager.GetState(token.DocType_Token, tokenId, ctx)
// 	if err != nil {
// 		logger.Error(err)
// 		return nil, err
// 	}

// 	tokenStruct := token.PartitionToken{}
// 	err = json.Unmarshal(tokenBytes, &tokenStruct)
// 	if err != nil {
// 		logger.Error(err)
// 		return nil, err
// 	}

// 	if tokenStruct.PublicOfferingAmount != publicOfferingAmount {
// 		logger.Error("publicOfferingAmount is not matched")
// 		return nil, fmt.Errorf("publicOfferingAmount is not matched")

// 	}

// 	var updateTotalSupplyAmount int64

// 	if holderListStruct.IsDistributed == true {
// 		logger.Error("token is already distributed")
// 		return nil, fmt.Errorf("distribution already exectued")
// 	} else {

// 		resultMap := make(map[string]int64, len(recipients))

// 		for address, amount := range recipients {

// 			holderListStruct.Recipients[address] = token.Recipient{TokenWalletId: address, TokenId: tokenId, Amount: int64(amount.(float64)) / 5000}

// 			testData := distribute.AirDropStruct{}
// 			testData.Recipient = address
// 			testData.PartitionToken = holderListStruct.TokenInfo
// 			testData.PartitionToken.TokenHolderID = address
// 			testData.PartitionToken.Amount = int64(amount.(float64)) / 5000

// 			updateTotalSupplyAmount += testData.PartitionToken.Amount

// 			resultMap[address] = testData.PartitionToken.Amount

// 			err = distribute.DistributeToken(ctx, testData)
// 			if err != nil {
// 				logger.Error(err)
// 				return nil, err
// 			}
// 		}

// 		err = distribute.UpdateTotalSupply(ctx, tokenId, updateTotalSupplyAmount)

// 		holderListStruct.IsDistributed = true
// 		listToMap, err := ccutils.StructToMap(holderListStruct)
// 		if err != nil {
// 			logger.Error(err)
// 			return nil, err
// 		}

// 		err = ledgermanager.UpdateState(token.DocType_TokenHolderList, holderListKey, listToMap, ctx)
// 		if err != nil {
// 			logger.Error(err)
// 			return nil, err
// 		}

// 		logger.Infof("Success function : DistributeToken")
// 		return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], resultMap)
// 	}
// }
