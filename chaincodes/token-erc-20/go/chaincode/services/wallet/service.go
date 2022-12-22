package wallet

import (
	"encoding/json"
	"fmt"
	"reflect"

	"github.com/KyleParkMedium/mdl-chaincode/chaincode/ccutils"
	"github.com/KyleParkMedium/mdl-chaincode/chaincode/ledgermanager"
	"github.com/KyleParkMedium/mdl-chaincode/chaincode/services/token"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func CreateWallet(ctx contractapi.TransactionContextInterface, tokenWallet TokenWallet) (*TokenWallet, error) {
	_, err := ledgermanager.PutState(DocType_TokenWallet, tokenWallet.TokenWalletId, tokenWallet, ctx)
	if err != nil {
		return nil, err
	}
	return &tokenWallet, nil
}

func TransferByPartition(ctx contractapi.TransactionContextInterface, transferByPartition token.TransferByPartitionStruct) error {

	fromBytes, err := ledgermanager.GetState(DocType_TokenWallet, transferByPartition.From, ctx)
	if err != nil {
		return err
	}

	fromWallet := TokenWallet{}
	err = json.Unmarshal(fromBytes, &fromWallet)
	if err != nil {
		return err
	}

	if reflect.ValueOf(fromWallet.PartitionTokens[transferByPartition.Partition]).IsZero() {
		return fmt.Errorf("partition data in From Wallet does not exist")
	}

	toBytes, err := ledgermanager.GetState(DocType_TokenWallet, transferByPartition.To, ctx)
	if err != nil {
		return err
	}

	toWallet := TokenWallet{}
	err = json.Unmarshal(toBytes, &toWallet)
	if err != nil {
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
		return err
	}
	toToMap, err := ccutils.StructToMap(toWallet)
	if err != nil {
		return err
	}

	err = ledgermanager.UpdateState(DocType_TokenWallet, transferByPartition.From, fromToMap, ctx)
	if err != nil {
		return err
	}
	err = ledgermanager.UpdateState(DocType_TokenWallet, transferByPartition.To, toToMap, ctx)
	if err != nil {
		return err
	}

	// balanceOf
	fromBalanceKey, err := ctx.GetStub().CreateCompositeKey(token.BalanceOfByPartitionPrefix, []string{transferByPartition.From, transferByPartition.Partition})
	if err != nil {
		return err
	}

	fromPartitionToken := token.PartitionToken{}
	fromPartitionToken.DocType = token.DocType_Token
	fromPartitionToken.Amount = fromUpdatedBalance
	fromPartitionTokenBytes, err := json.Marshal(fromPartitionToken)
	if err != nil {
		return err
	}

	err = ctx.GetStub().PutState(fromBalanceKey, fromPartitionTokenBytes)
	if err != nil {
		return err
	}

	toBalanceKey, err := ctx.GetStub().CreateCompositeKey(token.BalanceOfByPartitionPrefix, []string{transferByPartition.To, transferByPartition.Partition})
	if err != nil {
		return err
	}

	toPartitionToken := token.PartitionToken{}
	toPartitionToken.DocType = token.DocType_Token
	toPartitionToken.Amount = toUpdatedBalance
	toPartitionTokenBytes, err := json.Marshal(toPartitionToken)
	if err != nil {
		return err
	}

	err = ctx.GetStub().PutState(toBalanceKey, toPartitionTokenBytes)
	if err != nil {
		return err
	}

	return nil
}

func MintByPartition(ctx contractapi.TransactionContextInterface, mintByPartition token.MintByPartitionStruct) error {

	walletBytes, err := ledgermanager.GetState(DocType_TokenWallet, mintByPartition.Minter, ctx)
	if err != nil {
		return err
	}

	wallet := TokenWallet{}
	err = json.Unmarshal(walletBytes, &wallet)
	if err != nil {
		return err
	}

	exist := true

	if reflect.ValueOf(wallet.PartitionTokens[mintByPartition.Partition]).IsZero() {
		exist = false
	}

	// wallet.PartitionTokens[mintByPartition.Partition] = append(wallet.PartitionTokens[mintByPartition.Partition], token.PartitionToken{Amount: mintByPartition.Amount})
	// wallet.PartitionTokens[mintByPartition.Partition] = append(wallet.PartitionTokens[mintByPartition.Partition], token.PartitionToken{Amount: mintByPartition.Amount})

	// BalanceOf
	var afterBalance int64
	balanceKey, err := ctx.GetStub().CreateCompositeKey(token.BalanceOfByPartitionPrefix, []string{mintByPartition.Minter, mintByPartition.Partition})
	if err != nil {
		return err
	}

	if exist {
		wallet.PartitionTokens[mintByPartition.Partition][0].Amount += mintByPartition.Amount

		mintByPartitionToMap, err := ccutils.StructToMap(wallet)
		if err != nil {
			return err
		}

		err = ledgermanager.UpdateState(DocType_TokenWallet, mintByPartition.Minter, mintByPartitionToMap, ctx)
		if err != nil {
			return err
		}

		afterBalance = wallet.PartitionTokens[mintByPartition.Partition][0].Amount
		partitionToken := token.PartitionToken{Amount: afterBalance}
		balanceOfByPartitionToMap, err := ccutils.StructToMap(partitionToken)
		if err != nil {
			return err
		}

		err = ledgermanager.UpdateState(token.DocType_Token, balanceKey, balanceOfByPartitionToMap, ctx)
		if err != nil {
			return err
		}

	} else {
		partitionTokenMap := make(map[string][]token.PartitionToken)
		partitionTokenMap[mintByPartition.Partition] = append(partitionTokenMap[mintByPartition.Partition], token.PartitionToken{Amount: mintByPartition.Amount})

		wallet.PartitionTokens[mintByPartition.Partition] = partitionTokenMap[mintByPartition.Partition]
		wallet.PartitionTokens[mintByPartition.Partition][0] = token.PartitionToken{Amount: mintByPartition.Amount}

		mintByPartitionToMap, err := ccutils.StructToMap(wallet)
		if err != nil {
			return err
		}

		err = ledgermanager.UpdateState(DocType_TokenWallet, mintByPartition.Minter, mintByPartitionToMap, ctx)
		if err != nil {
			return err
		}

		afterBalance = wallet.PartitionTokens[mintByPartition.Partition][0].Amount
		partitionToken := token.PartitionToken{}
		partitionToken.Amount = afterBalance
		partitionToken.DocType = token.DocType_Token

		partitionTokenBytes, err := json.Marshal(partitionToken)
		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(balanceKey, partitionTokenBytes)
		if err != nil {
			return err
		}
	}

	// Update the totalSupply, totalSupplyByPartition
	totalSupplyBytes, err := ledgermanager.GetState(token.DocType_TotalSupply, "TotalSupply", ctx)
	if err != nil {
		return err
	}

	totalSupply := token.TotalSupplyStruct{}
	if err := json.Unmarshal(totalSupplyBytes, &totalSupply); err != nil {
		return err
	}

	totalSupply.TotalSupply += mintByPartition.Amount

	totalSupplyMap, err := ccutils.StructToMap(totalSupply)
	if err != nil {
		return err
	}

	err = ledgermanager.UpdateState(token.DocType_TotalSupply, "TotalSupply", totalSupplyMap, ctx)
	if err != nil {
		return err
	}

	totalSupplyByPartitionBytes, err := ledgermanager.GetState(token.DocType_TotalSupplyByPartition, mintByPartition.Partition, ctx)
	if err != nil {
		return err
	}

	totalSupplyByPartition := token.TotalSupplyByPartitionStruct{}
	if err := json.Unmarshal(totalSupplyByPartitionBytes, &totalSupplyByPartition); err != nil {
		return err
	}

	totalSupplyByPartition.TotalSupply += mintByPartition.Amount

	totalSupplyByPartitionMap, err := ccutils.StructToMap(totalSupplyByPartition)
	if err != nil {
		return err
	}

	err = ledgermanager.UpdateState(token.DocType_TotalSupplyByPartition, mintByPartition.Partition, totalSupplyByPartitionMap, ctx)
	if err != nil {
		return err
	}

	return nil
}

func BurnByPartition(ctx contractapi.TransactionContextInterface, mintByPartition token.MintByPartitionStruct) error {

	walletBytes, err := ledgermanager.GetState(DocType_TokenWallet, mintByPartition.Minter, ctx)
	if err != nil {
		return err
	}

	wallet := TokenWallet{}
	err = json.Unmarshal(walletBytes, &wallet)
	if err != nil {
		return err
	}

	if reflect.ValueOf(wallet.PartitionTokens[mintByPartition.Partition]).IsZero() {
		return fmt.Errorf("partition data is not exist")
	}

	if wallet.PartitionTokens[mintByPartition.Partition][0].Amount < mintByPartition.Amount {
		return fmt.Errorf("currentBalance is lower than input amount")
	}

	wallet.PartitionTokens[mintByPartition.Partition][0].Amount -= mintByPartition.Amount

	mintByPartitionToMap, err := ccutils.StructToMap(wallet)
	if err != nil {
		return err
	}

	err = ledgermanager.UpdateState(DocType_TokenWallet, mintByPartition.Minter, mintByPartitionToMap, ctx)
	if err != nil {
		return err
	}

	// Update the totalSupply, totalSupplyByPartition
	totalSupplyBytes, err := ledgermanager.GetState(token.DocType_TotalSupply, "TotalSupply", ctx)
	if err != nil {
		return err
	}

	totalSupply := token.TotalSupplyStruct{}
	if err := json.Unmarshal(totalSupplyBytes, &totalSupply); err != nil {
		return err
	}

	totalSupply.TotalSupply -= mintByPartition.Amount

	totalSupplyMap, err := ccutils.StructToMap(totalSupply)
	if err != nil {
		return err
	}

	err = ledgermanager.UpdateState(token.DocType_TotalSupply, "TotalSupply", totalSupplyMap, ctx)
	if err != nil {
		return err
	}

	totalSupplyByPartitionBytes, err := ledgermanager.GetState(token.DocType_TotalSupplyByPartition, mintByPartition.Partition, ctx)
	if err != nil {
		return err
	}

	totalSupplyByPartition := token.TotalSupplyByPartitionStruct{}
	if err := json.Unmarshal(totalSupplyByPartitionBytes, &totalSupplyByPartition); err != nil {
		return err
	}

	totalSupplyByPartition.TotalSupply -= mintByPartition.Amount

	totalSupplyByPartitionMap, err := ccutils.StructToMap(totalSupplyByPartition)
	if err != nil {
		return err
	}

	err = ledgermanager.UpdateState(token.DocType_TotalSupplyByPartition, mintByPartition.Partition, totalSupplyByPartitionMap, ctx)
	if err != nil {
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
		return nil, err
	}

	return bytes, nil
}
