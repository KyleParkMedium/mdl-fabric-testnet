package test

import (
	"encoding/json"
	"fmt"
	"testing"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/stretchr/testify/require"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ledgermanager"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/token"
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

//counterfeiter:generate -o mocks/utils.go -fake-name Utils . utils
type utils interface {
	ccutils.Utils
}

//counterfeiter:generate -o mocks/ledgermanager.go -fake-name Ledger . ledger
type ledger interface {
	ledgermanager.Ledgermanager
}

func initialize() {
	chaincodeStub := &mocks.ChaincodeStub{}
	transactionContext := &mocks.TransactionContext{}
	transactionContext.GetStubReturns(chaincodeStub)
}

func TestDistributeToken(t *testing.T) {

	chaincodeStub := &mocks.ChaincodeStub{}
	transactionContext := &mocks.TransactionContext{}
	transactionContext.GetStubReturns(chaincodeStub)

	err := fmt.Errorf("Invalid Transaction But Accepted, Error : order of coin transactions")

	a := &mocks.Utils{}

	a.GetMSPIDReturns(err)

	b := CreateRecipient()
	fmt.Println(b)

	for i := 0; i < 10000; i++ {
		// err = distribute.DistributeToken(transactionContext, b)
		err = serviceDistributeToken(transactionContext)
		fmt.Println(err)
	}
}

func serviceDistributeToken(ctx *mocks.TransactionContext) error {

	ledger := &mocks.Ledger{}

	buf := []byte("kyle Wallet")
	ledger.GetStateReturns(buf, nil)

	ledger.UpdateStateReturns(nil)

	ledger.PutStateReturns("success", nil)

	return nil
}

func TestKyle(t *testing.T) {

	chaincodeStub := &mocks.ChaincodeStub{}
	transactionContext := &mocks.TransactionContext{}
	transactionContext.GetStubReturns(chaincodeStub)

	a := CreateMock()

	b, err := json.Marshal(a)

	var c map[string]interface{}

	err = json.Unmarshal(b, &c)
	if err != nil {
		fmt.Println(err)
	}

	// asset := &chaincode.Asset{ID: "asset1"}
	asset := &token.TokenHolderList{DocType: token.DocType_TokenHolderList}

	bytes, err := json.Marshal(asset)
	require.NoError(t, err)
	fmt.Println(bytes)

	// chaincodeStub.GetStateReturns(bytes, nil)

	// asset = &token.TokenHolderList{DocType: token.DocType_Token}

	// bytes, err = json.Marshal(asset)
	// require.NoError(t, err)
	// fmt.Println(bytes)

	// chaincodeStub.GetStateReturns(bytes, nil)

	ledger := &mocks.Ledger{}
	ledger.GetStateReturns(bytes, nil)

	assetTransfer := chaincode.SmartContract{}
	// _, err = assetTransfer.DistributeToken(transactionContext, c)
	_, err = assetTransfer.DevDistributeToken(transactionContext, ledger, c)
	require.NoError(t, err)

	// assetTransfer := chaincode.SmartContract{}
	// err := assetTransfer.DistributeToken(transactionContext)
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
