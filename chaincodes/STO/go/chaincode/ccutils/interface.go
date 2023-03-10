package ccutils

import (
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type Utils interface {
	GetID(ctx contractapi.TransactionContextInterface) (string, error)
	GetMSPID(ctx contractapi.TransactionContextInterface) error
}

type Q struct {
	Name string
}

func (q *Q) GetID(ctx contractapi.TransactionContextInterface) (string, error) {
	return "", nil
}
func (q *Q) GetMSPID(ctx contractapi.TransactionContextInterface) error {
	return nil
}

func Test() {

	test := &Q{Name: "kyle"}

	var a Utils
	a = test

	err := a.GetMSPID(&contractapi.TransactionContext{})
	if err != nil {
		fmt.Println(err)
	}

	fmt.Println(a)
}
