package wallet

import (
	"encoding/json"
	"fmt"
	"reflect"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"

	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils/flogging"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ledgermanager"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/token"
)

var logger = flogging.MustGetLogger("wallet service")

func CreateWallet(ctx contractapi.TransactionContextInterface, tokenWallet TokenWallet) (*TokenWallet, error) {

	_, err := ledgermanager.PutState(DocType_TokenWallet, tokenWallet.TokenWalletId, tokenWallet, ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}
	logger.Infof("success putstate ledger : %v", tokenWallet.TokenWalletId)

	return &tokenWallet, nil
}

func TransferByPartition(ctx contractapi.TransactionContextInterface, transferByPartition token.TransferByPartitionStruct) error {

	fromBytes, err := ledgermanager.GetState(DocType_TokenWallet, transferByPartition.From, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	fromWallet := TokenWallet{}
	err = json.Unmarshal(fromBytes, &fromWallet)
	if err != nil {
		logger.Error(err)
		return err
	}

	if reflect.ValueOf(fromWallet.PartitionTokens[transferByPartition.Partition]).IsZero() {
		return fmt.Errorf("partition data in From Wallet does not exist")
	}

	toBytes, err := ledgermanager.GetState(DocType_TokenWallet, transferByPartition.To, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	toWallet := TokenWallet{}
	err = json.Unmarshal(toBytes, &toWallet)
	if err != nil {
		logger.Error(err)
		return err
	}

	// 이건 기획팀과 회의가 필요함 2차 거래에서의 조건임
	// if reflect.ValueOf(toWallet.PartitionTokens[transferByPartition.Partition]).IsZero() {
	// 	return fmt.Errorf("partition data is not exist")
	// }

	fromCurrentBalance := fromWallet.PartitionTokens[transferByPartition.Partition][0].Amount
	if fromCurrentBalance < transferByPartition.Amount {
		return fmt.Errorf("client account %s has insufficient funds", fromWallet.TokenWalletId)
	}

	// Math
	fromUpdatedBalance := fromCurrentBalance - transferByPartition.Amount
	fromWallet.PartitionTokens[transferByPartition.Partition][0].Amount = fromUpdatedBalance

	// toUpdatedBalance := toCurrentBalance + transferByPartition.Amount
	// toWallet.PartitionTokens[transferByPartition.Partition][0].Amount = toUpdatedBalance

	var toUpdatedBalance int64
	// 우선 이렇게 처리
	if reflect.ValueOf(toWallet.PartitionTokens[transferByPartition.Partition]).IsZero() {
		partitionTokenMap := make(map[string][]token.PartitionToken)
		partitionTokenMap[transferByPartition.Partition] = append(partitionTokenMap[transferByPartition.Partition], token.PartitionToken{Amount: transferByPartition.Amount})
		toWallet.PartitionTokens = partitionTokenMap
		toUpdatedBalance = transferByPartition.Amount
	} else {
		toWallet.PartitionTokens[transferByPartition.Partition][0].Amount += transferByPartition.Amount
		toUpdatedBalance = toWallet.PartitionTokens[transferByPartition.Partition][0].Amount
	}

	fromToMap, err := ccutils.StructToMap(fromWallet)
	if err != nil {
		logger.Error(err)
		return err
	}
	toToMap, err := ccutils.StructToMap(toWallet)
	if err != nil {
		logger.Error(err)
		return err
	}

	err = ledgermanager.UpdateState(DocType_TokenWallet, transferByPartition.From, fromToMap, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}
	err = ledgermanager.UpdateState(DocType_TokenWallet, transferByPartition.To, toToMap, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	// balanceOf
	fromBalanceKey, err := ctx.GetStub().CreateCompositeKey(token.BalanceOfByPartitionPrefix, []string{transferByPartition.From, transferByPartition.Partition})
	if err != nil {
		logger.Error(err)
		return err
	}

	fromPartitionToken := token.PartitionToken{}
	fromPartitionToken.DocType = token.DocType_Token
	fromPartitionToken.Amount = fromUpdatedBalance
	fromPartitionTokenBytes, err := json.Marshal(fromPartitionToken)
	if err != nil {
		logger.Error(err)
		return err
	}

	err = ctx.GetStub().PutState(fromBalanceKey, fromPartitionTokenBytes)
	if err != nil {
		logger.Error(err)
		return err
	}

	toBalanceKey, err := ctx.GetStub().CreateCompositeKey(token.BalanceOfByPartitionPrefix, []string{transferByPartition.To, transferByPartition.Partition})
	if err != nil {
		logger.Error(err)
		return err
	}

	toPartitionToken := token.PartitionToken{}
	toPartitionToken.DocType = token.DocType_Token
	toPartitionToken.Amount = toUpdatedBalance
	toPartitionTokenBytes, err := json.Marshal(toPartitionToken)
	if err != nil {
		logger.Error(err)
		return err
	}

	err = ctx.GetStub().PutState(toBalanceKey, toPartitionTokenBytes)
	if err != nil {
		logger.Error(err)
		return err
	}

	return nil
}

func MintByPartition(ctx contractapi.TransactionContextInterface, mintByPartition token.MintByPartitionStruct) error {

	tokenBytes, err := ledgermanager.GetState(token.DocType_Token, mintByPartition.Partition, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	tokenStruct := token.PartitionToken{}
	if err := json.Unmarshal(tokenBytes, &tokenStruct); err != nil {
		logger.Error(err)
		return err
	}

	if tokenStruct.IsLocked == true {
		return fmt.Errorf("%v token is already locked", mintByPartition.Partition)
	}

	// Get Holder List
	holderListKey, err := ctx.GetStub().CreateCompositeKey(token.DocType_TokenHolderList, []string{mintByPartition.Partition})
	if err != nil {
		logger.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_TokenHolderList, err)
		return fmt.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_TokenHolderList, err)
	}

	holderListBytes, err := ledgermanager.GetState(token.DocType_TokenHolderList, holderListKey, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	holderListStruct := token.TokenHolderList{}
	err = json.Unmarshal(holderListBytes, &holderListStruct)
	if err != nil {
		logger.Error(err)
		return err
	}

	if holderListStruct.IsDistributed == false {
		return fmt.Errorf("you have to run the distribution first : %v token", mintByPartition.Partition)
	}

	walletBytes, err := ledgermanager.GetState(DocType_TokenWallet, mintByPartition.Minter, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	wallet := TokenWallet{}
	err = json.Unmarshal(walletBytes, &wallet)
	if err != nil {
		logger.Error(err)
		return err
	}

	wallet.PartitionTokens[mintByPartition.Partition][0].AddAmount(mintByPartition.Amount)

	mintByPartitionToMap, err := ccutils.StructToMap(wallet)
	if err != nil {
		return err
	}

	err = ledgermanager.UpdateState(DocType_TokenWallet, mintByPartition.Minter, mintByPartitionToMap, ctx)
	if err != nil {
		return err
	}

	changeValue := holderListStruct.Recipients[mintByPartition.Minter]
	changeValue.Amount = wallet.PartitionTokens[mintByPartition.Partition][0].Amount
	holderListStruct.Recipients[mintByPartition.Minter] = changeValue

	listToMap, err := ccutils.StructToMap(holderListStruct)
	if err != nil {
		logger.Error(err)
		return err
	}

	err = ledgermanager.UpdateState(token.DocType_TokenHolderList, holderListKey, listToMap, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	// BalanceOf
	balanceOfKey, err := ctx.GetStub().CreateCompositeKey(token.BalanceOfByPartitionPrefix, []string{mintByPartition.Minter, mintByPartition.Partition})
	if err != nil {
		logger.Error(err)
		return err
	}

	partitionTokenBytes, err := ledgermanager.GetState(token.DocType_Token, balanceOfKey, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	partitionToken := token.PartitionToken{}
	if err := json.Unmarshal(partitionTokenBytes, &partitionToken); err != nil {
		logger.Error(err)
		return err
	}

	partitionToken.Amount = wallet.PartitionTokens[mintByPartition.Partition][0].Amount

	balanceOfByPartitionToMap, err := ccutils.StructToMap(partitionToken)
	if err != nil {
		return err
	}

	err = ledgermanager.UpdateState(token.DocType_Token, balanceOfKey, balanceOfByPartitionToMap, ctx)
	if err != nil {
		return err
	}

	// Update the totalSupply, totalSupplyByPartition
	totalSupplyBytes, err := ledgermanager.GetState(token.DocType_TotalSupply, "TotalSupply", ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	totalSupply := token.TotalSupplyStruct{}
	if err := json.Unmarshal(totalSupplyBytes, &totalSupply); err != nil {
		return err
	}

	err = totalSupply.AddAmount(mintByPartition.Amount)
	if err != nil {
		logger.Error(err)
		return err
	}

	totalSupplyMap, err := ccutils.StructToMap(totalSupply)
	if err != nil {
		logger.Error(err)
		return err
	}

	err = ledgermanager.UpdateState(token.DocType_TotalSupply, "TotalSupply", totalSupplyMap, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	// totalSupplyByPartition
	totalKey, err := ctx.GetStub().CreateCompositeKey(token.DocType_TotalSupplyByPartition, []string{mintByPartition.Partition})
	if err != nil {
		return fmt.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_TotalSupplyByPartition, err)
	}

	totalSupplyByPartitionBytes, err := ledgermanager.GetState(token.DocType_TotalSupplyByPartition, totalKey, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	totalSupplyByPartition := token.TotalSupplyByPartitionStruct{}
	if err := json.Unmarshal(totalSupplyByPartitionBytes, &totalSupplyByPartition); err != nil {
		return err
	}

	totalSupplyByPartition.AddAmount(mintByPartition.Amount)

	totalSupplyByPartitionMap, err := ccutils.StructToMap(totalSupplyByPartition)
	if err != nil {
		logger.Error(err)
		return err
	}

	err = ledgermanager.UpdateState(token.DocType_TotalSupplyByPartition, totalKey, totalSupplyByPartitionMap, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	return nil
}

func BurnByPartition(ctx contractapi.TransactionContextInterface, burnByPartition token.MintByPartitionStruct) error {

	tokenBytes, err := ledgermanager.GetState(token.DocType_Token, burnByPartition.Partition, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	tokenStruct := token.PartitionToken{}
	if err := json.Unmarshal(tokenBytes, &tokenStruct); err != nil {
		logger.Error(err)
		return err
	}

	if tokenStruct.IsLocked == true {
		return fmt.Errorf("%v token is already locked", burnByPartition.Partition)
	}

	// Get Holder List
	holderListKey, err := ctx.GetStub().CreateCompositeKey(token.DocType_TokenHolderList, []string{burnByPartition.Partition})
	if err != nil {
		logger.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_TokenHolderList, err)
		return fmt.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_TokenHolderList, err)
	}

	holderListBytes, err := ledgermanager.GetState(token.DocType_TokenHolderList, holderListKey, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	holderListStruct := token.TokenHolderList{}
	err = json.Unmarshal(holderListBytes, &holderListStruct)
	if err != nil {
		logger.Error(err)
		return err
	}

	if holderListStruct.IsDistributed == false {
		return fmt.Errorf("you have to run the distribution first : %v token", burnByPartition.Partition)
	}

	walletBytes, err := ledgermanager.GetState(DocType_TokenWallet, burnByPartition.Minter, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	wallet := TokenWallet{}
	err = json.Unmarshal(walletBytes, &wallet)
	if err != nil {
		logger.Error(err)
		return err
	}

	err = wallet.PartitionTokens[burnByPartition.Partition][0].SubAmount(burnByPartition.Amount)
	if err != nil {
		logger.Error(err)
		return err
	}

	burnByPartitionToMap, err := ccutils.StructToMap(wallet)
	if err != nil {
		logger.Error(err)
		return err
	}

	err = ledgermanager.UpdateState(DocType_TokenWallet, burnByPartition.Minter, burnByPartitionToMap, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	changeValue := holderListStruct.Recipients[burnByPartition.Minter]
	changeValue.Amount = wallet.PartitionTokens[burnByPartition.Partition][0].Amount
	holderListStruct.Recipients[burnByPartition.Minter] = changeValue

	listToMap, err := ccutils.StructToMap(holderListStruct)
	if err != nil {
		logger.Error(err)
		return err
	}

	err = ledgermanager.UpdateState(token.DocType_TokenHolderList, holderListKey, listToMap, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	// BalanceOf
	balanceOfKey, err := ctx.GetStub().CreateCompositeKey(token.BalanceOfByPartitionPrefix, []string{burnByPartition.Minter, burnByPartition.Partition})
	if err != nil {
		logger.Error(err)
		return err
	}

	partitionTokenBytes, err := ledgermanager.GetState(token.DocType_Token, balanceOfKey, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	partitionToken := token.PartitionToken{}
	if err := json.Unmarshal(partitionTokenBytes, &partitionToken); err != nil {
		logger.Error(err)
		return err
	}

	partitionToken.Amount = wallet.PartitionTokens[burnByPartition.Partition][0].Amount

	balanceOfByPartitionToMap, err := ccutils.StructToMap(partitionToken)
	if err != nil {
		return err
	}

	err = ledgermanager.UpdateState(token.DocType_Token, balanceOfKey, balanceOfByPartitionToMap, ctx)
	if err != nil {
		return err
	}

	// Update the totalSupply, totalSupplyByPartition
	totalSupplyBytes, err := ledgermanager.GetState(token.DocType_TotalSupply, "TotalSupply", ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	totalSupply := token.TotalSupplyStruct{}
	if err := json.Unmarshal(totalSupplyBytes, &totalSupply); err != nil {
		return err
	}

	totalSupply.SubAmount(burnByPartition.Amount)

	totalSupplyMap, err := ccutils.StructToMap(totalSupply)
	if err != nil {
		logger.Error(err)
		return err
	}

	err = ledgermanager.UpdateState(token.DocType_TotalSupply, "TotalSupply", totalSupplyMap, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	totalKey, err := ctx.GetStub().CreateCompositeKey(token.DocType_TotalSupplyByPartition, []string{burnByPartition.Partition})
	if err != nil {
		return fmt.Errorf("failed to create the composite key for prefix %s: %v", token.DocType_TotalSupplyByPartition, err)
	}

	totalSupplyByPartitionBytes, err := ledgermanager.GetState(token.DocType_TotalSupplyByPartition, totalKey, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	totalSupplyByPartition := token.TotalSupplyByPartitionStruct{}
	if err := json.Unmarshal(totalSupplyByPartitionBytes, &totalSupplyByPartition); err != nil {
		return err
	}

	totalSupplyByPartition.SubAmount(burnByPartition.Amount)

	totalSupplyByPartitionMap, err := ccutils.StructToMap(totalSupplyByPartition)
	if err != nil {
		logger.Error(err)
		return err
	}

	err = ledgermanager.UpdateState(token.DocType_TotalSupplyByPartition, totalKey, totalSupplyByPartitionMap, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	return nil
}

func GetTokenWalletList(args map[string]interface{}, pageSize int32, bookmark string, ctx contractapi.TransactionContextInterface) ([]byte, error) {
	queryBuilder := ccutils.QueryBuilder{}
	queryBuilder.AddSelectorGroup(ledgermanager.DocType, DocType_TokenWallet)

	// 공통 필드
	if value, exist := args[ledgermanager.StartDate]; exist {
		queryBuilder.AddSelectorGroupCondition(ledgermanager.CreatedDate, "$gte", value)
	}

	if value, exist := args[ledgermanager.EndDate]; exist {
		queryBuilder.AddSelectorGroupCondition(ledgermanager.CreatedDate, "$lt", value)
	}

	// // 고유 필드
	// stringParameterFields := []string{FieldPublisherAuthWalletId, FieldExpiredDate, FieldTokenId}
	// for _, stringField := range stringParameterFields {
	// 	if value, exist := args[stringField]; exist {
	// 		err := ccutils.CheckRequireTypeString([]string{stringField}, args)
	// 		if err != nil {
	// 			return nil, err
	// 		}
	// 		queryBuilder.AddSelectorGroup(stringField, value)
	// 	}
	// }

	// boolParameterFields := []string{FieldIsLocked, FieldIsTradePossible, FieldIsSettlementPossible, FieldIsChargePossible,
	// 	FieldIsExchangePossible, FieldIsExtAsstDepositPossible, FieldIsExtAsstWithdrawalPossible}
	// for _, boolField := range boolParameterFields {
	// 	if value, exist := args[boolField]; exist {
	// 		err := ccutils.CheckRequireTypeBool([]string{boolField}, args)
	// 		if err != nil {
	// 			return nil, err
	// 		}
	// 		queryBuilder.AddSelectorGroup(boolField, value)
	// 	}
	// }

	queryString := queryBuilder.MakeQueryString()

	bytes, err := ledgermanager.GetQueryResultWithPagination(queryString, pageSize, bookmark, ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	return bytes, nil
}

func GetAdminWallet(args map[string]interface{}, pageSize int32, bookmark string, ctx contractapi.TransactionContextInterface) ([]byte, error) {
	queryBuilder := ccutils.QueryBuilder{}
	queryBuilder.AddSelectorGroup(ledgermanager.DocType, DocType_AdminWallet)

	// 공통 필드
	if value, exist := args[ledgermanager.StartDate]; exist {
		queryBuilder.AddSelectorGroupCondition(ledgermanager.CreatedDate, "$gte", value)
	}

	if value, exist := args[ledgermanager.EndDate]; exist {
		queryBuilder.AddSelectorGroupCondition(ledgermanager.CreatedDate, "$lt", value)
	}

	// // 고유 필드
	// stringParameterFields := []string{FieldPublisherAuthWalletId, FieldExpiredDate, FieldTokenId}
	// for _, stringField := range stringParameterFields {
	// 	if value, exist := args[stringField]; exist {
	// 		err := ccutils.CheckRequireTypeString([]string{stringField}, args)
	// 		if err != nil {
	// 			return nil, err
	// 		}
	// 		queryBuilder.AddSelectorGroup(stringField, value)
	// 	}
	// }

	// boolParameterFields := []string{FieldIsLocked, FieldIsTradePossible, FieldIsSettlementPossible, FieldIsChargePossible,
	// 	FieldIsExchangePossible, FieldIsExtAsstDepositPossible, FieldIsExtAsstWithdrawalPossible}
	// for _, boolField := range boolParameterFields {
	// 	if value, exist := args[boolField]; exist {
	// 		err := ccutils.CheckRequireTypeBool([]string{boolField}, args)
	// 		if err != nil {
	// 			return nil, err
	// 		}
	// 		queryBuilder.AddSelectorGroup(boolField, value)
	// 	}
	// }

	queryString := queryBuilder.MakeQueryString()

	bytes, err := ledgermanager.GetQueryResultWithPagination(queryString, pageSize, bookmark, ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	return bytes, nil
}
