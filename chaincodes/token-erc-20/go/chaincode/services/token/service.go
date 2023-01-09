package token

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"

	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ledgermanager"
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

	fmt.Println(_tokenHolder)
	fmt.Println(_partition)
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

func IssueToken(ctx contractapi.TransactionContextInterface, token PartitionToken) (*PartitionToken, error) {

	// IssueToken
	_, err := ledgermanager.PutState(DocType_Token, token.TokenID, token, ctx)
	if err != nil {
		return nil, err
	}

	// totalSupplyByPartition
	_, err = ledgermanager.PutState(DocType_TotalSupplyByPartition, token.TokenID, TotalSupplyByPartitionStruct{TotalSupply: 0, Partition: token.TokenID}, ctx)
	if err != nil {
		return nil, err
	}

	// Distribute List
	holderStruct := TokenHolderList{}
	holderStruct.IsLocked = false
	partitionTokenMap := make(map[string]PartitionToken)
	holderStruct.Recipients = partitionTokenMap

	// Create allowanceKey
	listKey, err := ctx.GetStub().CreateCompositeKey(DocType_TokenHolderList, []string{token.TokenID})
	if err != nil {
		return nil, fmt.Errorf("failed to create the composite key for prefix %s: %v", BalanceOfByPartitionPrefix, err)
	}

	_, err = ledgermanager.PutState(DocType_TokenHolderList, listKey, holderStruct, ctx)
	if err != nil {
		return nil, err
	}

	return &token, nil
}

// 만약 undo 기능이 추가된다면, 투자 모집 진행 중 undo 발생 시 이를 어떻게 처리할거냐에 대한 고려가 들어가야함. 일단 이렇게만 적어놓겠음.
func UndoIssueToken(ctx contractapi.TransactionContextInterface, token PartitionToken) (*PartitionToken, error) {

	tokenBytes, err := ledgermanager.GetState(DocType_Token, token.TokenID, ctx)
	if err != nil {
		return nil, err
	}

	tokenStruct := PartitionToken{}
	err = json.Unmarshal(tokenBytes, &tokenStruct)
	if err != nil {
		return nil, err
	}

	if token.Publisher != tokenStruct.Publisher {
		return nil, fmt.Errorf("token publisher differs from caller")
	}

	tokenStruct.IsLocked = true

	tokenToMap, err := ccutils.StructToMap(tokenStruct)
	if err != nil {
		return nil, err
	}

	err = ledgermanager.UpdateState(DocType_Token, token.TokenID, tokenToMap, ctx)
	if err != nil {
		return nil, err
	}

	return &tokenStruct, nil
}

// func RedeemToken(ctx contractapi.TransactionContextInterface, token RedeemTokenStruct) (*PartitionToken, error) {

// 	listBytes, err := ledgermanager.GetState(DocType_TokenHolderList, token.Partition, ctx)
// 	if err != nil {
// 		return nil, err
// 	}

// 	listStruct := TokenHolderList{}
// 	err = json.Unmarshal(listBytes, &listStruct)
// 	if err != nil {
// 		return nil, err
// 	}

// 	adminBytes, err := ledgermanager.GetState(wallet.DocType_AdminWallet, "", ctx)
// 	if err != nil {
// 		return nil, err
// 	}

// 	adminStruct := wallet.AdminWallet{}
// 	err = json.Unmarshal(adminBytes, &adminStruct)
// 	if err != nil {
// 		return nil, err
// 	}

// 	test := listStruct.Recipients[token.Holder]
// 	aaa := PartitionToken{}
// 	aaa.Amount = test.Amount
// 	adminStruct.PartitionTokens[token.Partition][token.Holder] = aaa
// 	// a to admin
// 	test.Amount = 0
// 	listStruct.Recipients[token.Holder] = test

// 	listToMap, err := ccutils.StructToMap(listStruct)
// 	if err != nil {
// 		return nil, err
// 	}

// 	err = ledgermanager.UpdateState(DocType_TokenHolderList, token.Partition, listToMap, ctx)
// 	if err != nil {
// 		return nil, err
// 	}

// 	adminToMap, err := ccutils.StructToMap(adminStruct)
// 	if err != nil {
// 		return nil, err
// 	}

// 	err = ledgermanager.UpdateState(wallet.DocType_AdminWallet, "", adminToMap, ctx)
// 	if err != nil {
// 		return nil, err
// 	}

// 	return &aaa, nil
// }

func IsIssuable(ctx contractapi.TransactionContextInterface, partition string) error {

	_, err := ledgermanager.GetState(DocType_Token, partition, ctx)
	if err != nil {
		return err
	}

	return nil
}
