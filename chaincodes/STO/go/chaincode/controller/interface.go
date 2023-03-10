package controller

import (
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils"
)

type Controller interface {
	IsOperatorByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	AuthorizeOperatorByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	RevokeOperatorByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	DistributeToken(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	RedeemToken(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)

	GetTokenWalletList(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	GetAdminWallet(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	GetData(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	GetToken(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	GetTokenList(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	GetTokenHolderList(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	GetHolderList(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)

	TotalSupply(ctx contractapi.TransactionContextInterface) (*ccutils.Response, error)
	TotalSupplyByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	BalanceOfByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	AllowanceByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	ApproveByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	IncreaseAllowanceByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	DecreaseAllowanceByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	IssueToken(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	UndoIssueToken(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	IsIssuable(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)

	CreateWallet(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	TransferByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	TransferFromByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	MintByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
	BurnByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error)
}
