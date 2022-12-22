package operator

import (
	"encoding/json"

	"github.com/KyleParkMedium/mdl-chaincode/chaincode/ledgermanager"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func IsOperator(ctx contractapi.TransactionContextInterface, operator string) (bool, error) {

	operatorBytes, err := ledgermanager.GetState(DocType_Operator, "Operator", ctx)
	if err != nil {
		return false, err
	}

	operatorStruct := OperatorsStruct{}
	err = json.Unmarshal(operatorBytes, &operator)
	if err != nil {
		return false, err
	}

	if operatorStruct.Operator[operator].Role != "Operator" {
		return false, nil
	}

	return true, nil
}
