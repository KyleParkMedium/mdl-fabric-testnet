package token

import (
	"fmt"
	"math/big"

	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils"
)

const (
	DocType_Token                  = "DOCTYPE_TOKEN"
	DocType_TotalSupply            = "DOCTYPE_TOTALSUPPLY"
	DocType_TotalSupplyByPartition = "DOCTYPE_TOTALSUPPLYBYPARTITION"
	DocType_Allowance              = "DOCTYPE_ALLOWANCE"
	DocType_Test                   = "DOCTYPE_TEST"
	DocType_TokenHolderList        = "DOCTYPE_TOKENHOLDERLIST"

	// Prefix
	BalanceOfByPartitionPrefix = "balanceOfByPartition"
	allowanceByPartitionPrefix = "allowanceByPartition"
)

// totalSupply
type TotalSupplyStruct struct {
	DocType string `json:"docType"`

	TotalSupply    int64    `json:"totalSupply"`
	ToTalSupplyBig *big.Int `json:"totalSupplyBig"`

	CreatedDate string `json:"createdDate"`
	UpdatedDate string `json:"updatedDate"`
}

type TotalSupplyByPartitionStruct struct {
	DocType string `json:"docType"`

	TotalSupply    int64    `json:"totalSupply"`
	ToTalSupplyBig *big.Int `json:"totalSupplyBig"`
	// Partition Address
	Partition string `json:"partition"`

	CreatedDate string `json:"createdDate"`
	UpdatedDate string `json:"updatedDate"`
}

type AllowanceByPartitionStruct struct {
	DocType string `json:"docType"`

	Owner     string   `json:"owner"`
	Spender   string   `json:"spender"`
	Partition string   `json:"partition"`
	Amount    int64    `json:"amount"`
	AmountBig *big.Int `json:"amountBig"`

	CreatedDate string `json:"createdDate"`
	UpdatedDate string `json:"updatedDate"`
}

type TransferByPartitionStruct struct {
	From      string   `json:"from"`
	To        string   `json:"to"`
	Partition string   `json:"partition"`
	Amount    int64    `json:"amount"`
	AmountBig *big.Int `json:"amountBig"`
}

type MintByPartitionStruct struct {
	Minter    string   `json:"minter"`
	Partition string   `json:"partition"`
	Amount    int64    `json:"amount"`
	AmountBig *big.Int `json:"amountBig"`
}

// partition Token (상품 정보)
type PartitionToken struct {
	DocType string `json:"docType"`

	// 상품(토큰) ID
	TokenID string `json:"tokenId"`
	// 상품(토큰) 발행인
	Publisher     string `json:"publisher"`
	PublisherUuid string `json:"publisherUuid"`
	// 소지인
	TokenHolderID string `json:"tokenHolder"`
	// 소유량
	Amount    int64    `json:"amount"`
	AmountBig *big.Int `json:"amountBig"`
	// 연수익률(Rate or return)
	Ror string `json:"ror"`
	// 투자기간
	InvestmentPeriod string `json:"investmentPeriod"`
	// 상품등급
	Grade string `json:"grade"`
	// 모집금액(공모금액)
	PublicOfferingAmount    int64    `json:"publicOfferingAmount"`
	PublicOfferingAmountBig *big.Int `json:"publicOfferingAmountBig"`
	// 모집 완료 토큰 개수
	NumberOfTokens    int64    `json:"numberOfTokens"`
	NumberOfTokensBig *big.Int `json:"numberOfTokensBig"`
	// 모집시작일
	StartDate string `json:"startDate"`
	// 모집종료일
	EndDate string `json:"endDate"`
	// 토큰 잠김
	IsLocked bool `json:"isLocked"`

	CreatedDate string `json:"createdDate"`
	UpdatedDate string `json:"updatedDate"`
	ExpiredDate string `json:"expiredDate"`
}

// 토큰 홀더 리스트
type TokenHolderList struct {
	DocType string `json:"docType"`

	TokenId   string         `json:"tokenId"`
	TokenInfo PartitionToken `json:"tokenInfo"`

	// bool
	IsLocked      bool `json:"isLocked`
	IsDistributed bool `json:"isDistributed"`
	IsRedeemed    bool `json:"isRedeemed"`

	Recipients map[string]Recipient `json:"recipients"`

	CreatedDate string `json:"createdDate"`
	UpdatedDate string `json:"updatedDate"`
}

type Recipient struct {
	TokenWalletId string   `json:"tokenWalletId"`
	TokenId       string   `json:"tokenId"`
	Amount        int64    `json:"amount"`
	AmountBig     *big.Int `json:"amountBig"`
}

// 토큰 상환
type RedeemTokenStruct struct {
	DocType string `json:"docType"`

	Holder    string `json:"holder"`
	Partition string `json:"partition"`
}

func (t *TotalSupplyStruct) AddAmount(amount int64) error {
	t.TotalSupply += amount
	return nil
}

func (t *TotalSupplyStruct) SubAmount(amount int64) error {
	t.TotalSupply -= amount
	return nil
}

func (t *TotalSupplyByPartitionStruct) AddAmount(amount int64) error {
	t.TotalSupply += amount
	return nil
}

func (t *TotalSupplyByPartitionStruct) SubAmount(amount int64) error {
	t.TotalSupply -= amount
	return nil
}

func (a *AllowanceByPartitionStruct) AddAmount(amount int64) error {
	a.Amount += amount
	return nil
}

func (a *AllowanceByPartitionStruct) SubAmount(amount int64) error {
	// if t.PartitionTokens[partition][0].Amount < amount {
	// 	return ccutils.CreateError(ccutils.ChaincodeError, fmt.Errorf("not enough balance"))
	// }
	a.Amount -= amount
	return nil
}

func (p *PartitionToken) AddAmount(amount int64) error {
	p.Amount += amount
	return nil
}

func (p *PartitionToken) SubAmount(amount int64) error {
	if p.Amount < amount {
		return ccutils.CreateError(ccutils.ChaincodeError, fmt.Errorf("currentBalance is lower than input amount"))
	}
	p.Amount -= amount
	return nil
}
