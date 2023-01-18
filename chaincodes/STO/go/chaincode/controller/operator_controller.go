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
		return nil, err
	}

	_, err = ccutils.GetID(ctx)
	if err != nil {
		return nil, err
	}

	requireParameterFields := []string{operator.FieldOperator, operator.FieldPartition}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{operator.FieldOperator, operator.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	operatorArg := args[operator.FieldOperator].(string)
	partitionArg := args[operator.FieldPartition].(string)

	checkBool, err := operator.IsOperatorByPartition(ctx, operatorArg, partitionArg)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], checkBool)
}

func (s *SmartContract) AuthorizeOperatorByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	err := ccutils.GetMSPID(ctx)
	if err != nil {
		return nil, err
	}

	_, err = ccutils.GetID(ctx)
	if err != nil {
		return nil, err
	}

	requireParameterFields := []string{operator.FieldOperator, operator.FieldPartition}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{operator.FieldOperator, operator.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	operatorArg := args[operator.FieldOperator].(string)
	partitionArg := args[operator.FieldPartition].(string)

	err = token.IsIssuable(ctx, partitionArg)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	err = operator.AuthorizeOperatorByPartition(ctx, operatorArg, partitionArg)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
}

func (s *SmartContract) RevokeOperatorByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	err := ccutils.GetMSPID(ctx)
	if err != nil {
		return nil, err
	}

	_, err = ccutils.GetID(ctx)
	if err != nil {
		return nil, err
	}

	requireParameterFields := []string{operator.FieldOperator, operator.FieldPartition}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{operator.FieldOperator, operator.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	operatorArg := args[operator.FieldOperator].(string)
	partitionArg := args[operator.FieldPartition].(string)

	err = token.IsIssuable(ctx, partitionArg)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	err = operator.RevokeOperatorByPartition(ctx, operatorArg, partitionArg)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
}

func (s *SmartContract) DistributeToken(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	err := ccutils.GetMSPID(ctx)
	if err != nil {
		return nil, err
	}

	requireParameterFields := []string{operator.FieldPartition, operator.FieldRecipients}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{operator.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	partition := args[operator.FieldPartition].(string)
	recipients := args[operator.FieldRecipients].(map[string]interface{})
	fmt.Println(recipients)

	// json example
	// {
	// 	"partition":"mediumToken",
	// 	"recipients":{
	// 	   "A":50,
	// 	   "B":30,
	// 	   "C":120
	// 	}
	//  }

	// Create allowanceKey
	listKey, err := ctx.GetStub().CreateCompositeKey(token.DocType_TokenHolderList, []string{partition})
	if err != nil {
		return nil, fmt.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_TokenHolderList, err)
	}

	listBytes, err := ledgermanager.GetState(token.DocType_TokenHolderList, listKey, ctx)
	if err != nil {
		return nil, err
	}

	listStruct := token.TokenHolderList{}
	err = json.Unmarshal(listBytes, &listStruct)
	if err != nil {
		return nil, err
	}

	if listStruct.IsLocked == true {
		return nil, fmt.Errorf("already exectued")
	} else {

		listStruct.PartitionToken = partition

		var wg sync.WaitGroup

		wg.Add(len(recipients))
		for key, value := range args {
			if key == operator.FieldRecipients {
				if rec, ok := value.(map[string]interface{}); ok {
					// wg.Add(1)

					for address, amount := range rec {

						listStruct.Recipients[address] = token.PartitionToken{Amount: int64(amount.(float64))}

						testData := distribute.AirDropStruct{}
						testData.Recipient = address

						testData.PartitionToken.Amount = int64(amount.(float64))
						testData.PartitionToken.TokenID = partition

						errChan := make(chan error)

						// go func() {
						// 	defer wg.Done()
						// 	// , &wg
						// 	distribute.AirDrop(ctx, testData, errChan)
						// }()

						go distribute.DistributeToken(ctx, testData, errChan, &wg)

						if err := <-errChan; err != nil {
							return ccutils.GenerateErrorResponse(err)
						}
					}
				}
			}
		}
		wg.Wait()
		// close(errChan)

		listStruct.IsLocked = true
		listToMap, err := ccutils.StructToMap(listStruct)
		if err != nil {
			return nil, err
		}

		err = ledgermanager.UpdateState(token.DocType_TokenHolderList, listKey, listToMap, ctx)
		if err != nil {
			return nil, err
		}

		return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
	}
}

func (s *SmartContract) AirDrop(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	err := ccutils.GetMSPID(ctx)
	if err != nil {
		return nil, err
	}

	requireParameterFields := []string{operator.FieldPartition, operator.FieldRecipients}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{operator.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		return ccutils.GenerateErrorResponse(err)
	}

	partition := args[operator.FieldPartition].(string)
	recipients := args[operator.FieldRecipients].(map[string]interface{})

	// Create allowanceKey
	listKey, err := ctx.GetStub().CreateCompositeKey(token.DocType_AirDrop, []string{partition})
	if err != nil {
		return nil, fmt.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_AirDrop, err)
	}

	listBytes, err := ledgermanager.GetState(token.DocType_AirDrop, listKey, ctx)
	if err != nil {
		return nil, err
	}

	listStruct := token.TokenHolderList{}
	err = json.Unmarshal(listBytes, &listStruct)
	if err != nil {
		return nil, err
	}

	// 투자 종료가 되었다는 파악을 할 수 있는 트리거가 있어야 하네

	if listStruct.IsLocked == true {
		return nil, fmt.Errorf("already exectued")
	} else {

		listStruct.PartitionToken = partition

		var wg sync.WaitGroup

		wg.Add(len(recipients))
		for key, value := range args {
			if key == operator.FieldRecipients {
				if rec, ok := value.(map[string]interface{}); ok {
					// wg.Add(1)

					for address, amount := range rec {

						listStruct.Recipients[address] = token.PartitionToken{Amount: int64(amount.(float64))}

						testData := distribute.AirDropStruct{}
						testData.Recipient = address

						testData.PartitionToken.Amount = int64(amount.(float64))
						testData.PartitionToken.TokenID = partition

						errChan := make(chan error)

						// go func() {
						// 	defer wg.Done()
						// 	// , &wg
						// 	distribute.AirDrop(ctx, testData, errChan)
						// }()

						go distribute.AirDrop(ctx, testData, errChan, &wg)

						if err := <-errChan; err != nil {
							return ccutils.GenerateErrorResponse(err)
						}
					}
				}
			}
		}
		wg.Wait()
		// close(errChan)

		listStruct.IsLocked = true
		listToMap, err := ccutils.StructToMap(listStruct)
		if err != nil {
			return nil, err
		}

		err = ledgermanager.UpdateState(token.DocType_AirDrop, listKey, listToMap, ctx)
		if err != nil {
			return nil, err
		}

		return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
	}
}
