package token

const (
	DocType_Token                  = "DOCTYPE_TOKEN"
	DocType_TotalSupply            = "DOCTYPE_TOTALSUPPLY"
	DocType_TotalSupplyByPartition = "DOCTYPE_TOTALSUPPLYBYPARTITION"
	DocType_Allowance              = "DOCTYPE_ALLOWANCE"
	DocType_Test                   = "DOCTYPE_TEST"

	// Prefix
	BalanceOfByPartitionPrefix = "balancePrefix"
	allowanceByPartitionPrefix = "allowanceByPartition"
)

// totalSupply
type TotalSupplyStruct struct {
	DocType string `json:"docType"`

	TotalSupply int64 `json:"totalSupply"`
}

type TotalSupplyByPartitionStruct struct {
	DocType string `json:"docType"`

	TotalSupply int64 `json:"totalSupply"`
	// Partition Address
	Partition string `json:"partition"`
}

type AllowanceByPartitionStruct struct {
	DocType string `json:"docType"`

	Owner     string `json:"owner"`
	Spender   string `json:"spender"`
	Partition string `json:"partition"`
	Amount    int64  `json:"amount"`
}

type TransferByPartitionStruct struct {
	DocType string `json:"docType"`

	From      string `json:"from"`
	To        string `json:"to"`
	Partition string `json:"partition"`
	Amount    int64  `json:"amount"`
}

type MintByPartitionStruct struct {
	DocType string `json:"docType"`

	Minter    string `json:"minter"`
	Partition string `json:"partition"`
	Amount    int64  `json:"amount"`
}

// partition Token
type PartitionToken struct {
	DocType string `json:"docType"`

	TokenName string `json:"name"`
	TokenID   string `json:"id"`
	IsLocked  bool   `json:"islocked"`
	TxId      string `json:"txId"`

	Publisher string `json:"publisher"`

	CreatedDate string `json:"createdDate"`
	UpdatedDate string `json:"updatedDate"`
	ExpiredDate string `json:"expiredDate"`

	Amount int64 `json:"amount"`
}
