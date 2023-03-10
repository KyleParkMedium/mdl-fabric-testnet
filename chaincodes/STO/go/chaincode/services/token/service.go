package token

import (
	"encoding/json"
	"fmt"
	"math/big"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"

	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils/flogging"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ledgermanager"
)

var logger = flogging.MustGetLogger("token service")

func TotalSupply(ctx contractapi.TransactionContextInterface) (*TotalSupplyStruct, error) {

	totalSupplyBytes, err := ledgermanager.GetState(DocType_TotalSupply, "TotalSupply", ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	totalSupply := TotalSupplyStruct{}
	if err := json.Unmarshal(totalSupplyBytes, &totalSupply); err != nil {
		logger.Error(err)
		return nil, err
	}

	return &totalSupply, nil
}

func TotalSupplyByPartition(ctx contractapi.TransactionContextInterface, partition string) (*TotalSupplyByPartitionStruct, error) {

	// totalSupplyByPartition
	totalKey, err := ctx.GetStub().CreateCompositeKey(DocType_TotalSupplyByPartition, []string{partition})
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	totalSupplyBytes, err := ledgermanager.GetState(DocType_TotalSupplyByPartition, totalKey, ctx)
	if err != nil {
		logger.Error(err)
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
	balanceOfKey, err := ctx.GetStub().CreateCompositeKey(BalanceOfByPartitionPrefix, []string{_tokenHolder, _partition})
	if err != nil {
		return 0, fmt.Errorf("failed to create the composite key for prefix %s: %v", BalanceOfByPartitionPrefix, err)
	}

	partitionTokenBytes, err := ledgermanager.GetState(DocType_Token, balanceOfKey, ctx)
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
		logger.Error(err)
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
		logger.Error(err)
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

	// Issue Token
	_, err := ledgermanager.PutState(DocType_Token, token.TokenID, token, ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}
	logger.Infof("success putstate ledger : %v", token.TokenID)

	// totalSupplyByPartition
	totalKey, err := ctx.GetStub().CreateCompositeKey(DocType_TotalSupplyByPartition, []string{token.TokenID})
	if err != nil {
		return nil, fmt.Errorf("failed to create the composite key for prefix %s: %v", DocType_TotalSupplyByPartition, err)
	}

	_, err = ledgermanager.PutState(DocType_TotalSupplyByPartition, totalKey, TotalSupplyByPartitionStruct{DocType: DocType_TotalSupplyByPartition, TotalSupply: 0, ToTalSupplyBig: big.NewInt(0), Partition: token.TokenID}, ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}
	logger.Infof("success putstate totalSupplyByPartition : %v", token.TokenID)

	// initialize token holder ledger
	holderStruct := TokenHolderList{}
	holderStruct.DocType = DocType_TokenHolderList
	holderStruct.TokenId = token.TokenID
	holderStruct.TokenInfo = token
	holderStruct.IsLocked = false
	holderStruct.IsDistributed = false
	holderStruct.IsRedeemed = false
	recipients := make(map[string]Recipient)
	holderStruct.Recipients = recipients

	// Create holderList Key
	holderListKey, err := ctx.GetStub().CreateCompositeKey(DocType_TokenHolderList, []string{token.TokenID})
	if err != nil {
		return nil, fmt.Errorf("failed to create the composite key for prefix %s: %v", BalanceOfByPartitionPrefix, err)
	}

	_, err = ledgermanager.PutState(DocType_TokenHolderList, holderListKey, holderStruct, ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}
	logger.Infof("success initialize tokenHolderList : %v", token.TokenID)

	return &token, nil
}

// 만약 undo 기능이 추가된다면, 투자 모집 진행 중 undo 발생 시 이를 어떻게 처리할거냐에 대한 고려가 들어가야함. 일단 이렇게만 적어놓겠음.
func UndoIssueToken(ctx contractapi.TransactionContextInterface, token PartitionToken) (*PartitionToken, error) {

	// lock token
	tokenBytes, err := ledgermanager.GetState(DocType_Token, token.TokenID, ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	tokenStruct := PartitionToken{}
	err = json.Unmarshal(tokenBytes, &tokenStruct)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	if token.Publisher != tokenStruct.Publisher {
		return nil, fmt.Errorf("token publisher differs from caller")
	}

	tokenStruct.IsLocked = true

	tokenToMap, err := ccutils.StructToMap(tokenStruct)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	err = ledgermanager.UpdateState(DocType_Token, token.TokenID, tokenToMap, ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	// lock token holder list
	holderListKey, err := ctx.GetStub().CreateCompositeKey(DocType_TokenHolderList, []string{token.TokenID})
	if err != nil {
		return nil, fmt.Errorf("failed to create the composite key for prefix %s: %v", DocType_TokenHolderList, err)
	}

	holderListBytes, err := ledgermanager.GetState(DocType_TokenHolderList, holderListKey, ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	holderListStruct := TokenHolderList{}
	err = json.Unmarshal(holderListBytes, &holderListStruct)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	holderListStruct.IsLocked = true
	holderListToMap, err := ccutils.StructToMap(holderListStruct)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	err = ledgermanager.UpdateState(DocType_TokenHolderList, holderListKey, holderListToMap, ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	return &tokenStruct, nil
}

func IsIssuable(ctx contractapi.TransactionContextInterface, partition string) error {

	tokenBytes, err := ledgermanager.GetState(DocType_Token, partition, ctx)
	if err != nil {
		logger.Error(err)
		return err
	}

	tokenStruct := PartitionToken{}
	err = json.Unmarshal(tokenBytes, &tokenStruct)
	if err != nil {
		logger.Error(err)
		return err
	}

	if tokenStruct.IsLocked == true {
		return fmt.Errorf("token is locked")
	}

	return nil
}

func GetData(args map[string]interface{}, pageSize int32, bookmark string, ctx contractapi.TransactionContextInterface) ([]byte, error) {

	queryBuilder := ccutils.QueryBuilder{}

	// condition field
	if value, exist := args[ledgermanager.StartDate]; exist {
		queryBuilder.AddSelectorGroupCondition(ledgermanager.CreatedDate, "$gte", value)
	}

	if value, exist := args[ledgermanager.EndDate]; exist {
		queryBuilder.AddSelectorGroupCondition(ledgermanager.CreatedDate, "$lt", value)
	}

	query := ccutils.Query{}

	// selector
	selector, ok := args["selector"].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("selector is blank")
	}
	err := query.AddSelector(selector)

	// // fields
	// fields, ok := args["fields"].([]interface{})
	// if !ok {
	// 	return nil, fmt.Errorf("fields is blank")
	// }
	// err = query.AddFields(fields)

	// use_index
	index, ok := args["use_index"].([]interface{})
	if !ok {
		return nil, fmt.Errorf("use_index is blank")
	}
	err = query.AddIndex(index)

	// sort
	sort, ok := args["sort"].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("sort is blank")
	}
	for key, value := range sort {
		c := make(map[string]string)
		c[key] = value.(string)
		err = query.AddSort(c)
	}

	queryString, err := query.MakeQueryString()
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	bytes, err := ledgermanager.GetQueryResultWithPagination(queryString, pageSize, bookmark, ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	return bytes, nil

	// // 고유 필드
	// for a, b := range selector {
	// 	queryBuilder.AddSelectorGroup(a, b)
	// }

	// stringParameterFields := []string{ledgermanager.DocType, FieldPartition, FieldOwner, FieldSpender, FieldFrom, FieldTo, FieldTokenWalletId, FieldRole, FieldTokenId, FieldPublisher, FieldAccountNumber, FieldRor, FieldInvestmentPeriod, FieldGrade, FieldCaller}
	// for _, stringField := range stringParameterFields {
	// 	if value, exist := selector[stringField]; exist {
	// 		// err := ccutils.CheckRequireTypeString([]string{stringField}, selector)
	// 		// if err != nil {
	// 		// 	return nil, err
	// 		// }
	// 		queryBuilder.AddSelectorGroup(stringField, value)
	// 	}
	// }

	// // sort
	// sort := args["sort"].(map[string]interface{})
	// stringParameterFields := []string{ledgermanager.DocType, FieldPartition, FieldOwner, FieldSpender, FieldFrom, FieldTo, FieldTokenWalletId, FieldRole, FieldTokenId, FieldPublisher, FieldAccountNumber, FieldRor, FieldInvestmentPeriod, FieldGrade, FieldCaller}
	// for _, stringField := range stringParameterFields {
	// 	if value, exist := sort[stringField]; exist {
	// 		// err := ccutils.CheckRequireTypeString([]string{stringField}, sort)
	// 		// if err != nil {
	// 		// 	return nil, err
	// 		// }
	// 		queryBuilder.AddSortField(stringField, value)
	// 	}
	// }

	// // fields
	// field := args["fields"].(map[string]interface{})
	// stringParameterFields = []string{ledgermanager.DocType, FieldPartition, FieldOwner, FieldSpender, FieldFrom, FieldTo, FieldTokenWalletId, FieldRole, FieldTokenId, FieldPublisher, FieldAccountNumber, FieldRor, FieldInvestmentPeriod, FieldGrade, FieldCaller}
	// for _, stringField := range stringParameterFields {
	// 	if _, exist := field[stringField]; exist {
	// 		// err := ccutils.CheckRequireTypeString([]string{stringField}, field)
	// 		// if err != nil {
	// 		// 	return nil, err
	// 		// }
	// 		queryBuilder.AddFieldGroup(stringField)
	// 	}
	// }

	// // 고유 필드

	// // "partitionTokens": "medium82",
	// // 객체 내 객체
	// objectParameterFields := FieldPartitionTokens
	// if value, exist := args[objectParameterFields]; exist {

	// 	imsy := args[FieldTokenHolder].(string)

	// 	field := fmt.Sprintf("%s.%s.%s", objectParameterFields, value, imsy)

	// 	// var myInterface interface{}
	// 	// myInterface = field
	// 	queryBuilder.AddSelectorKey(field)
	// }

	// boolParameterFields := []string{FieldIsLocked, FieldIsDistributed, FieldIsRedeemed}
	// for _, boolField := range boolParameterFields {
	// 	if value, exist := args[boolField]; exist {
	// 		err := ccutils.CheckRequireTypeBool([]string{boolField}, args)
	// 		if err != nil {
	// 			return nil, err
	// 		}
	// 		queryBuilder.AddSelectorGroup(boolField, value)
	// 	}
	// }

	// int64ParameterFields := []string{FieldAmount, FieldPublicOfferingAmount}
	// for _, int64Field := range int64ParameterFields {
	// 	if value, exist := args[int64Field]; exist {
	// 		err := ccutils.CheckRequireTypeInt64([]string{int64Field}, args)
	// 		if err != nil {
	// 			return nil, err
	// 		}
	// 		queryBuilder.AddSelectorGroup(int64Field, value)
	// 	}
	// }

	// queryString := queryBuilder.MakeQueryString()

	// bytes, err := ledgermanager.GetQueryResultWithPagination(queryString, pageSize, bookmark, ctx)
	// if err != nil {
	// 	logger.Error(err)
	// 	return nil, err
	// }

	// return bytes, nil
}

func GetToken(args map[string]interface{}, partition string, pageSize int32, bookmark string, ctx contractapi.TransactionContextInterface) ([]byte, error) {

	queryBuilder := ccutils.QueryBuilder{}
	queryBuilder.AddSelectorGroup(ledgermanager.DocType, DocType_Token)
	queryBuilder.AddSelectorGroup("_id", partition)

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

func GetTokenList(args map[string]interface{}, pageSize int32, bookmark string, ctx contractapi.TransactionContextInterface) ([]byte, error) {

	queryBuilder := ccutils.QueryBuilder{}
	queryBuilder.AddSelectorGroup(ledgermanager.DocType, DocType_Token)

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

func GetTokenHolderList(args map[string]interface{}, partition string, pageSize int32, bookmark string, ctx contractapi.TransactionContextInterface) ([]byte, error) {

	// Create allowanceKey
	listKey, err := ctx.GetStub().CreateCompositeKey(DocType_TokenHolderList, []string{partition})
	if err != nil {
		return nil, fmt.Errorf("failed to create the composite key for prefix %s: %v", DocType_TokenHolderList, err)
	}

	queryBuilder := ccutils.QueryBuilder{}
	queryBuilder.AddSelectorGroup(ledgermanager.DocType, DocType_TokenHolderList)
	queryBuilder.AddSelectorGroup("_id", listKey)

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
