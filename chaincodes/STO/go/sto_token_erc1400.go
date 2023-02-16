/*
SPDX-License-Identifier: Apache-2.0
*/

package main

import (
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils/flogging"
)

type SmartContract struct {
	chaincode.SmartContract
}

var logger = flogging.MustGetLogger("main")

func main() {
	tokenChaincode, err := contractapi.NewChaincode(&SmartContract{})

	if err != nil {
		logger.Panicf("Error creating sto_token_erc1400 chaincode: %v", err)
	}

	if err := tokenChaincode.Start(); err != nil {
		logger.Panicf("Error starting sto_token_erc1400 chaincode: %v", err)
	}
}
