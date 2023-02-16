package controller

import (
	"encoding/json"
	"fmt"
	"sync"

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

	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		return nil, err
	}

	// requireParameterFields := []string{operator.FieldPartition, operator.FieldRecipients}
	// err = ccutils.CheckRequireParameter(requireParameterFields, args)
	// if err != nil {
	// 	logger.Error(err)
	// 	return ccutils.GenerateErrorResponse(err)
	// }

	// stringParameterFields := []string{operator.FieldPartition}
	// err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	// if err != nil {
	// 	logger.Error(err)
	// 	return ccutils.GenerateErrorResponse(err)
	// }

	tokenId := args[operator.FieldTokenId].(string)
	recipients := args[operator.FieldRecipients].(map[string]interface{})

	// Read Holder List
	listKey, err := ctx.GetStub().CreateCompositeKey(token.DocType_TokenHolderList, []string{tokenId})
	if err != nil {
		logger.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_TokenHolderList, err)
		return nil, fmt.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_TokenHolderList, err)
	}

	listBytes, err := ledgermanager.GetState(token.DocType_TokenHolderList, listKey, ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	listStruct := token.TokenHolderList{}
	err = json.Unmarshal(listBytes, &listStruct)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	// read Partition Token
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

	var updateTotalSupplyAmount int64

	if listStruct.IsDistributed == true {
		logger.Error("token is already distributed")
		return nil, fmt.Errorf("distribution already exectued")
	} else {
		var wg sync.WaitGroup

		wg.Add(len(recipients))
		for key, value := range args {
			if key == operator.FieldRecipients {
				if rec, ok := value.(map[string]interface{}); ok {
					// wg.Add(1)

					for address, amount := range rec {

						listStruct.Recipient2[address] = token.Recipient{TokenWalletId: address, TokenId: tokenId, Amount: int64(amount.(float64))}

						// listStruct.Recipients[address] = token.PartitionToken{Amount: int64(amount.(float64))}

						testData := distribute.AirDropStruct{}
						testData.Recipient = address

						// testData.PartitionToken = tokenStruct
						// or
						testData.PartitionToken = listStruct.TokenInfo
						testData.PartitionToken.Amount = int64(amount.(float64))

						updateTotalSupplyAmount += testData.PartitionToken.Amount

						errChan := make(chan error)

						// go func() {
						// 	defer wg.Done()
						// 	// , &wg
						// 	distribute.AirDrop(ctx, testData, errChan)
						// }()

						go distribute.DistributeToken(ctx, testData, errChan, &wg)

						if err := <-errChan; err != nil {
							logger.Error(err)
							return ccutils.GenerateErrorResponse(err)
						}
					}
				}
			}
		}
		wg.Wait()
		// close(errChan)

		err = distribute.UpdateTotalSupply(ctx, tokenId, updateTotalSupplyAmount)

		listStruct.IsDistributed = true
		listToMap, err := ccutils.StructToMap(listStruct)
		if err != nil {
			logger.Error(err)
			return nil, err
		}

		err = ledgermanager.UpdateState(token.DocType_TokenHolderList, listKey, listToMap, ctx)
		if err != nil {
			logger.Error(err)
			return nil, err
		}

		logger.Infof("Success function : DistributeToken")
		return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
	}
}

func (s *SmartContract) AirDrop(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		return nil, err
	}

	requireParameterFields := []string{operator.FieldPartition}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{operator.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// args Data
	partition := args[operator.FieldPartition].(string)

	// Create allowanceKey
	listKey, err := ctx.GetStub().CreateCompositeKey(token.DocType_AirDrop, []string{partition})
	if err != nil {
		logger.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_AirDrop, err)
		return nil, fmt.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_AirDrop, err)
	}

	listBytes, err := ledgermanager.GetState(token.DocType_AirDrop, listKey, ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	listStruct := token.TokenHolderList{}
	err = json.Unmarshal(listBytes, &listStruct)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	// listLength := len(listStruct.Recipient2)

	var updateTotalSupplyAmount int64

	// 투자 종료가 되었다는 파악을 할 수 있는 트리거가 있어야 하네
	if listStruct.IsAirDroped == true {
		logger.Error("list is already airdroped")
		return nil, fmt.Errorf("already exectued")
	} else {

		listStruct.PartitionToken = partition

		var wg sync.WaitGroup

		// wg.Add(len(recipients))
		for _, value := range listStruct.Recipient2 {

			// // 이걸로 넣을 것임.
			// arg로 벨류 처리 하고,
			imsy := token.Recipient{}
			imsy.TokenWalletId = value.TokenWalletId
			imsy.TokenId = value.TokenId
			// imsy.Amount = arg와 짬뽕한 Amount

			//imsy
			errChan := make(chan error)

			// updateTotalSupplyAmount += testData.PartitionToken.Amount

			// 암튼 여기 고루틴
			go distribute.AirDrop(ctx, imsy, errChan, &wg)

			// 이게 좋은 구조인지를 모르겠음
			// value.Amount = 최종 Amount
		}

		err = distribute.UpdateTotalSupply(ctx, partition, updateTotalSupplyAmount)

		listStruct.IsAirDroped = true
		listToMap, err := ccutils.StructToMap(listStruct)
		if err != nil {
			logger.Error(err)
			return nil, err
		}

		err = ledgermanager.UpdateState(token.DocType_AirDrop, listKey, listToMap, ctx)
		if err != nil {
			logger.Error(err)
			return nil, err
		}

		logger.Infof("Success function : AirDrop")
		return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
	}
}

func (s *SmartContract) RedeemToken2(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		return nil, err
	}

	// requireParameterFields := []string{operator.FieldPartition}
	// err = ccutils.CheckRequireParameter(requireParameterFields, args)
	// if err != nil {
	// 	logger.Error(err)
	// 	return ccutils.GenerateErrorResponse(err)
	// }

	// stringParameterFields := []string{operator.FieldPartition}
	// err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	// if err != nil {
	// 	logger.Error(err)
	// 	return ccutils.GenerateErrorResponse(err)
	// }

	// args Data
	tokenId := args[operator.FieldTokenId].(string)
	// percent := int64(args[operator.FieldPercent].(float64))

	// Create allowanceKey
	listKey, err := ctx.GetStub().CreateCompositeKey(token.DocType_TokenHolderList, []string{tokenId})
	if err != nil {
		logger.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_TokenHolderList, err)
		return nil, fmt.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_TokenHolderList, err)
	}

	listBytes, err := ledgermanager.GetState(token.DocType_TokenHolderList, listKey, ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	listStruct := token.TokenHolderList{}
	err = json.Unmarshal(listBytes, &listStruct)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	if listStruct.IsDistributed == false {
		logger.Error("This is not the time for redemption")
		return nil, fmt.Errorf("This is not the time for redemption")
	}
	// listLength := len(listStruct.Recipient2)

	// 투자 종료가 되었다는 파악을 할 수 있는 트리거가 있어야 하네
	if listStruct.IsRedeemed == true {
		logger.Error("list is already redeemed")
		return nil, fmt.Errorf("already exectued")
	} else {

		var wg sync.WaitGroup

		wg.Add(len(listStruct.Recipient2))
		for _, value := range listStruct.Recipient2 {

			// // // 이걸로 넣을 것임.
			// // arg로 벨류 처리 하고,
			imsy := token.Recipient{}
			imsy.TokenWalletId = value.TokenWalletId
			imsy.TokenId = value.TokenId
			imsy.Amount = value.Amount

			// //imsy
			errChan := make(chan error)

			// // 암튼 여기 고루틴
			go distribute.RedeemToken2(ctx, imsy, errChan, &wg)

			// // 이게 좋은 구조인지를 모르겠음
			value.Amount = 0

			if err := <-errChan; err != nil {
				logger.Error(err)
				return ccutils.GenerateErrorResponse(err)
			}

		}

		err = distribute.SetAdminWallet(ctx, &listStruct)

		listStruct.IsRedeemed = true
		listToMap, err := ccutils.StructToMap(listStruct)
		if err != nil {
			logger.Error(err)
			return nil, err
		}

		err = ledgermanager.UpdateState(token.DocType_TokenHolderList, listKey, listToMap, ctx)
		if err != nil {
			logger.Error(err)
			return nil, err
		}

		logger.Infof("Success function : Redeem Token")
		return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
	}
}
