package operator

import (
	"encoding/json"
	"fmt"
	"reflect"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"

	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils/flogging"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ledgermanager"
)

var logger = flogging.MustGetLogger("operator service")

func IsOperatorByPartition(ctx contractapi.TransactionContextInterface, operator string, partition string) (bool, error) {

	operatorBytes, err := ledgermanager.GetState(DocType_Operator, "Operator", ctx)
	if err != nil {
		return false, err
	}

	operatorStruct := OperatorsStruct{}
	err = json.Unmarshal(operatorBytes, &operatorStruct)
	if err != nil {
		return false, err
	}

	if reflect.ValueOf(operatorStruct.Operator[partition]).IsZero() {
		return false, fmt.Errorf("partition's operator data is not exist")
	}

	if operatorStruct.Operator[partition][operator].Role != "Operator" {
		return false, nil
	}

	return true, nil
}

func AuthorizeOperatorByPartition(ctx contractapi.TransactionContextInterface, operator string, partition string) error {

	operatorBytes, err := ledgermanager.GetState(DocType_Operator, "Operator", ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	operatorStruct := OperatorsStruct{}
	err = json.Unmarshal(operatorBytes, &operatorStruct)
	if err != nil {
		logger.Error(err)
		return err
	}

	// 여기도 다시 수정해야함.덮어쓰기임 지금
	test := OperatorStruct{}
	test.Role = "Operator"
	operatorStruct.Operator[partition][operator] = test

	operatorToMap, err := ccutils.StructToMap(operatorStruct)
	if err != nil {
		logger.Error(err)
		return err
	}

	err = ledgermanager.UpdateState(DocType_Operator, "Operator", operatorToMap, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	return nil
}

func RevokeOperatorByPartition(ctx contractapi.TransactionContextInterface, operator string, partition string) error {

	operatorBytes, err := ledgermanager.GetState(DocType_Operator, "Operator", ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	operatorStruct := OperatorsStruct{}
	err = json.Unmarshal(operatorBytes, &operatorStruct)
	if err != nil {
		logger.Error(err)
		return err
	}

	// 여기도 다시 수정해야함.덮어쓰기임 지금
	test := OperatorStruct{}
	test.Role = ""
	operatorStruct.Operator[partition][operator] = test

	operatorToMap, err := ccutils.StructToMap(operatorStruct)
	if err != nil {
		logger.Error(err)
		return err
	}

	err = ledgermanager.UpdateState(DocType_Operator, "Operator", operatorToMap, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	return nil
}
