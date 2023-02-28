package chaincode

import (
	"fmt"
	"log"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SmartContract struct {
	contractapi.Contract
}

func (s *SmartContract) IsInit(ctx contractapi.TransactionContextInterface) error {

	log.Printf("Initial Isinit run")

	// Initial Isinit run
	err := ctx.GetStub().PutState("key", []byte("key"))
	if err != nil {
		return err
	}

	return nil
}

func (s *SmartContract) Check(ctx contractapi.TransactionContextInterface) error {

	key, err := ctx.GetStub().GetState("key")
	if err != nil {
		return err
	}
	fmt.Println(key)

	// Initial Isinit run
	err = ctx.GetStub().PutState("key", []byte("key22"))
	if err != nil {
		return err
	}

	key2, err := ctx.GetStub().GetState("key")
	if err != nil {
		return err
	}
	fmt.Println(key2)

	return nil
}
