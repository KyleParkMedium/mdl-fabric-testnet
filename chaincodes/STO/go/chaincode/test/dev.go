package test

const (
	// Define key names for options
	totalSupplyKey = "totalSupply"
	tokenName      = "mdl"

	// Define objectType names by partition for prefix
	totalSupplyByPartitionPrefix = "totalSupplyByPartition"

	// _allowances
	allowanceByPartitionPrefix = "allowanceByPartition"

	// issue or mint partition token
	mintingByPartitionPrefix         = "mintingByPartition"
	clientBalanceOfByPartitionPrefix = "clientWallet"

	operatorForPartitionPrefix = "operatorForPartition"
)

// Represents a fungible set of tokens.
type TotalSupplyByPartition struct {
	TotalSupply int
	// Partition Address
	Partition string
}

// Represents a fungible set of tokens.

// token
type Token struct {
	Name   string `json:"name"`
	ID     string `json:"id"`
	Amount int    `json:"amount"`
	Locked bool   `json:"locked"`
}

// address or wallet
type Wallet struct {
	DocType string `json:"docType"`
	Name    string `json:"name"`

	AuthWalletId string `json:"authWalletId"`
	CreatedDate  string `json:"createdDate"`
	UpdatedDate  string `json:"updatedDate"`
	ExpiredDate  string `json:"expiredDate"`

	AA map[string]struct{}

	BB []PartitionToken

	CC interface{}

	// 배열로..?
	PartitionToken Partition
}

type Partition struct {
	Amount int
	// Partition Address
	Partition string
}

// partition Token
type PartitionToken struct {
	DocType string `json:"docType"`

	Name   string `json:"name"`
	ID     string `json:"id"`
	Locked bool   `json:"locked"`

	Publisher string `json:"publisher"`

	ExpiredDate string `json:"expiredDate"`
	CreatedDate string `json:"createdDate"`
	UpdatedDate string `json:"updatedDate"`

	TxId string `json:"txId"`

	// 요기가 fix 될 예정
	Partition Partition `json:"partition"`
}
