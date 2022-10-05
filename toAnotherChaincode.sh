#!/bin/bash
CHANNEL_NAME="$1"
: ${CHANNEL_NAME:="mychannel0"}
DELAY="$2"
: ${DELAY:="3"}
MAX_RETRY="$3"
: ${MAX_RETRY:="5"}
VERBOSE="$4"
: ${VERBOSE:="false"}
CHAINCODE_NAME="$5"
: ${CHAINCODE_NAME:="token-erc-20"}
CHAINCODE_VERSION="$6"
: ${CHAINCODE_VERSION:="v1"}
CHAINCODE_SEQUENCE="$7"
: ${CHAINCODE_SEQUENCE:="1"}
CHAINCODE_INIT_REQUIRED=""
CHAINCODE_END_POLICY="$8"
: ${CHAINCODE_END_POLICY:=""}
CHAINCODE_COLL_CONFIG="$9"
: ${CHAINCODE_COLL_CONFIG:=""}

export TEST_NETWORK_HOME=$(dirname $(readlink -f $0))
export BIN_DIR="${TEST_NETWORK_HOME}/bin"
export LOG_DIR="${TEST_NETWORK_HOME}/log"
export FABRIC_CFG_PATH=${TEST_NETWORK_HOME}/config
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
export CORE_PEER_ADDRESS="localhost:7051"
PEER_CONN_PARMS="${PEER_CONN_PARMS} --peerAddresses ${CORE_PEER_ADDRESS}"
TLSINFO=$(eval echo "--tlsRootCertFiles \$CORE_PEER_TLS_ROOTCERT_FILE")
PEER_CONN_PARMS="${PEER_CONN_PARMS} ${TLSINFO}"
function minter() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    CHANNEL_NAME=$1
    CHAINCODE_NAME=$2
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="Minter"
    CC_ARGS="\"10000\""
    set -x
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS} -c ${fcn_call} --isInit >&${LOG_DIR}/minter.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/minter.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function invokeAnotherChaincode() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp"
    CHANNEL_NAME="mychannel0"
    CHAINCODE_NAME="token-erc-20"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="InvokeAnotherChaincode"
    CC_ARGS="\"Client\",\"\""
    set -x
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS} -c ${fcn_call} >&${LOG_DIR}/invokeAnotherChaincode.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/invokeAnotherChaincode.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function main() {
    # minter "mychannel0" "token-erc-20"
    # sleep 3
    # minter "mychannel1" "coin-erc-20"
    # sleep 3
    invokeAnotherChaincode
}

function verifyResult() {
    if [ $1 -ne 0 ]; then
        echo -e "$2"
        exit 1
    fi
}

main



