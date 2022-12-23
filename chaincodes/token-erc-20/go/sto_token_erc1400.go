/*
SPDX-License-Identifier: Apache-2.0
*/

package main

import (
	"log"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"

	"github.com/the-medium-tech/mdl-chaincodes/chaincode"
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
