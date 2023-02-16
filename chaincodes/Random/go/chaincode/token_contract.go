package chaincode

import (
	"fmt"
	"log"
	"math/rand"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SmartContract struct {
	contractapi.Contract
}

/** 체인코드 init 위해 임시로 코드 작성
 */
func (s *SmartContract) IsInit(ctx contractapi.TransactionContextInterface) error {

	log.Printf("Initial Isinit run")

	// Initial Isinit run
	err := ctx.GetStub().PutState("Isinit", []byte("Isinit"))
	if err != nil {
		return err
	}

	return nil
}

func (s *SmartContract) Minter(ctx contractapi.TransactionContextInterface) error {

	num := rand.Intn(100)

	err := ctx.GetStub().PutState("test", []byte(string(num)))
	if err != nil {
		return fmt.Errorf("failed to put state: %v", err)
	}

	return nil
}
