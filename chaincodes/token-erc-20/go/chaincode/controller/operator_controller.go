package controller

import (
	"sync"

	"github.com/KyleParkMedium/mdl-chaincode/chaincode/ccutils"
	"github.com/KyleParkMedium/mdl-chaincode/chaincode/services/airdrop"
	"github.com/KyleParkMedium/mdl-chaincode/chaincode/services/operator"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func (s *SmartContract) IsOperator(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (bool, error) {

	operatorArg := args[operator.FieldOperator].(string)

	checkBool, err := operator.IsOperator(ctx, operatorArg)
	if err != nil {
		return false, err
	}

	return checkBool, nil
}

func (s *SmartContract) AirDrop(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	var wg sync.WaitGroup

	partition := args[operator.FieldPartition].(string)
	recipients := args[operator.FieldRecipients].(map[string]interface{})

	wg.Add(len(recipients))
	for key, value := range args {
		if key == operator.FieldRecipients {
			if rec, ok := value.(map[string]interface{}); ok {
				for _, address := range rec {
					testData := airdrop.AirDropStruct{}
					testData.Recipient = address.(string)
					// 토큰 양을 전달 받는 순간을 정해야 해서 임시로 500 투입
					testData.PartitionToken.Amount = 500
					testData.PartitionToken.TokenID = partition

					errChan := make(chan error)

					go airdrop.AirDrop(ctx, testData, errChan, &wg)

					if err := <-errChan; err != nil {
						return ccutils.GenerateErrorResponse(err)
					}
				}
			}
		}
	}
	wg.Wait()

	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
}
