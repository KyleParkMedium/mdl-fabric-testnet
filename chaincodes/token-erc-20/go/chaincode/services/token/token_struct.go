package token

const (
	DocType_Token                  = "DOCTYPE_TOKEN"
	DocType_TotalSupply            = "DOCTYPE_TOTALSUPPLY"
	DocType_TotalSupplyByPartition = "DOCTYPE_TOTALSUPPLYBYPARTITION"
	DocType_Allowance              = "DOCTYPE_ALLOWANCE"
	DocType_Test                   = "DOCTYPE_TEST"
	DocType_TokenHolderList        = "DOCTYPE_TOKENHOLDERLIST"

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

// 분배 받을 사람 배열
type TokenHolderList struct {
	DocType string `json:"docType"`

	IsLocked bool `json:"isLocked`

	PartitionToken string `json:"partitionToken"`
	// recipient의 변동을 생각해 이도 map으로 짜는게 낫긴 함.
	Recipients map[string]PartitionToken `json:"recipients"`
}

// 토큰 상환
type RedeemTokenStruct struct {
	DocType string `json:"docType"`

	Holder    string `json:"holder"`
	Partition string `json:"partition"`
}
