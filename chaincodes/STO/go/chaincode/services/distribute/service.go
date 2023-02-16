package distribute

import (
	"encoding/json"
	"fmt"
	"sync"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"

	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils/flogging"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ledgermanager"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/token"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/wallet"
)

var logger = flogging.MustGetLogger("distribute service")

func DistributeToken(ctx contractapi.TransactionContextInterface, airDrop AirDropStruct, errChan chan error, wg *sync.WaitGroup) {

	walletBytes, err := ledgermanager.GetState(wallet.DocType_TokenWallet, airDrop.Recipient, ctx)
	if err != nil {
		errChan <- err
	}

	walletData := wallet.TokenWallet{}
	err = json.Unmarshal(walletBytes, &walletData)
	if err != nil {
		errChan <- err
	}

	// 기획팀 이야기로는 일괄 배급이라고 우선 정의가 되었기 때문에 파티션에 대한 데이터가 이미 존재하는지에 대한 판단은 고려하지 않음.
	tokenMap := make(map[string][]token.PartitionToken)
	tokenMap[airDrop.PartitionToken.TokenID] = append(tokenMap[airDrop.PartitionToken.TokenID], airDrop.PartitionToken)

	// 이거 없애도 되는지 확인 둘중 하나만 쓸 수 있음
	walletData.PartitionTokens[airDrop.PartitionToken.TokenID] = tokenMap[airDrop.PartitionToken.TokenID]
	// walletData.PartitionTokens[airDrop.PartitionToken.TokenID][0] = airDrop.PartitionToken
	// walletData.PartitionTokens[airDrop.PartitionToken.TokenID][0] = token.PartitionToken{Amount: airDrop.PartitionToken.Amount}

	walletToMap, err := ccutils.StructToMap(walletData)
	if err != nil {
		errChan <- err
	}

	err = ledgermanager.UpdateState(wallet.DocType_TokenWallet, airDrop.Recipient, walletToMap, ctx)
	if err != nil {
		errChan <- err
	}
	logger.Infof("success distribute token %v to wallet %v", airDrop.PartitionToken, walletData.TokenWalletId)

	// balanceOf
	balanceKey, err := ctx.GetStub().CreateCompositeKey(token.BalanceOfByPartitionPrefix, []string{airDrop.Recipient, airDrop.PartitionToken.TokenID})
	if err != nil {
		errChan <- err
	}

	partitionToken := token.PartitionToken{}
	partitionToken = airDrop.PartitionToken
	partitionToken.DocType = token.DocType_Token

	// _, err = ledgermanager.PutState(token.BalanceOfByPartitionPrefix, balanceKey, partitionToken, ctx)
	// if err != nil {
	// 	errChan <- err
	// 	return
	// }

	partitionTokenBytes, err := json.Marshal(partitionToken)
	if err != nil {
		errChan <- err
	}
	err = ctx.GetStub().PutState(balanceKey, partitionTokenBytes)
	if err != nil {
		errChan <- err
	}

	// all good - send nil to the error channel
	errChan <- nil

	// defer wg.Done()
	wg.Done()
}

func AirDrop(ctx contractapi.TransactionContextInterface, airDrop token.Recipient, errChan chan error, wg *sync.WaitGroup) {

	walletBytes, err := ledgermanager.GetState(wallet.DocType_TokenWallet, airDrop.TokenWalletId, ctx)
	if err != nil {
		errChan <- err
	}

	walletData := wallet.TokenWallet{}
	err = json.Unmarshal(walletBytes, &walletData)
	if err != nil {
		errChan <- err
	}

	walletData.PartitionTokens[airDrop.TokenId][0].AddAmount(airDrop.Amount)

	walletToMap, err := ccutils.StructToMap(walletData)
	if err != nil {
		errChan <- err
	}

	err = ledgermanager.UpdateState(wallet.DocType_TokenWallet, airDrop.TokenWalletId, walletToMap, ctx)
	if err != nil {
		errChan <- err
	}

	// balanceOf
	balanceKey, err := ctx.GetStub().CreateCompositeKey(token.BalanceOfByPartitionPrefix, []string{airDrop.TokenWalletId, airDrop.TokenId})
	if err != nil {
		errChan <- err
	}

	balanceOfBytes, err := ledgermanager.GetState(token.DocType_Token, balanceKey, ctx)
	if err != nil {
		errChan <- err
	}

	balanceOfData := token.PartitionToken{}
	err = json.Unmarshal(balanceOfBytes, &balanceOfData)
	if err != nil {
		errChan <- err
	}

	balanceOfData.Amount = airDrop.Amount

	balanceOfToMap, err := ccutils.StructToMap(balanceOfData)
	if err != nil {
		errChan <- err
	}

	err = ledgermanager.UpdateState(token.DocType_Token, balanceKey, balanceOfToMap, ctx)
	if err != nil {
		errChan <- err
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
		logger.Error(err)
		return nil, err
	}

	listStruct := token.TokenHolderList{}
	if err := json.Unmarshal(listBytes, &listStruct); err != nil {
		return nil, err
	}

	return &listStruct, nil

}

func UpdateTotalSupply(ctx contractapi.TransactionContextInterface, partition string, update int64) error {

	totalSupplyBytes, err := ledgermanager.GetState(token.DocType_TotalSupply, "TotalSupply", ctx)
	if err != nil {
		return err
	}

	totalSupply := token.TotalSupplyStruct{}
	if err := json.Unmarshal(totalSupplyBytes, &totalSupply); err != nil {
		return err
	}

	totalSupply.AddAmount(update)

	totalSupplyMap, err := ccutils.StructToMap(totalSupply)
	if err != nil {
		return err
	}

	err = ledgermanager.UpdateState(token.DocType_TotalSupply, "TotalSupply", totalSupplyMap, ctx)
	if err != nil {
		return err
	}

	// totalSupplyByPartition
	totalKey, err := ctx.GetStub().CreateCompositeKey(token.DocType_TotalSupplyByPartition, []string{partition})
	if err != nil {
		return err
	}

	totalSupplyByPartitionBytes, err := ledgermanager.GetState(token.DocType_TotalSupplyByPartition, totalKey, ctx)
	if err != nil {
		return err
	}

	totalSupplyByPartition := token.TotalSupplyByPartitionStruct{}
	if err := json.Unmarshal(totalSupplyByPartitionBytes, &totalSupplyByPartition); err != nil {
		return err
	}

	totalSupplyByPartition.AddAmount(update)

	totalSupplyByPartitionMap, err := ccutils.StructToMap(totalSupplyByPartition)
	if err != nil {
		return err
	}

	err = ledgermanager.UpdateState(token.DocType_TotalSupplyByPartition, totalKey, totalSupplyByPartitionMap, ctx)
	if err != nil {
		return err
	}

	logger.Infof("succes update totalSupply : %v", partition)
	return nil
}

func RedeemToken2(ctx contractapi.TransactionContextInterface, airDrop token.Recipient, errChan chan error, wg *sync.WaitGroup) {

	walletBytes, err := ledgermanager.GetState(wallet.DocType_TokenWallet, airDrop.TokenWalletId, ctx)
	if err != nil {
		errChan <- err
	}

	walletData := wallet.TokenWallet{}
	err = json.Unmarshal(walletBytes, &walletData)
	if err != nil {
		errChan <- err
	}

	walletData.PartitionTokens[airDrop.TokenId][0].Amount = 0
	walletData.PartitionTokens[airDrop.TokenId][0].IsLocked = true

	walletToMap, err := ccutils.StructToMap(walletData)
	if err != nil {
		errChan <- err
	}

	err = ledgermanager.UpdateState(wallet.DocType_TokenWallet, airDrop.TokenWalletId, walletToMap, ctx)
	if err != nil {
		errChan <- err
	}

	// balanceOf
	balanceKey, err := ctx.GetStub().CreateCompositeKey(token.BalanceOfByPartitionPrefix, []string{airDrop.TokenWalletId, airDrop.TokenId})
	if err != nil {
		errChan <- err
	}

	balanceOfBytes, err := ledgermanager.GetState(token.DocType_Token, balanceKey, ctx)
	if err != nil {
		errChan <- err
	}

	balanceOfData := token.PartitionToken{}
	err = json.Unmarshal(balanceOfBytes, &balanceOfData)
	if err != nil {
		errChan <- err
	}

	balanceOfData.Amount = 0

	balanceOfToMap, err := ccutils.StructToMap(balanceOfData)
	if err != nil {
		errChan <- err
	}

	err = ledgermanager.UpdateState(token.DocType_Token, balanceKey, balanceOfToMap, ctx)
	if err != nil {
		errChan <- err
	}

	// all good - send nil to the error channel
	errChan <- nil

	// defer wg.Done()
	wg.Done()
}

func SetAdminWallet(ctx contractapi.TransactionContextInterface, listStruct *token.TokenHolderList) error {

	// admin
	adminBytes, err := ledgermanager.GetState(wallet.DocType_AdminWallet, "AdminWallet", ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	adminStruct := wallet.AdminWallet{}
	err = json.Unmarshal(adminBytes, &adminStruct)
	if err != nil {
		logger.Error(err)
		return err
	}

	for _, value := range listStruct.Recipient2 {

		a := adminStruct.PartitionTokens[value.TokenId][value.TokenWalletId]
		a = listStruct.TokenInfo
		a.Amount = value.Amount
		adminStruct.PartitionTokens[value.TokenId][value.TokenWalletId] = a

		logger.Infof("success transfer %v token (amount : %v), wallet %v to admin %v", listStruct.PartitionToken, value.Amount, value.TokenWalletId, adminStruct.AdminName)
	}

	adminToMap, err := ccutils.StructToMap(adminStruct)
	if err != nil {
		logger.Error(err)
		return err
	}

	err = ledgermanager.UpdateState(wallet.DocType_AdminWallet, "AdminWallet", adminToMap, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	// Token
	tokenBytes, err := ledgermanager.GetState(token.DocType_Token, listStruct.PartitionToken, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	tokenStruct := token.PartitionToken{}
	if err := json.Unmarshal(tokenBytes, &tokenStruct); err != nil {
		logger.Error(err)
		return err
	}

	tokenStruct.IsLocked = true

	tokenToMap, err := ccutils.StructToMap(tokenStruct)
	if err != nil {
		logger.Error(err)
		return err
	}

	err = ledgermanager.UpdateState(token.DocType_Token, listStruct.PartitionToken, tokenToMap, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}
	logger.Infof("token %v is locked", tokenStruct.TokenID)

	return nil
}
