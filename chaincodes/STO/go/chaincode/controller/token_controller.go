package controller

import (
	"encoding/json"
	"fmt"
	"math/big"

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

	logger.Infof("Success function : TotalSupply : %v tokens", totalSupply.TotalSupply)
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

	// args
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

	logger.Infof("Success function : TotalSupplyByPartition \n token : %v, amount : %v", totalSupplyByPartition.Partition, totalSupplyByPartition.TotalSupply)
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

	// args
	_tokenHoler := args[token.FieldTokenHolder].(string)
	_partition := args[token.FieldPartition].(string)

	balanceOfByPartition, err := token.BalanceOfByPartition(ctx, _tokenHoler, _partition)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : BalanceOfByPartition \n holder : %v, token : %v, amount : %v", _tokenHoler, _partition, balanceOfByPartition)
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

	// args
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

	logger.Infof("Success function : AllowanceByPartition \n owner : %v, spender : %v, token : %v, amount : %v", owner, spender, partition, allowanceByPartition.Amount)
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

	_, err = ccutils.GetID(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	requireParameterFields := []string{token.FieldOwner, token.FieldSpender, token.FieldPartition, token.FieldAmount}
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

	int64ParameterFields := []string{token.FieldAmount}
	err = ccutils.CheckRequireTypeInt64(int64ParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// args
	// owner := ccutils.GetAddress([]byte(id))
	owner := args[token.FieldOwner].(string)
	spender := args[token.FieldSpender].(string)
	partition := args[token.FieldPartition].(string)
	amount := int64(args[token.FieldAmount].(float64))

	err = _approveByPartition(ctx, owner, spender, partition, amount)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	approveEvent := ccutils.ApprovalEvent{ctx.GetStub().GetTxID(), "Approval", owner, spender, partition, amount, big.NewInt(amount)}
	err = approveEvent.EmitApprovalEvent(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : ApproveByPartition \n owner : %v, spender : %v, token : %v, amount : %v", owner, spender, partition, amount)
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

	_, err = ccutils.GetID(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	requireParameterFields := []string{token.FieldOwner, token.FieldSpender, token.FieldPartition, token.FieldAmount}
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

	int64ParameterFields := []string{token.FieldAmount}
	err = ccutils.CheckRequireTypeInt64(int64ParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// args
	// owner := ccutils.GetAddress([]byte(id))
	owner := args[token.FieldOwner].(string)
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

	allowanceByPartition.AddAmount(addedValue)

	imsy := allowanceByPartition.AmountBig
	imsy.Add(imsy, big.NewInt(addedValue))
	allowanceByPartition.AmountBig = imsy

	err = token.ApproveByPartition(ctx, *allowanceByPartition)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	approvalEvent := ccutils.ApprovalEvent{ctx.GetStub().GetTxID(), "Approval", owner, spender, partition, addedValue, big.NewInt(addedValue)}
	err = approvalEvent.EmitApprovalEvent(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : IncreaseAllowanceByPartition \n owner : %v, spender : %v, token : %v, amount : %v", owner, spender, partition, addedValue)
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
}

func (s *SmartContract) DecreaseAllowanceByPartition(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

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

	requireParameterFields := []string{token.FieldOwner, token.FieldSpender, token.FieldPartition, token.FieldAmount}
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

	int64ParameterFields := []string{token.FieldAmount}
	err = ccutils.CheckRequireTypeInt64(int64ParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// args
	// owner := ccutils.GetAddress([]byte(id))
	owner := args[token.FieldOwner].(string)
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

	allowanceByPartition.SubAmount(subtractedValue)

	imsy := allowanceByPartition.AmountBig
	imsy.Sub(imsy, big.NewInt(subtractedValue))
	allowanceByPartition.AmountBig = imsy

	err = token.ApproveByPartition(ctx, *allowanceByPartition)
	if err != nil {
		logger.Error(err)
		return nil, err
	}

	approvalEvent := ccutils.ApprovalEvent{ctx.GetStub().GetTxID(), "Approval", owner, spender, partition, subtractedValue, big.NewInt(subtractedValue)}
	err = approvalEvent.EmitApprovalEvent(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : DecreaseAllowanceByPartition \n owner : %v, spender : %v, token : %v, amount : %v", owner, spender, partition, subtractedValue)
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], nil)
}

func _approveByPartition(ctx contractapi.TransactionContextInterface, owner string, spender string, partition string, value int64) error {

	allowanceByPartition := token.AllowanceByPartitionStruct{DocType: token.DocType_Allowance, Owner: owner, Spender: spender, Partition: partition, Amount: value, AmountBig: big.NewInt(value)}

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

	_, err = ccutils.GetID(ctx)
	if err != nil {
		logger.Errorf("failed to get client id: %v", err)
		return nil, err
	}

	requireParameterFields := []string{token.FieldTokenId, token.FieldPublisher, token.FieldRor, token.FieldInvestmentPeriod, token.FieldGrade, token.FieldPublicOfferingAmount, token.FieldStartDate, token.FieldEndDate}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldTokenId, token.FieldPublisher, token.FieldRor, token.FieldInvestmentPeriod, token.FieldGrade, token.FieldStartDate, token.FieldEndDate}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	int64ParameterFields := []string{token.FieldPublicOfferingAmount}
	err = ccutils.CheckTypeInt64(int64ParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// args
	// partition := args[token.FieldPartition].(string)
	tokenId := args[token.FieldTokenId].(string)
	publisher := args[token.FieldPublisher].(string)
	publisherUuid := args[token.FieldPublisherUuid].(string)
	ror := args[token.FieldRor].(string)
	investmentPeriod := args[token.FieldInvestmentPeriod].(string)
	grade := args[token.FieldGrade].(string)
	publicOfferingAmount := int64(args[token.FieldPublicOfferingAmount].(float64))
	startDate := args[token.FieldStartDate].(string)
	endDate := args[token.FieldEndDate].(string)

	// issue Token
	newToken := token.PartitionToken{}
	newToken.DocType = token.DocType_Token
	newToken.TokenID = tokenId
	newToken.Publisher = publisher
	newToken.PublisherUuid = publisherUuid
	newToken.Ror = ror
	newToken.InvestmentPeriod = investmentPeriod
	newToken.Grade = grade
	newToken.AmountBig = big.NewInt(0)
	newToken.PublicOfferingAmount = publicOfferingAmount
	newToken.PublicOfferingAmountBig = big.NewInt(publicOfferingAmount)
	newToken.NumberOfTokens = publicOfferingAmount / 5000
	newToken.NumberOfTokensBig = big.NewInt(publicOfferingAmount / 5000)
	newToken.StartDate = startDate
	newToken.EndDate = endDate
	newToken.IsLocked = false
	newToken.CreatedDate = ccutils.CreateKstTimeAndSecond()
	newToken.UpdatedDate = newToken.CreatedDate

	// check publisher role
	walletBytes, err := ledgermanager.GetState(wallet.DocType_TokenWallet, publisherUuid, ctx)
	if err != nil {
		return nil, err
	}

	walletData := wallet.TokenWallet{}
	err = json.Unmarshal(walletBytes, &walletData)
	if err != nil {
		return nil, err
	}

	if walletData.Role != "ipo" {
		return nil, fmt.Errorf("publisher's role is not ipo")
	}

	asset, err := token.IssueToken(ctx, newToken)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// get admin wallet
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

	// get operators
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

	issueEvent := ccutils.IssueEvent{ctx.GetStub().GetTxID(), "Issue", publisher, tokenId, 0, big.NewInt(0)}
	err = issueEvent.EmitIssueEvent(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	retData, err := ccutils.StructToMap(asset)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : IssueToken \n token : %v", tokenId)
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], retData)
}

func (s *SmartContract) UndoIssueToken(ctx contractapi.TransactionContextInterface, args map[string]interface{}) (*ccutils.Response, error) {

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

	requireParameterFields := []string{token.FieldCaller, token.FieldPartition}
	err = ccutils.CheckRequireParameter(requireParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	stringParameterFields := []string{token.FieldCaller, token.FieldPartition}
	err = ccutils.CheckRequireTypeString(stringParameterFields, args)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	// args
	address := args[token.FieldCaller].(string)
	partition := args[token.FieldPartition].(string)

	tokenStruct := token.PartitionToken{Publisher: address, TokenID: partition}

	asset, err := token.UndoIssueToken(ctx, tokenStruct)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	issueEvent := ccutils.IssueEvent{ctx.GetStub().GetTxID(), "UndoIssue", "Locked", partition, 0, big.NewInt(0)}
	err = issueEvent.EmitIssueEvent(ctx)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	retData, err := ccutils.StructToMap(asset)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : UndoIssueToken \n token : %v", partition)
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

	// args
	partition := args[token.FieldPartition].(string)

	err = token.IsIssuable(ctx, partition)
	if err != nil {
		logger.Error(err)
		return ccutils.GenerateErrorResponse(err)
	}

	logger.Infof("Success function : IsIssuable \n Issuable : true")
	return ccutils.GenerateSuccessResponse(ctx.GetStub().GetTxID(), ccutils.ChaincodeSuccess, ccutils.CodeMessage[ccutils.ChaincodeSuccess], "true")
}
