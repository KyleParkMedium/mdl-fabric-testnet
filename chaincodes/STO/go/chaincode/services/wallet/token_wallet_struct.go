package wallet

import (
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/token"
)

const (
	DocType_TokenWallet = "DOCTYPE_TOKEN_WALLET"
	DocType_AdminWallet = "DOCTYPE_ADMIN_WALLET"
)

type AdminWallet struct {
	DocType string `json:"docType"`

	AdminName string `json:"adminName"`

	PartitionTokens map[string]map[string]token.PartitionToken `json:"partitionTokens"`

	CreatedDate string `json:"createdDate"`
	UpdatedDate string `json:"updatedDate"`
}

// 원장 지갑
type TokenWallet struct {
	DocType string `json:"docType"`

	// email
	TokenWalletId string `json:"tokenWalletId"`
	// 개인(personal), 법인(corporate)
	Role string `json:"role"`
	// 계좌번호
	AccountNumber string `json:"accountNumber"`

	// bool
	IsLocked bool `json:"isLocked"`

	CreatedDate string `json:"createdDate"`
	UpdatedDate string `json:"updatedDate"`
	ExpiredDate string `json:"expiredDate"`

	PartitionTokens map[string][]token.PartitionToken `json:"partitionTokens"`
}
