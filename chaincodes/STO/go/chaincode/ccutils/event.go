package ccutils

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type ApprovalEvent struct {
	TxId      string `json:"txId"`
	Type      string `json:"type"`
	Owner     string `json:"owner"`
	Spender   string `json:"spender"`
	Partition string `json:"partition"`
	Amount    int64  `json:"amount"`
}

func (e *ApprovalEvent) EmitApprovalEvent(ctx contractapi.TransactionContextInterface) error {

	approvalEventJSON, err := json.Marshal(e)
	if err != nil {
		return fmt.Errorf("failed to obtain JSON encoding: %v", err)
	}

	err = ctx.GetStub().SetEvent(e.Type, approvalEventJSON)
	if err != nil {
		return fmt.Errorf("failed to set event: %v", err)
	}

	return nil
}

type IssueEvent struct {
	TxId      string `json:"txId"`
	Type      string `json:"type"`
	Publisher string `json:"publisher"`
	Partition string `json:"partition"`
	Amount    int64  `json:"amount"`
}

func (e *IssueEvent) EmitIssueEvent(ctx contractapi.TransactionContextInterface) error {

	issueEventJSON, err := json.Marshal(e)
	if err != nil {
		return fmt.Errorf("failed to obtain JSON encoding: %v", err)
	}

	err = ctx.GetStub().SetEvent(e.Type, issueEventJSON)
	if err != nil {
		return fmt.Errorf("failed to set event: %v", err)
	}

	return nil
}

type TransferEvent struct {
	TxId      string `json:"txId"`
	Type      string `json:"type"`
	From      string `json:"from"`
	To        string `json:"to"`
	Partition string `json:"partition"`
	Amount    int64  `json:"amount"`
}

func (e *TransferEvent) EmitTransferEvent(ctx contractapi.TransactionContextInterface) error {

	transferEventJSON, err := json.Marshal(e)
	if err != nil {
		return fmt.Errorf("failed to obtain JSON encoding: %v", err)
	}

	err = ctx.GetStub().SetEvent(e.Type, transferEventJSON)
	if err != nil {
		return fmt.Errorf("failed to set event: %v", err)
	}

	return nil
}
