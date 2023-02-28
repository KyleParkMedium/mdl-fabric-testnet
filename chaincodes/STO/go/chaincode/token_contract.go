package chaincode

import (
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"

	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils/flogging"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/controller"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ledgermanager"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/operator"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/token"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/wallet"
)

var logger = flogging.MustGetLogger("chaincode")

// Changelog
const (
	Author           = "Kyle"
	DateCreated      = "2023/02/10"
	ChaincodeName    = "STO TOKEN Standard"
	ChaincodeVersion = "0.0.3"
)

// SmartContract provides functions for transferring tokens between accounts
type SmartContract struct {
	controller.SmartContract
}

// event provides an organized struct for emitting events
type Event struct {
	From  string
	To    string
	Value int
}

func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {

	logger.Info("Initialize Ledger")

	// Check minter authorization - this sample assumes Org1 is the central banker with privilege to mint new tokens
	err := _getMSPID(ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	_, err = _msgSender(ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	// Init TotalSupply Ledger
	logger.Info("Initialize TotalSupply Ledger, db key : TotalSupply")
	_, err = ledgermanager.PutState(token.DocType_TotalSupply, "TotalSupply", token.TotalSupplyStruct{DocType: token.DocType_TotalSupply, TotalSupply: 0}, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	// Init Admin Wallet Ledger
	walletStruct := wallet.AdminWallet{}
	walletStruct.DocType = wallet.DocType_AdminWallet
	walletStruct.AdminName = "medium"
	partitionTokenMap := make(map[string]map[string]token.PartitionToken)
	walletStruct.PartitionTokens = partitionTokenMap

	logger.Infof("Initialize Admin Wallet Ledger : %v, db key : AdminWallet", walletStruct.AdminName)
	_, err = ledgermanager.PutState(wallet.DocType_AdminWallet, "AdminWallet", walletStruct, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	// Init Operator Ledger
	operatorsStruct := operator.OperatorsStruct{}
	operatorsStruct.DocType = operator.DocType_Operator
	operatorMap := make(map[string]map[string]operator.OperatorStruct)
	operatorsStruct.Operator = operatorMap

	logger.Info("Initialize Operators Ledger, db key : Opearator")
	_, err = ledgermanager.PutState(operator.DocType_Operator, "Operator", operatorsStruct, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	return nil
}

/** 체인코드 init 위해 임시로 코드 작성
 */
func (s *SmartContract) IsInit(ctx contractapi.TransactionContextInterface) error {

	logger.Info("Initial Isinit run")

	// Check minter authorization - this sample assumes Org1 is the central banker with privilege to mint new tokens
	err := _getMSPID(ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	// Initial Isinit run
	err = ctx.GetStub().PutState("Isinit", []byte("Isinit"))
	if err != nil {
		logger.Error(err)
		return err
	}

	// Init totalSupply
	logger.Info("Init TotalSupply Ledger")
	_, err = ledgermanager.PutState(token.DocType_TotalSupply, "TotalSupply", token.TotalSupplyStruct{DocType: token.DocType_TotalSupply, TotalSupply: 0}, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	// Init Admin Wallet
	walletStruct := wallet.AdminWallet{}
	walletStruct.DocType = wallet.DocType_AdminWallet
	walletStruct.AdminName = "medium"
	partitionTokenMap := make(map[string]map[string]token.PartitionToken)
	walletStruct.PartitionTokens = partitionTokenMap

	logger.Infof("Init Admin Wallet Ledger : %v", walletStruct.AdminName)
	_, err = ledgermanager.PutState(wallet.DocType_AdminWallet, "AdminWallet", walletStruct, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	// Init Operator
	operatorsStruct := operator.OperatorsStruct{}
	operatorsStruct.DocType = operator.DocType_Operator
	operatorMap := make(map[string]map[string]operator.OperatorStruct)
	operatorsStruct.Operator = operatorMap

	logger.Info("Init Operator Ledger")
	_, err = ledgermanager.PutState(operator.DocType_Operator, "Operator", operatorsStruct, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	return nil
}

/** org1, org2, 피어(관리자, 클라이언트) 노드 주소 생성
 */
func (s *SmartContract) Init(ctx contractapi.TransactionContextInterface) (string, error) {

	// Check minter authorization - this sample assumes Org1 is the central banker with privilege to mint new tokens
	err := _getMSPID(ctx)
	if err != nil {
		logger.Error(err)
		return "", err
	}

	id, err := _msgSender(ctx)
	if err != nil {
		logger.Error(err)
		return "", err
	}

	// owner Address
	owner := ccutils.GetAddress([]byte(id))

	return owner, nil
}

// msgSender 등 이더리움 함수 이름 대로 두고 싶었는데, Go에서 소문자가 public 호출이 안되니까 그냥 아쉬워서 냅둠 ㅠ ㅋ
// 호출자 Address(shim / ctx.GetClientIdentity().GetID() 모듈화)
func _msgSender(ctx contractapi.TransactionContextInterface) (string, error) {

	// Get ID of submitting client identity
	id, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return "", fmt.Errorf("failed to get client id: %v", err)
	}

	return id, nil
}

/** shim / ctx.GetClientIdentity().GeMSPID() 모듈화
 */
func _getMSPID(ctx contractapi.TransactionContextInterface) error {

	// Get ID of submitting client identity
	_, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get client id: %v", err)
	}

	return nil
}

// ClientAccountID returns the id of the requesting client's account
// In this implementation, the client account ID is the clientId itself
// Users can use this function to get their own account id, which they can then give to others as the payment address
func (s *SmartContract) ClientAccountID(ctx contractapi.TransactionContextInterface) (string, error) {

	// Check minter authorization - this sample assumes Org1 is the central banker with privilege to mint new tokens
	err := _getMSPID(ctx)
	if err != nil {
		logger.Error(err)
		return "", err
	}

	id, err := _msgSender(ctx)
	if err != nil {
		logger.Error(err)
		return "", err
	}

	// owner Address
	clientAccountID := ccutils.GetAddress([]byte(id))

	return clientAccountID, nil
}
