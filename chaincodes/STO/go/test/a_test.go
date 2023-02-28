package test

import (
	"fmt"
	"testing"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/stretchr/testify/require"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode"
	"github.com/the-medium-tech/mdl-chaincodes/test/mocks"
)

//go:generate go run github.com/maxbrunsfeld/counterfeiter/v6 -generate

//counterfeiter:generate -o mocks/transaction.go -fake-name TransactionContext . transactionContext
type transactionContext interface {
	contractapi.TransactionContextInterface
}

//counterfeiter:generate  -o mocks/chaincodestub.go -fake-name ChaincodeStub . chaincodeStub
type chaincodeStub interface {
	shim.ChaincodeStubInterface
}

//counterfeiter:generate -o mocks/statequeryiterator.go -fake-name StateQueryIterator . stateQueryIterator
type stateQueryIterator interface {
	shim.StateQueryIteratorInterface
}

func TestKyle(t *testing.T) {

	assetTransfer := chaincode.SmartContract{}
	// _, err = assetTransfer.TransferAsset(transactionContext, "", "")
	// require.NoError(t, err)
}
func TestInitLedger(t *testing.T) {
	chaincodeStub := &mocks.ChaincodeStub{}
	transactionContext := &mocks.TransactionContext{}
	transactionContext.GetStubReturns(chaincodeStub)

	assetTransfer := chaincode.SmartContract{}
	err := assetTransfer.InitLedger(transactionContext)
	require.NoError(t, err)

	chaincodeStub.PutStateReturns(fmt.Errorf("failed inserting key"))
	err = assetTransfer.InitLedger(transactionContext)
	require.EqualError(t, err, "failed to put to world state. failed inserting key")

	// chaincodeStub.GetStateReturns(bytes, nil)
	// assetTransfer := chaincode.SmartContract{}
	// _, err = assetTransfer.TransferAsset(transactionContext, "", "")
	// require.NoError(t, err)

}
