package airdrop

import "github.com/KyleParkMedium/mdl-chaincode/chaincode/services/token"

type AirDropStruct struct {
	DocType string `json:"docType"`

	// 혹은 operator
	Caller         string               `json:"caller"`
	PartitionToken token.PartitionToken `json:"partitionToken"`
	Recipient      string               `json:"recipient"`
}

// 에어드롭 시에 두가지 방안을
type Recipients struct {
	DocType        string `json:"docType"`
	PartitionToken string `json:"partitionToken"`

	// PartitionToken token.PartitionToken

	// recipient의 변동을 생각해 이도 map으로 짜는게 낫긴 함.
	Recipients []string `json:"recipients"`
}

// // 드롭받을 사람 배열
// Array []token.MintByPartitionStruct
