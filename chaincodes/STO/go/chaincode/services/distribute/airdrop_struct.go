package distribute

import "github.com/the-medium-tech/mdl-chaincodes/chaincode/services/token"

type AirDropStruct struct {
	// 혹은 operator
	Caller         string               `json:"caller"`
	PartitionToken token.PartitionToken `json:"partitionToken"`
	Recipient      string               `json:"recipient"`
}
