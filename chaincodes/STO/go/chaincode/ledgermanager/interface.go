package ledgermanager

import "github.com/hyperledger/fabric-contract-api-go/contractapi"

type Ledgermanager interface {
	GetState(docType string, key string, ctx contractapi.TransactionContextInterface) ([]byte, error)
	PutState(docType string, key string, data interface{}, ctx contractapi.TransactionContextInterface) (string, error)
	UpdateState(docType string, key string, data map[string]interface{}, ctx contractapi.TransactionContextInterface) error
	// GetQueryResultWithPagination(queryString string, pageSize int32, bookmark string, ctx contractapi.TransactionContextInterface) ([]byte, error)
}
