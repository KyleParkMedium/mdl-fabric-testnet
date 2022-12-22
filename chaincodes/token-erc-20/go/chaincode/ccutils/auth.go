package ccutils

import (
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// Get ID of submitting client identity
func GetID(ctx contractapi.TransactionContextInterface) (string, error) {

	id, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return "", fmt.Errorf("failed to get client id: %v", err)
	}

	return id, nil
}

// Get MSPID of submitting client identity
func GetMSPID(ctx contractapi.TransactionContextInterface) error {

	_, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get client id: %v", err)
	}

	return nil
}
