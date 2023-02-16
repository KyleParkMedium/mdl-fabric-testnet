package controller

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"

	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils/flogging"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ledgermanager"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/operator"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/token"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/wallet"
)

var logger = flogging.MustGetLogger("controller")

// SmartContract provides functions for transferring tokens between accounts
type SmartContract struct {
	contractapi.Contract
}

// ERC20 Strandard Code
/**
 * @dev Total number of tokens in existence
 */
func (s *SmartContract) TotalSupply(ctx contractapi.TransactionContextInterface) (*ccutils.Response, error) {

	// Check minter authorization - this sample assumes Org1 is the central banker with privilege to mint new tokens
	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		return nil, err
	}

	totalSupply, err := token.TotalSupply(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	retData, err := ccutils.StructToMap(totalSupply)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	log.Printf("TotalSupply: %d tokens", totalSupply)

	logger.Infof("Success function : TotalSupply")
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], retData)
}

// ERC20 Strandard Code
/**
 * @dev Total number of tokens in existence
 */
func (s *SmartContract) TotalSupplyByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	// Check minter authorization - this sample assumes Org1 is the central banker with privilege to mint new tokens
	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	requireParameterFields := []string{token.FieldPartition}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	partition := args[token.FieldPartition].(string)

	totalSupplyByPartition, err := token.TotalSupplyByPartition(ctx, partition)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	retData, err := ccutils.StructToMap(totalSupplyByPartition)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : TotalSupplyByPartition")
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], retData)
}

func (s *SmartContract) BalanceOfByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	// Check minter authorization - this sample assumes Org1 is the central banker with privilege to mint new tokens
	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		return nil, err
	}

	requireParameterFields := []string{token.FieldTokenHolder, token.FieldPartition}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldTokenHolder, token.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	_tokenHoler := args[token.FieldTokenHolder].(string)
	_partition := args[token.FieldPartition].(string)

	balanceOfByPartition, err := token.BalanceOfByPartition(ctx, _tokenHoler, _partition)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : BalanceOfByPartition")
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], balanceOfByPartition)
}

func (s *SmartContract) AllowanceByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	// Check minter authorization - this sample assumes Org1 is the central banker with privilege to mint new tokens
	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		return nil, err
	}

	requireParameterFields := []string{token.FieldOwner, token.FieldSpender, token.FieldPartition}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldOwner, token.FieldSpender, token.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	owner := args[token.FieldOwner].(string)
	spender := args[token.FieldSpender].(string)
	partition := args[token.FieldPartition].(string)

	allowanceByPartition, err := token.AllowanceByPartition(ctx, owner, spender, partition)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	retData, err := ccutils.StructToMap(allowanceByPartition)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : AllowanceByPartition")
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], retData)
}

func (s *SmartContract) ApproveByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	// Check minter authorization - this sample assumes Org1 is the central banker with privilege to mint new tokens
	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	id, err := ccutils.GetID(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	requireParameterFields := []string{token.FieldSpender, token.FieldPartition, token.FieldAmount}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldSpender, token.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	int64ParameterFields := []string{token.FieldAmount}
	err = ccutils.CheckRequireTypeInt64(int64ParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	owner := ccutils.GetAddress([]byte(id))
	spender := args[token.FieldSpender].(string)
	partition := args[token.FieldPartition].(string)
	amount := int64(args[token.FieldAmount].(float64))

	err = _approveByPartition(ctx, owner, spender, partition, amount)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	transferEvent := ccutils.Event{ctx.GetStub().GetTxID(), "Approval", owner, spender, partition, amount}
	err = transferEvent.EmitTransferEvent(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : ApproveByPartition")
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
}

func (s *SmartContract) IncreaseAllowanceByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	// Check minter authorization - this sample assumes Org1 is the central banker with privilege to mint new tokens
	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	id, err := ccutils.GetID(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	requireParameterFields := []string{token.FieldSpender, token.FieldPartition, token.FieldAmount}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldSpender, token.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	int64ParameterFields := []string{token.FieldAmount}
	err = ccutils.CheckRequireTypeInt64(int64ParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// args Data
	owner := ccutils.GetAddress([]byte(id))
	spender := args[token.FieldSpender].(string)
	partition := args[token.FieldPartition].(string)
	addedValue := int64(args[token.FieldAmount].(float64))

	if addedValue <= 0 { // transfer of 0 is allowed in ERC-20, so just validate against negative amounts
		return nil, fmt.Errorf("addValue cannot be negative")
	}

	allowanceByPartition, err := token.AllowanceByPartition(ctx, owner, spender, partition)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	allowance := allowanceByPartition.Amount

	err = _approveByPartition(ctx, owner, spender, partition, allowance+addedValue)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	transferEvent := ccutils.Event{ctx.GetStub().GetTxID(), "Approval", owner, spender, partition, addedValue}
	err = transferEvent.EmitTransferEvent(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : IncreaseAllowanceByPartition")
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
}

func (s *SmartContract) DecreaseAllowanceByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	// Check minter authorization - this sample assumes Org1 is the central banker with privilege to mint new tokens
	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		return nil, err
	}

	id, err := ccutils.GetID(ctx)
	if err != nil {
		logger.Errorf("failed to get client id: %v", err)
		return nil, err
	}

	requireParameterFields := []string{token.FieldSpender, token.FieldPartition, token.FieldAmount}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldSpender, token.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	int64ParameterFields := []string{token.FieldAmount}
	err = ccutils.CheckRequireTypeInt64(int64ParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// args Data
	owner := ccutils.GetAddress([]byte(id))
	spender := args[token.FieldSpender].(string)
	partition := args[token.FieldPartition].(string)
	subtractedValue := int64(args[token.FieldAmount].(float64))

	if subtractedValue <= 0 {
		// transfer of 0 is allowed in ERC-20, so just validate against negative amounts
		return nil, fmt.Errorf("subtractedValue cannot be negative")
	}

	allowanceByPartition, err := token.AllowanceByPartition(ctx, owner, spender, partition)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	allowance := allowanceByPartition.Amount
	if allowance < subtractedValue {
		return nil, fmt.Errorf("The subtraction is greater than the allowable amount. ERC20: decreased allowance below zero : %v", err)
	}

	err = _approveByPartition(ctx, owner, spender, partition, allowance-subtractedValue)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	transferEvent := ccutils.Event{ctx.GetStub().GetTxID(), "Approval", owner, spender, partition, subtractedValue}
	err = transferEvent.EmitTransferEvent(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : DecreaseAllowanceByPartition")
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
}

func _approveByPartition(ctx contractapi.TransactionContextInterface, owner string, spender string, partition string, value int64) error {

	allowanceByPartition := token.AllowanceByPartitionStruct{Owner: owner, Spender: spender, Partition: partition, Amount: value}

	err := token.ApproveByPartition(ctx, allowanceByPartition)
	if err != nil {
		return err
	}

	return nil
}

func (s *SmartContract) IssueToken(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	// Check minter authorization - this sample assumes Org1 is the central banker with privilege to mint new tokens
	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		return nil, err
	}

	// id, err := ccutils.GetID(ctx)
	// if err != nil {
	// 	logger.Errorf("failed to get client id: %v", err)
	// 	return nil, err
	// }

	// // owner Address
	// address := ccutils.GetAddress([]byte(id))

	// // Asset.Name, Asset.Partition
	// requireParameterFields := []string{token.FieldPartition}

	// // codename.FieldCode
	// err = ccutils.CheckRequireParameter(requireParameterFields, args)
	// if err != nil {
	// 	logger.Error(err)
	// 	return ccutils.GenerateErrorResponse(err)
	// }

	// stringParameterFields := []string{token.FieldPartition}
	// err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	// if err != nil {
	// 	logger.Error(err)
	// 	return ccutils.GenerateErrorResponse(err)
	// }

	// // args Data
	// // partition := args[token.FieldPartition].(string)
	tokenId := args[token.FieldTokenId].(string)
	publisher := args[token.FieldPublisher].(string)
	ror := args[token.FieldRor].(string)
	investmentPeriod := args[token.FieldInvestmentPeriod].(string)
	grade := args[token.FieldGrade].(string)
	publicOfferingAmount := int64(args[token.FieldPublicOfferingAmount].(float64))
	startDate := args[token.FieldStartDate].(string)
	endDate := args[token.FieldEndDate].(string)

	// issue Token
	newToken := token.PartitionToken{}
	newToken.TokenID = tokenId
	newToken.Publisher = publisher
	newToken.Ror = ror
	newToken.InvestmentPeriod = investmentPeriod
	newToken.Grade = grade
	newToken.PublicOfferingAmount = publicOfferingAmount
	newToken.StartDate = startDate
	newToken.EndDate = endDate
	newToken.IsLocked = false
	newToken.CreatedDate = ccutils.CreateKstTime()

	asset, err := token.IssueToken(ctx, newToken)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// 임시 admin wallet
	adminBytes, err := ledgermanager.GetState(wallet.DocType_AdminWallet, "AdminWallet", ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	adminStruct := wallet.AdminWallet{}
	err = json.Unmarshal(adminBytes, &adminStruct)
	if err != nil {
		logger.Error(err)
		return nil, err
	}
	adminStruct.PartitionTokens[tokenId] = make(map[string]token.PartitionToken)

	adminToMap, err := ccutils.StructToMap(adminStruct)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	err = ledgermanager.UpdateState(wallet.DocType_AdminWallet, "AdminWallet", adminToMap, ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	// operator
	operatorBytes, err := ledgermanager.GetState(operator.DocType_Operator, "Operator", ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	operatorsStruct := operator.OperatorsStruct{}
	err = json.Unmarshal(operatorBytes, &operatorsStruct)
	if err != nil {
		logger.Error(err)
		return nil, err
	}
	operatorsStruct.Operator[tokenId] = make(map[string]operator.OperatorStruct)

	operatorsToMap, err := ccutils.StructToMap(operatorsStruct)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	err = ledgermanager.UpdateState(operator.DocType_Operator, "Operator", operatorsToMap, ctx)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	transferEvent := ccutils.Event{ctx.GetStub().GetTxID(), "Issue", publisher, "", tokenId, 0}
	err = transferEvent.EmitTransferEvent(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	retData, err := ccutils.StructToMap(asset)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : IssueToken")
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], retData)
}

func (s *SmartContract) UndoIssueToken(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	// Check minter authorization - this sample assumes Org1 is the central banker with privilege to mint new tokens
	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		return nil, err
	}

	id, err := ccutils.GetID(ctx)
	if err != nil {
		logger.Errorf("failed to get client id: %v", err)
		return nil, err
	}

	// owner Address
	address := ccutils.GetAddress([]byte(id))

	// Asset.Name, Asset.Partition
	requireParameterFields := []string{token.FieldPartition}

	// codename.FieldCode
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	partition := args[token.FieldPartition].(string)

	tokenStruct := token.PartitionToken{Publisher: address, TokenID: partition}

	asset, err := token.UndoIssueToken(ctx, tokenStruct)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	transferEvent := ccutils.Event{ctx.GetStub().GetTxID(), "UndoIssue", address, "", partition, 0}
	err = transferEvent.EmitTransferEvent(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	retData, err := ccutils.StructToMap(asset)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : UndoIssueToken")
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], retData)
}

func (s *SmartContract) RedeemToken(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	// Check minter authorization - this sample assumes Org1 is the central banker with privilege to mint new tokens
	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		return nil, err
	}

	id, err := ccutils.GetID(ctx)
	if err != nil {
		logger.Errorf("failed to get client id: %v", err)
		return nil, err
	}

	requireParameterFields := []string{token.FieldPartition}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// args Data
	holder := ccutils.GetAddress([]byte(id))
	partition := args[token.FieldPartition].(string)

	redeemStruct := token.RedeemTokenStruct{Holder: holder, Partition: partition}

	asset, err := wallet.RedeemToken(ctx, redeemStruct)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	transferEvent := ccutils.Event{ctx.GetStub().GetTxID(), "Redeem", holder, "", partition, 0}
	err = transferEvent.EmitTransferEvent(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	retData, err := ccutils.StructToMap(asset)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : RedeemToken")
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], retData)
}

func (s *SmartContract) IsIssuable(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	// Check minter authorization - this sample assumes Org1 is the central banker with privilege to mint new tokens
	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		return nil, err
	}

	_, err = ccutils.GetID(ctx)
	if err != nil {
		logger.Errorf("failed to get client id: %v", err)
		return nil, err
	}

	requireParameterFields := []string{token.FieldPartition}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// args Data
	partition := args[token.FieldPartition].(string)

	err = token.IsIssuable(ctx, partition)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	transferEvent := ccutils.Event{ctx.GetStub().GetTxID(), "IsIssuable", "", "", partition, 0}
	err = transferEvent.EmitTransferEvent(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	retData, err := ccutils.StructToMap("true")
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : IsIssuable")
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], retData)
}

func (s *SmartContract) GetTokenList(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	err := ccutils.GetMSPID(ctx)
	if err != nil {
		logger.Errorf("failed to get client msp id: %v", err)
		return nil, err
	}

	_, err = ccutils.GetID(ctx)
	if err != nil {
		logger.Errorf("failed to get client id: %v", err)
		return nil, err
	}

	requireParameterFields := []string{ledgermanager.PageSize, ledgermanager.Bookmark}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{ledgermanager.Bookmark}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	int64ParameterFields := []string{ledgermanager.PageSize}
	err = ccutils.CheckTypeInt64(int64ParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	dateParameterFields := []string{ledgermanager.StartDate, ledgermanager.EndDate}
	err = ccutils.CheckFormatDate(dateParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	pageSize := int32(args[ledgermanager.PageSize].(float64))
	bookmark := args[ledgermanager.Bookmark].(string)

	var bytes []byte
	bytes, err = token.GetTokenList(args, pageSize, bookmark, ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : GetTokenList")
	return ccutils.GenerateSuccessResponseByteArray(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], bytes)
}

func (s *SmartContract) GetTokenHolderList(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

	requireParameterFields := []string{ledgermanager.PageSize, ledgermanager.Bookmark, ledgermanager.Partition}
	err := ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{ledgermanager.Bookmark, ledgermanager.Partition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	int64ParameterFields := []string{ledgermanager.PageSize}
	err = ccutils.CheckTypeInt64(int64ParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	dateParameterFields := []string{ledgermanager.StartDate, ledgermanager.EndDate}
	err = ccutils.CheckFormatDate(dateParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	pageSize := int32(args[ledgermanager.PageSize].(float64))
	bookmark := args[ledgermanager.Bookmark].(string)
	partition := args[ledgermanager.Partition].(string)

	var bytes []byte
	bytes, err = token.GetTokenHolderList(args, partition, pageSize, bookmark, ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : GetTokenHolderList")
	return ccutils.GenerateSuccessResponseByteArray(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], bytes)
}
