package ccutils

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type Event struct {
	TxId      string `json:"txId"`
	Type      string `json:"type"`
	From      string `json:"from"`
	To        string `json:"to"`
	Partition string `json:"partition"`
	Amount    int64  `json:"amount"`
}

func (e *Event) EmitTransferEvent(ctx contractapi.TransactionContextInterface) error {

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
