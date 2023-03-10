package test

import (
	crand "crypto/rand"
	"math"
	"math/big"
	"math/rand"

	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/distribute"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/services/token"
)

type Mock struct {
	TokenId              string           `json:"tokenId"`
	PublicOfferingAmount int64            `json:"publicOfferingAmount"`
	Recipients           map[string]int64 `json:"recipients"`
}

func CreateRecipient() distribute.AirDropStruct {

	mock := distribute.AirDropStruct{}
	mock.Caller = "kyle"
	// mock.PartitionToken = "mediumToken"
	mock.Recipient = "tom@medium.com"

	return mock
}

type AirDropStruct struct {
	// 혹은 operator
	Caller         string               `json:"caller"`
	PartitionToken token.PartitionToken `json:"partitionToken"`
	Recipient      string               `json:"recipient"`
}

func CreateMock() Mock {

	mock := Mock{}
	mock.TokenId = "mediumToken"
	mock.PublicOfferingAmount = 100000
	mock.Recipients = make(map[string]int64)

	for i := 0; i < 10000; i++ {
		a := GenerateUniqueID(64)
		mock.Recipients[a] = int64(i * 100)
	}

	return mock
}

/*
*
crypto/rand string을 이용해 유니크한 ID 생성
*/
const letterBytes = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"

func GenerateUniqueID(length int) string {
	seed, _ := crand.Int(crand.Reader, big.NewInt(math.MaxInt64))
	rand.Seed(seed.Int64())

	b := make([]byte, length)
	for i := range b {
		b[i] = letterBytes[rand.Intn(len(letterBytes))]
	}

	return string(b)
}
