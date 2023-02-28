/*
SPDX-License-Identifier: Apache-2.0
*/

package main

import (
	"log"

	"key/chaincode"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func main() {

	instanceChaincode, err := contractapi.NewChaincode(&chaincode.SmartContract{})
	if err != nil {
		log.Panicf("Error creating token-erc-20 chaincode: %v", err)
	}

	if err := instanceChaincode.Start(); err != nil {
		log.Panicf("Error starting token-erc-20 chaincode: %v", err)
	}
}
