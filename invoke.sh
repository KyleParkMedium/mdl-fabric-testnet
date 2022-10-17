#!/bin/bash

LOG_LEVEL=info
export CALIPER_SCRIPT=${PWD}
export CALIPER_HOME=${CALIPER_SCRIPT%/*}
export CALIPER_BENCHMARKS=$CALIPER_HOME/benchmarks


############ Set core.yaml ############
PEERID="peer0"
export TEST_NETWORK_HOME=$(dirname $(readlink -f $0))
export FABRIC_CFG_PATH=${TEST_NETWORK_HOME}/config


############ Peer Vasic Setting ############
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_ID="$PEERID.org1.example.com"
export CORE_PEER_ENDORSER_ENABLED=true
export CORE_PEER_ADDRESS="$PEERID.org1.example.com:7050"
export CORE_PEER_LOCALMSPID="Org1MSP"

export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp"
export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"

############ Start Peer ############
echo "MspPath : $CORE_PEER_MSPCONFIGPATH"

echo "chaincode invoke"
export PEERPATH="${TEST_NETWORK_HOME}"

## Invoke
export BIN_DIR="${TEST_NETWORK_HOME}/bin"
${BIN_DIR}/peer chaincode invoke -o orderer.example.com:9050 --tls --cafile ${ORDERER_CA} -C mychannel0 -c '{"Args":["open","aabb","1122"]}'

## Query
#$PEERPATH/bin/peer chaincode query -o orderer0.example.com:7050 -C mychannel0 -n simple -c '{"Args":["query","aacc"]}'
