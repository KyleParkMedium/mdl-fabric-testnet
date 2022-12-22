package token

import (
	"encoding/json"
	"fmt"

	"github.com/KyleParkMedium/mdl-chaincode/chaincode/ccutils"
	"github.com/KyleParkMedium/mdl-chaincode/chaincode/ledgermanager"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func TotalSupply(ctx contractapi.TransactionContextInterface) (*TotalSupplyStruct, error) {

	totalSupplyBytes, err := ledgermanager.GetState(DocType_TotalSupply, "TotalSupply", ctx)
	if err != nil {
		return nil, err
	}

	totalSupply := TotalSupplyStruct{}
	if err := json.Unmarshal(totalSupplyBytes, &totalSupply); err != nil {
		return nil, err
	}

	return &totalSupply, nil
}

func TotalSupplyByPartition(ctx contractapi.TransactionContextInterface, partition string) (*TotalSupplyByPartitionStruct, error) {

	totalSupplyBytes, err := ledgermanager.GetState(DocType_TotalSupplyByPartition, partition, ctx)
	if err != nil {
		return nil, err
	}

	totalSupplyByPartition := TotalSupplyByPartitionStruct{}
	if err := json.Unmarshal(totalSupplyBytes, &totalSupplyByPartition); err != nil {
		return nil, err
	}

	return &totalSupplyByPartition, nil
}

func BalanceOfByPartition(ctx contractapi.TransactionContextInterface, _tokenHolder string, _partition string) (int64, error) {

	// Create allowanceKey
	walletKey, err := ctx.GetStub().CreateCompositeKey(BalanceOfByPartitionPrefix, []string{_tokenHolder, _partition})
	if err != nil {
		return 0, fmt.Errorf("failed to create the composite key for prefix %s: %v", BalanceOfByPartitionPrefix, err)
	}

	partitionTokenBytes, err := ledgermanager.GetState(DocType_Token, walletKey, ctx)
	if err != nil {
		return 0, err
	}

	partitionToken := PartitionToken{}
	if err := json.Unmarshal(partitionTokenBytes, &partitionToken); err != nil {
		return 0, err
	}

	return partitionToken.Amount, nil
}

func AllowanceByPartition(ctx contractapi.TransactionContextInterface, owner string, spender string, partition string) (*AllowanceByPartitionStruct, error) {

	// Create allowanceKey
	allowancePartitionKey, err := ctx.GetStub().CreateCompositeKey(allowanceByPartitionPrefix, []string{owner, spender, partition})
	if err != nil {
		return nil, fmt.Errorf("failed to create the composite key for prefix %s: %v", allowanceByPartitionPrefix, err)
	}

	allowanceBytes, err := ledgermanager.GetState(DocType_Allowance, allowancePartitionKey, ctx)
	if err != nil {
		return nil, err
	}

	allowanceByPartition := AllowanceByPartitionStruct{}
	if err := json.Unmarshal(allowanceBytes, &allowanceByPartition); err != nil {
		return nil, err
	}

	return &allowanceByPartition, nil
}

func ApproveByPartition(ctx contractapi.TransactionContextInterface, allowanceByPartition AllowanceByPartitionStruct) error {

	allowanceByPartitionToMap, err := ccutils.StructToMap(allowanceByPartition)

	// Create allowanceKey
	allowancePartitionKey, err := ctx.GetStub().CreateCompositeKey(allowanceByPartitionPrefix, []string{allowanceByPartition.Owner, allowanceByPartition.Spender, allowanceByPartition.Partition})
	if err != nil {
		return fmt.Errorf("failed to create the composite key for prefix %s: %v", allowanceByPartitionPrefix, err)
	}

	exist, err := ledgermanager.CheckExistState(allowancePartitionKey, ctx)
	if err != nil {
		return err
	}

	if exist {
		err = ledgermanager.UpdateState(DocType_Allowance, allowancePartitionKey, allowanceByPartitionToMap, ctx)
		if err != nil {
			return err
		}
	} else {
		_, err = ledgermanager.PutState(DocType_Allowance, allowancePartitionKey, allowanceByPartition, ctx)
		if err != nil {
			return err
		}
	}

	return nil
}

func IssuanceAsset(ctx contractapi.TransactionContextInterface, token PartitionToken) (*PartitionToken, error) {

	// issuanceAsset
	_, err := ledgermanager.PutState(DocType_Token, token.TokenID, token, ctx)
	if err != nil {
		return nil, err
	}

	// totalSupplyByPartition
	_, err = ledgermanager.PutState(DocType_TotalSupplyByPartition, token.TokenID, TotalSupplyByPartitionStruct{TotalSupply: 0, Partition: token.TokenID}, ctx)
	if err != nil {
		return nil, err
	}

	return &token, nil
}
