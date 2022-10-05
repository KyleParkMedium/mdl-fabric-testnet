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
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="Minter"
    CC_ARGS="\"10000\""
    set -x
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c ${fcn_call} --isInit >&${LOG_DIR}/minter.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/minter.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function mint() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="Mint"
    CC_ARGS="\"10000\""
    set -x
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c ${fcn_call} >&${LOG_DIR}/mint.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/mint.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function burn() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="Burn"
    CC_ARGS="\"50\""
    set -x
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c ${fcn_call} >&${LOG_DIR}/burn.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/burn.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function client() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/$1@org1.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="Client"
    CC_ARGS="\"\""
    set -x
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c ${fcn_call} >&${LOG_DIR}/client_$1.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/client_$1.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function clientAccountID() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/$1@org1.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="ClientAccountID"
    CC_ARGS="\"\""
    set -x
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c ${fcn_call} >&${LOG_DIR}/$1_id.log
    { set +x; } 2>/dev/null
    export $1_ADDRESS=$(cat ${LOG_DIR}/$1_id.log)
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function tranfer() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="Transfer"
    CC_ARGS="\"${User1_ADDRESS}\",\"100\""
    set -x
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c ${fcn_call} >&${LOG_DIR}/transfer.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/transfer.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function clientAccountBalance() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/$1@org1.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="ClientAccountBalance"
    CC_ARGS="\"\""
    set -x
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c ${fcn_call} >&${LOG_DIR}/$1_balance.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/$1_balance.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function approve() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="Approve"
    CC_ARGS="\"${User1_ADDRESS}\",\"500\""
    set -x
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c ${fcn_call} >&${LOG_DIR}/approve.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/approve.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function transferFrom() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="TransferFrom"
    CC_ARGS="\"${Admin_ADDRESS}\",\"${User2_ADDRESS}\",\"500\""
    set -x
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c ${fcn_call} >&${LOG_DIR}/transferFrom.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/transferFrom.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function allowance() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="Allowance"
    CC_ARGS="\"${Admin_ADDRESS}\",\"${User1_ADDRESS}\""
    set -x
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c ${fcn_call} >&${LOG_DIR}/allowance.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/allowance.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function main() {
    minter
    sleep 3
    mint
    sleep 3
    burn
    sleep 3
    client User1
    sleep 3
    clientAccountID User1
    tranfer
    sleep 3
    clientAccountBalance Admin
    clientAccountBalance User1
    client User2
    sleep 3
    approve
    sleep 3
    clientAccountID Admin
    clientAccountID User2
    allowance
    transferFrom
    sleep 3
    allowance    
}

function verifyResult() {
    if [ $1 -ne 0 ]; then
        echo -e "$2"
        exit 1
    fi
}

main



