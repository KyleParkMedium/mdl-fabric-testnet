package airdrop

import (
	"encoding/json"
	"sync"

	"github.com/KyleParkMedium/mdl-chaincode/chaincode/ccutils"
	"github.com/KyleParkMedium/mdl-chaincode/chaincode/ledgermanager"
	"github.com/KyleParkMedium/mdl-chaincode/chaincode/services/token"
	"github.com/KyleParkMedium/mdl-chaincode/chaincode/services/wallet"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func AirDrop(ctx contractapi.TransactionContextInterface, airDrop AirDropStruct, errChan chan error, wg *sync.WaitGroup) {

	// 지갑 생성 또한 이제 동시에 해버릴 것인지..?
	// 흠 한번 생각을 해보기로 하오.
	// 지갑은 이 에어드롭 이전에 미리 만들어놓는게 서비스 결합도를 낮추는 방법인듯

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

	totalSupplyByPartitionBytes, err := ledgermanager.GetState(token.DocType_TotalSupplyByPartition, airDrop.PartitionToken.TokenID, ctx)
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

	err = ledgermanager.UpdateState(token.DocType_TotalSupplyByPartition, airDrop.PartitionToken.TokenID, totalSupplyByPartitionMap, ctx)
	if err != nil {
		errChan <- err
		return
	}

	// all good - send nil to the error channel
	errChan <- nil

	wg.Done()
}
