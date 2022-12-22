package wallet

import "github.com/KyleParkMedium/mdl-chaincode/chaincode/services/token"

const (
	DocType_TokenWallet = "DOCTYPE_TOKEN_WALLET"
)

type TokenWallet struct {
	DocType string `json:"docType"`

	TokenWalletId string `json:"tokenWalletId"`
	TxId          string `json:"txId"`

	// Balance           int64 `json:"balance"`
	// AuthWalletId string `json:"authWalletId"`

	CreatedDate string `json:"createdDate"`
	UpdatedDate string `json:"updatedDate"`
	ExpiredDate string `json:"expiredDate"`

	// AA map[string]struct{}
	// BB []PartitionToken
	// CC interface{}
	// // 배열로..?
	// PartitionToken Partition

	// PartitionTokens map[string][]interface{}
	PartitionTokens map[string][]token.PartitionToken `json:"partitionTokens"`
}

// 리시버 훅은 한번 만들어볼지 고민 중
// func (t *TokenWallet) SubBalance(amount int64) error {
// 	if t.Balance < amount {
// 		return ccutils.CreateError(ccutils.ChaincodeError, fmt.Errorf("not enough balance"))
// 	}

// 	t.Balance -= amount

// 	return nil
// }

// func (t *TokenWallet) SubPayback(amount int64) error {
// 	if t.Payback < amount {
// 		return ccutils.CreateError(ccutils.ChaincodeError, fmt.Errorf("not enough payback"))
// 	}

// 	t.Payback -= amount

// 	return nil
// }

// func (t *TokenWallet) SubOutPendingBalance(amount int64) error {
// 	if t.OutPendingBalance < amount {
// 		return ccutils.CreateError(ccutils.ChaincodeError, fmt.Errorf("not enough OutPnedingBalance"))
// 	}

// 	t.OutPendingBalance -= amount

// 	return nil
// }

// func (t *TokenWallet) SubPurchasePayback(amount int64) error {
// 	if t.PurchasePayback < amount {
// 		return ccutils.CreateError(ccutils.ChaincodeError, fmt.Errorf("not enough purchasePayback"))
// 	}

// 	t.PurchasePayback -= amount

// 	return nil
// }

// func (t *TokenWallet) SubBalanceInsteadOfPayback(amount int64) error {
// 	if t.Balance < amount {
// 		return ccutils.CreateError(ccutils.ChaincodeError, fmt.Errorf("not enough balance instead of payback"))
// 	}

// 	t.Balance -= amount

// 	return nil
// }
