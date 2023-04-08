#!/bin/bash
CHANNEL_NAME="$1"
: ${CHANNEL_NAME:="mychannel0"}
DELAY="$2"
: ${DELAY:="3"}
MAX_RETRY="$3"
: ${MAX_RETRY:="10"}
VERBOSE="$4"
: ${VERBOSE:="false"}
CHAINCODE_NAME="$5"
: ${CHAINCODE_NAME:="STO"}
CHAINCODE_VERSION="$6"
: ${CHAINCODE_VERSION:="v1"}
CHAINCODE_SEQUENCE="$7"
: ${CHAINCODE_SEQUENCE:="1"}
CHAINCODE_INIT_REQUIRED="--init-required"
CHAINCODE_END_POLICY="$8"
: ${CHAINCODE_END_POLICY:=""}
CHAINCODE_COLL_CONFIG="$9"
: ${CHAINCODE_COLL_CONFIG:=""}
ORG_NUM="1"
: ${ORG_NUM:="1"}

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
# export CORE_PEER_ADDRESS="localhost:7050"
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp"
export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"

############ Start Peer ############
echo "MspPath : $CORE_PEER_MSPCONFIGPATH"

echo "chaincode invoke"
export PEERPATH="${TEST_NETWORK_HOME}"
export LOG_DIR="${TEST_NETWORK_HOME}/log"

## Invoke
PEER_CONN_PARMS="${PEER_CONN_PARMS} --peerAddresses ${CORE_PEER_ADDRESS}"
TLSINFO=$(eval echo "--tlsRootCertFiles \$CORE_PEER_TLS_ROOTCERT_FILE")
# PEER_CONN_PARMS="${PEER_CONN_PARMS} ${TLSINFO}"
PEER_CONN_PARMS="${PEER_CONN_PARMS} ${TLSINFO} --peerAddresses localhost:8050 --tlsRootCertFiles ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"

export BIN_DIR="${TEST_NETWORK_HOME}/bin"
# ${BIN_DIR}/peer chaincode list --installed
# ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${ORDERER_CA} --isInit -C "mychannel0" -n "STO" -c '{"Args":["open","aabb","1122"]}' $PEER_CONN_PARMS
# ${BIN_DIR}/peer chaincode invoke -o orderer.example.com:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${ORDERER_CA} --isInit -C "mychannel0" -n "STO" $PEER_CONN_PARMS -c '{"Args":['']}'
# ${BIN_DIR}/peer chaincode invoke -o orderer.example.com:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${ORDERER_CA} -C "mychannel0" -n "STO" $PEER_CONN_PARMS -c '{"Args":["Minter",""]}'

## Query
# ${BIN_DIR}/peer chaincode query -o orderer.example.com:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${ORDERER_CA} -C "mychannel0" -n "STO"  -c '{"Args":["QueryCar","2"]}'
# ${BIN_DIR}/peer chaincode query -o orderer.example.com:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${ORDERER_CA} ${PEER_CONN_PARMS} -C "mychannel0" -n "STO" -c '{"Function":"QueryCar","Args":["2"]}'

function totalSupply() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/Admin@org${ORG_NUM}.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="TotalSupply"
    CC_ARGS="\"\""
    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/TotalSupply.log
    { set +x; } 2>/dev/null

    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"

}

function init() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="Init"
    CC_ARGS="\"\""
    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/Org1Admin_Address.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Org1Admin_Address.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Org1User1@org1.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="Init"
    CC_ARGS="\"\""
    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/Org1User1_address.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Org1User1_address.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Org1User2@org1.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="Init"
    CC_ARGS="\"\""
    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/Org1User2_address.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Org1User2_address.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    # org2
    ############ Peer Vasic Setting ############
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_ID="$PEERID.org2.example.com"
    export CORE_PEER_ENDORSER_ENABLED=true
    export CORE_PEER_ADDRESS="$PEERID.org2.example.com:8050"
    # export CORE_PEER_ADDRESS="localhost:7050"
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"

    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="Init"
    CC_ARGS="\"\""
    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org2.example.com:8050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/Org2Admin_address.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Org2Admin_address.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Org2User1@org2.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="Init"
    CC_ARGS="\"\""
    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org2.example.com:8050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/Org2User1_address.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Org2User1_address.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Org2User2@org2.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="Init"
    CC_ARGS="\"\""
    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org2.example.com:8050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/Org2User2_address.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Org2User2_address.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function IsInit() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="IsInit"
    CC_ARGS="\"10000\""
    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c ${fcn_call} --isInit >&${LOG_DIR}/imsy.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/imsy.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

# function setOrg() {

#     ############ Peer Vasic Setting ############
#     export CORE_PEER_TLS_ENABLED=true
#     export CORE_PEER_ID="$PEERID.$1.example.com"
#     export CORE_PEER_ENDORSER_ENABLED=true
#     export CORE_PEER_ADDRESS="$PEERID.$1.example.com:7050"
#     # export CORE_PEER_ADDRESS="localhost:7050"
#     export CORE_PEER_LOCALMSPID="Org1MSP"
#     export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/$1.example.com/peers/peer0.$1.example.com/tls/ca.crt"
#     export ORG_NUM=1
# }

function org1() {
    ############ Peer Vasic Setting ############
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_ID="$PEERID.org1.example.com"
    export CORE_PEER_ENDORSER_ENABLED=true
    export CORE_PEER_ADDRESS="$PEERID.org1.example.com:7050"
    # export CORE_PEER_ADDRESS="localhost:7050"
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
    export ORG_NUM=1
}

function org2() {
    ############ Peer Vasic Setting ############
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_ID="$PEERID.org2.example.com"
    export CORE_PEER_ENDORSER_ENABLED=true
    export CORE_PEER_ADDRESS="$PEERID.org2.example.com:8050"
    # export CORE_PEER_ADDRESS="localhost:7050"
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
    export ORG_NUM=2
}

function IssuanceAsset() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/Admin@org${ORG_NUM}.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="IssuanceAsset"
    CC_ARGS="\"\""
    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c ${fcn_call} >&${LOG_DIR}/temp_token_address.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/temp_token_address.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

export temp_token_address="0xb202b4d57167fe275b82ae93e3f28ee684e4c639"

function client() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$1@org${ORG_NUM}.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="ClientByPartition"
    CC_ARGS="\"$temp_token_address\""
    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c ${fcn_call} >&${LOG_DIR}/client_$1.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/client_$1.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function mint() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$1@org${ORG_NUM}.example.com/msp"
    # export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="MintByPartition"
    CC_ARGS="\"$temp_token_address\",\"10000\""
    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c ${fcn_call} >&${LOG_DIR}/mint.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/mint.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function clientAccountBalance() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$1@org${ORG_NUM}.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="ClientAccountBalanceByPartition"
    CC_ARGS="\"$temp_token_address\""
    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/$1_balance.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/$1_balance.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function totalSupply() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/Admin@org${ORG_NUM}.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="TotalSupply"
    CC_ARGS="\"\""
    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/TotalSupply.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/TotalSupply.log

    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function totalSupplyByPartition() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/Admin@org${ORG_NUM}.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="TotalSupplyByPartition"
    CC_ARGS="\"$temp_token_address\""
    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/TotalSupplyByPartition.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/TotalSupplyByPartition.log

    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function balanceOfByPartition() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$1@org${ORG_NUM}.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option

    # $2
    Address=$(cat ./log/$2_Address.log)
    CC_INIT_FCN="BalanceOfByPartition"
    CC_ARGS="\"$Address\",\"$temp_token_address\""
    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/TotalSupplyByPartition.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/TotalSupplyByPartition.log

    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function allowanceByPartition() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$1@org${ORG_NUM}.example.com/msp"

    firstAddress=$(cat ./log/$2_Address.log)
    secondAddress=$(cat ./log/$3_Address.log)

    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="AllowanceByPartition"
    CC_ARGS="\"$firstAddress\",\"$secondAddress\",\"$temp_token_address\""
    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/allowance.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/allowance.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function approveByPartition() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$1@org${ORG_NUM}.example.com/msp"

    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option

    Address=$(cat ./log/$2_Address.log)

    CC_INIT_FCN="ApproveByPartition"
    CC_ARGS="\"$Address\",\"$temp_token_address\",\"$3\""
    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c ${fcn_call} >&${LOG_DIR}/approve.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/approve.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function transferFromByPartition() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$1@org${ORG_NUM}.example.com/msp"

    firstAddress=$(cat ./log/$2_Address.log)
    secondAddress=$(cat ./log/$3_Address.log)

    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="TransferFromByPartition"
    CC_ARGS="\"$firstAddress\",\"$secondAddress\",\"$temp_token_address\",\"$4\""
    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c ${fcn_call} >&${LOG_DIR}/$1_transferFrom.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/$1_transferFrom.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function Kyle() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/Admin@org${ORG_NUM}.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="GetAllLedger"
    CC_ARGS="{\"selector\":{\"Name\":\"0\"}}"
    # CC_ARGS="\"\""

    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'

    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    # ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/Kyle.log
    # ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c '{"Args":["GetAllLedger", "{\"selector\":{\"docType\":\"asset\",\"owner\":\"tom\"}, \"use_index\":[\"_design/indexOwnerDoc\", \"indexOwner\"]}"]}' >&${LOG_DIR}/Kyle.log
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c '{"Args":["GetAllLedger", "{\"selector\":{\"docType\":\"token\",\"name\":\"tokenName\"}}"]}' >&${LOG_DIR}/Kyle.log
    { set +x; } 2>/dev/null

    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function GetID() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$1@org${ORG_NUM}.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="GetID"
    CC_ARGS="\"\""
    set -x

    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/$1_devid.log
    { set +x; } 2>/dev/null
    export $1_ADDRESS=$(cat ${LOG_DIR}/$1_devid.log)
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function GetMSPID() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$1@org${ORG_NUM}.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="GetMSPID"
    CC_ARGS="\"\""
    set -x

    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/$1_devmspid.log
    { set +x; } 2>/dev/null
    export $1_ADDRESS=$(cat ${LOG_DIR}/$1_devmspid.log)
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function Map() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/Admin@org${ORG_NUM}.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="Map"

    CC_ARGS="\"\""
    # declare -A map
    # map["A"]="B"

    # CC_ARGS=$map
    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c '{"Args":["Map", ""]}' >&${LOG_DIR}/imsyChec11k.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/imsyChec11k.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function Map2() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$1@org${ORG_NUM}.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="Map2"
    CC_ARGS="\"\""
    set -x

    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/map.log
    { set +x; } 2>/dev/null
    # export $1_ADDRESS=$(cat ${LOG_DIR}/map.log)
    cat ${LOG_DIR}/map.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function IssuanceAsset() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$1@org${ORG_NUM}.example.com/msp"

    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="IssuanceAsset"

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c '{"Args":["IssuanceAsset", ""]}' >&${LOG_DIR}/$1_Asset.log
    { set +x; } 2>/dev/null
    export $1_Asset=$(cat ${LOG_DIR}/$1_Asset.log) \
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function CreateWallet() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/Admin@org${ORG_NUM}.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="CreateWallet"

    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c '{"Args":["CreateWallet", ""]}' >&${LOG_DIR}/$1_Wallet.log
    { set +x; } 2>/dev/null

    export $1_Wallet=$(cat ${LOG_DIR}/$1_Wallet.log) \
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function MintByPartition() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$1@org${ORG_NUM}.example.com/msp"
    # export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="MintByPartition"
    CC_ARGS="\"$temp_token_address\",\"10000\""
    set -x

    fcn_call='{"Function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c '{"Args":["MintByPartition", "{\"partition\":\"imsyToken\",\"amount\",\"100\"}"]}' >&${LOG_DIR}/mint111.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/mint111.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function main() {
    # org1

    ###### example erc1400
    IsInit
    sleep 3
    init
    sleep 3
    org1
    sleep 3
    IssuanceAsset Org1User1
    CreateWallet Org1User2
    MintByPartition Org1User2

    # org1
    # sleep 3
    # GetID Org1User1
    # org1
    # Map
    # sleep 3
    # Map2 Org1User1

    # IssuanceAsset
    # sleep 3
    # GetMSPID Org1User1
    # sleep 3
    # org1
    # sleep 3
    # CreateWallet
    # sleep 3
    # init
    # sleep 3
    # org1

    # # # setOrg org1

    # org1
    # IssuanceAsset
    # sleep 3
    # client Org1User1
    # sleep 3
    # client Org1User2
    # sleep 3
    # mint Org1User1
    # sleep 3
    # mint Org1User2
    # sleep 3
    # org2
    # sleep 3
    # client Org2User1
    # sleep 3
    # client Org2User2
    # sleep 3
    # mint Org2User1
    # sleep 3
    # mint Org2User2
    # sleep 3
    # org2
    # clientAccountBalance Org2User2
    # sleep 3
    # org1
    # balanceOfByPartition Org1User1 Org2User1
    # sleep 3
    # totalSupply
    # sleep 3
    # totalSupplyByPartition
    # sleep 3
    # org2
    # allowanceByPartition Org2User2 Org2User1 Org1User1
    # sleep 5
    # org1
    # approveByPartition Org1User1 Org2User1 500
    # sleep 3
    # org2
    # allowanceByPartition Org2User1 Org1User1 Org2User1
    # sleep 5
    # org2
    # transferFromByPartition Org2User1 Org1User1 Org1User2 200
    # sleep 5
    # org1
    # clientAccountBalance Org1User2
    # sleep 3
    # org1
    # Kyle

    # allowance Org1User2 Org1User1 Org2User1
    ### increase, decrease allowance test
    # increaseAllowance Org1User2 Org1User1 7000
    # sleep 3
    # clientAccountBalance Org1User1
    # sleep 3
    # clientAccountBalance Org1User2
    # sleep 3
    # allowance Org1User2 Org1User2 Org1User1
    # sleep 3
    # allowance Org1User2 Org1User1 Org1User2
    # sleep 3
}

function verifyResult() {
    if [ $1 -ne 0 ]; then
        echo -e "$2"
        exit 1
    fi
}

main
