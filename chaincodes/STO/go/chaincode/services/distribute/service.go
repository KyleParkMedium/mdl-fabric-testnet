package distribute

import (
	"encoding/json"
	"fmt"
	"sync"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"

	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ledgermanager"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/token"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/wallet"
)

func DistributeToken(ctx contractapi.TransactionContextInterface, airDrop AirDropStruct, errChan chan error, wg *sync.WaitGroup) {

	walletBytes, err := ledgermanager.GetState(wallet.DocType_TokenWallet, airDrop.Recipient, ctx)
	if err != nil {
		errChan <- err
		return
	}

	walletData := wallet.TokenWallet{}
	err = json.Unmarshal(walletBytes, &walletData)
	if err != nil {
		errChan <- err
		return
	}

	// 기획팀 이야기로는 일괄 배급이라고 우선 정의가 되었기 때문에 파티션에 대한 데이터가 이미 존재하는지에 대한 판단은 고려하지 않음.
	tokenMap := make(map[string][]token.PartitionToken)
	tokenMap[airDrop.PartitionToken.TokenID] = append(tokenMap[airDrop.PartitionToken.TokenID], airDrop.PartitionToken)

	walletData.PartitionTokens[airDrop.PartitionToken.TokenID] = tokenMap[airDrop.PartitionToken.TokenID]
	walletData.PartitionTokens[airDrop.PartitionToken.TokenID][0] = token.PartitionToken{Amount: airDrop.PartitionToken.Amount}

	walletToMap, err := ccutils.StructToMap(walletData)
	if err != nil {
		errChan <- err
		return
	}

	err = ledgermanager.UpdateState(wallet.DocType_TokenWallet, airDrop.Recipient, walletToMap, ctx)
	if err != nil {
		errChan <- err
		return
	}

	// balanceOf
	balanceKey, err := ctx.GetStub().CreateCompositeKey(token.BalanceOfByPartitionPrefix, []string{airDrop.Recipient, airDrop.PartitionToken.TokenID})
	if err != nil {
		errChan <- err
		return
	}

	partitionToken := token.PartitionToken{}
	partitionToken.DocType = token.DocType_Token
	partitionToken.Amount = airDrop.PartitionToken.Amount

	// _, err = ledgermanager.PutState(token.BalanceOfByPartitionPrefix, balanceKey, partitionToken, ctx)
	// if err != nil {
	// 	errChan <- err
	// 	return
	// }

	partitionTokenBytes, err := json.Marshal(partitionToken)
	if err != nil {
		errChan <- err
		return
	}
	err = ctx.GetStub().PutState(balanceKey, partitionTokenBytes)
	if err != nil {
		errChan <- err
		return
	}

	// Update the totalSupply, totalSupplyByPartition
	// 이부분에서 동시성 걸림. 로직 고민을 해봐야함.
	totalSupplyBytes, err := ledgermanager.GetState(token.DocType_TotalSupply, "TotalSupply", ctx)
	if err != nil {
		errChan <- err
		return
	}

	totalSupply := token.TotalSupplyStruct{}
	if err := json.Unmarshal(totalSupplyBytes, &totalSupply); err != nil {
		errChan <- err
		return
	}

	totalSupply.TotalSupply += airDrop.PartitionToken.Amount

	totalSupplyMap, err := ccutils.StructToMap(totalSupply)
	if err != nil {
		errChan <- err
		return
	}

	err = ledgermanager.UpdateState(token.DocType_TotalSupply, "TotalSupply", totalSupplyMap, ctx)
	if err != nil {
		errChan <- err
		return
	}

	// totalSupplyByPartition
	totalKey, err := ctx.GetStub().CreateCompositeKey(token.DocType_TotalSupplyByPartition, []string{airDrop.PartitionToken.TokenID})
	if err != nil {
		errChan <- err
	}

	totalSupplyByPartitionBytes, err := ledgermanager.GetState(token.DocType_TotalSupplyByPartition, totalKey, ctx)
	if err != nil {
		errChan <- err
		return
	}

	totalSupplyByPartition := token.TotalSupplyByPartitionStruct{}
	if err := json.Unmarshal(totalSupplyByPartitionBytes, &totalSupplyByPartition); err != nil {
		errChan <- err
		return
	}

	totalSupplyByPartition.TotalSupply += airDrop.PartitionToken.Amount

	totalSupplyByPartitionMap, err := ccutils.StructToMap(totalSupplyByPartition)
	if err != nil {
		errChan <- err
		return
	}

	err = ledgermanager.UpdateState(token.DocType_TotalSupplyByPartition, totalKey, totalSupplyByPartitionMap, ctx)
	if err != nil {
		errChan <- err
		return
	}

	// all good - send nil to the error channel
	errChan <- nil

	// defer wg.Done()
	wg.Done()
}

func AirDrop(ctx contractapi.TransactionContextInterface, airDrop AirDropStruct, errChan chan error, wg *sync.WaitGroup) {

	walletBytes, err := ledgermanager.GetState(wallet.DocType_TokenWallet, airDrop.Recipient, ctx)
	if err != nil {
		errChan <- err
		return
	}

	walletData := wallet.TokenWallet{}
	err = json.Unmarshal(walletBytes, &walletData)
	if err != nil {
		errChan <- err
		return
	}

	walletData.PartitionTokens[airDrop.PartitionToken.TokenID][0].Amount += airDrop.PartitionToken.Amount

	walletToMap, err := ccutils.StructToMap(walletData)
	if err != nil {
		errChan <- err
		return
	}

	err = ledgermanager.UpdateState(wallet.DocType_TokenWallet, airDrop.Recipient, walletToMap, ctx)
	if err != nil {
		errChan <- err
		return
	}

	// balanceOf
	balanceKey, err := ctx.GetStub().CreateCompositeKey(token.BalanceOfByPartitionPrefix, []string{airDrop.Recipient, airDrop.PartitionToken.TokenID})
	if err != nil {
		errChan <- err
		return
	}

	partitionToken := token.PartitionToken{}
	partitionToken.DocType = token.DocType_Token
	partitionToken.Amount = airDrop.PartitionToken.Amount

	// _, err = ledgermanager.PutState(token.BalanceOfByPartitionPrefix, balanceKey, partitionToken, ctx)
	// if err != nil {
	// 	errChan <- err
	// 	return
	// }

	partitionTokenBytes, err := json.Marshal(partitionToken)
	if err != nil {
		errChan <- err
		return
	}
	err = ctx.GetStub().PutState(balanceKey, partitionTokenBytes)
	if err != nil {
		errChan <- err
		return
	}

	// Update the totalSupply, totalSupplyByPartition
	// 이부분에서 동시성 걸림. 로직 고민을 해봐야함.
	totalSupplyBytes, err := ledgermanager.GetState(token.DocType_TotalSupply, "TotalSupply", ctx)
	if err != nil {
		errChan <- err
		return
	}

	totalSupply := token.TotalSupplyStruct{}
	if err := json.Unmarshal(totalSupplyBytes, &totalSupply); err != nil {
		errChan <- err
		return
	}

	totalSupply.TotalSupply += airDrop.PartitionToken.Amount

	totalSupplyMap, err := ccutils.StructToMap(totalSupply)
	if err != nil {
		errChan <- err
		return
	}

	err = ledgermanager.UpdateState(token.DocType_TotalSupply, "TotalSupply", totalSupplyMap, ctx)
	if err != nil {
		errChan <- err
		return
	}

	// totalSupplyByPartition
	totalKey, err := ctx.GetStub().CreateCompositeKey(token.DocType_TotalSupplyByPartition, []string{airDrop.PartitionToken.TokenID})
	if err != nil {
		errChan <- err
	}

	totalSupplyByPartitionBytes, err := ledgermanager.GetState(token.DocType_TotalSupplyByPartition, totalKey, ctx)
	if err != nil {
		errChan <- err
		return
	}

	totalSupplyByPartition := token.TotalSupplyByPartitionStruct{}
	if err := json.Unmarshal(totalSupplyByPartitionBytes, &totalSupplyByPartition); err != nil {
		errChan <- err
		return
	}

	totalSupplyByPartition.TotalSupply += airDrop.PartitionToken.Amount

	totalSupplyByPartitionMap, err := ccutils.StructToMap(totalSupplyByPartition)
	if err != nil {
		errChan <- err
		return
	}

	err = ledgermanager.UpdateState(token.DocType_TotalSupplyByPartition, totalKey, totalSupplyByPartitionMap, ctx)
	if err != nil {
		errChan <- err
		return
	}

	// all good - send nil to the error channel
	errChan <- nil

	// defer wg.Done()
	wg.Done()
}

func GetHolderList(ctx contractapi.TransactionContextInterface, partition string) (*token.TokenHolderList, error) {

	// Create allowanceKey
	listKey, err := ctx.GetStub().CreateCompositeKey(token.DocType_TokenHolderList, []string{partition})
	if err != nil {
		return nil, fmt.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_TokenHolderList, err)
	}

	listBytes, err := ledgermanager.GetState(token.DocType_TokenHolderList, listKey, ctx)
	if err != nil {
		return nil, err
	}

	listStruct := token.TokenHolderList{}
	if err := json.Unmarshal(listBytes, &listStruct); err != nil {
		return nil, err
	}

	return &listStruct, nil

}
