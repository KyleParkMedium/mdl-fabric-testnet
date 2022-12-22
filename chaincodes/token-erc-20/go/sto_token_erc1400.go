/*
SPDX-License-Identifier: Apache-2.0
*/

package main

import (
	"log"

	"github.com/KyleParkMedium/mdl-chaincode/chaincode"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SmartContract struct {
	chaincode.SmartContract
}

func main() {

	tokenChaincode, err := contractapi.NewChaincode(&SmartContract{})

	if err != nil {
		log.Panicf("Error creating sto_token_erc1400 chaincode: %v", err)
	}

	if err := tokenChaincode.Start(); err != nil {
		log.Panicf("Error starting sto_token_erc1400 chaincode: %v", err)
	}
}
