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
: ${CHAINCODE_NAME:="token-erc-20"}
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
PEER_CONN_PARMS="${PEER_CONN_PARMS} ${TLSINFO} --peerAddresses localhost:8050 --tlsRootCertFiles /Users/park/code/purefabric/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"

export BIN_DIR="${TEST_NETWORK_HOME}/bin"
# ${BIN_DIR}/peer chaincode list --installed
# ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${ORDERER_CA} --isInit -C "mychannel0" -n "token-erc-20" -c '{"Args":["open","aabb","1122"]}' $PEER_CONN_PARMS
# ${BIN_DIR}/peer chaincode invoke -o orderer.example.com:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${ORDERER_CA} --isInit -C "mychannel0" -n "token-erc-20" $PEER_CONN_PARMS -c '{"Args":['']}'
# ${BIN_DIR}/peer chaincode invoke -o orderer.example.com:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${ORDERER_CA} -C "mychannel0" -n "token-erc-20" $PEER_CONN_PARMS -c '{"Args":["Minter",""]}'

## Query
# ${BIN_DIR}/peer chaincode query -o orderer.example.com:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${ORDERER_CA} -C "mychannel0" -n "token-erc-20"  -c '{"Args":["QueryCar","2"]}'
# ${BIN_DIR}/peer chaincode query -o orderer.example.com:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${ORDERER_CA} ${PEER_CONN_PARMS} -C "mychannel0" -n "token-erc-20" -c '{"function":"QueryCar","Args":["2"]}'

function totalSupply() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/Admin@org${ORG_NUM}.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="TotalSupply"
    CC_ARGS="\"\""
    set -x

    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "/Users/park/code/purefabric/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/TotalSupply.log
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
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "/Users/park/code/purefabric/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/Org1Admin_Address.log
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
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "/Users/park/code/purefabric/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/Org1User1_address.log
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
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "/Users/park/code/purefabric/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/Org1User2_address.log
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
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org2.example.com:8050" --tlsRootCertFiles "/Users/park/code/purefabric/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/Org2Admin_address.log
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
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org2.example.com:8050" --tlsRootCertFiles "/Users/park/code/purefabric/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/Org2User1_address.log
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
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org2.example.com:8050" --tlsRootCertFiles "/Users/park/code/purefabric/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/Org2User2_address.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Org2User2_address.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function imsy() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="Imsy"
    CC_ARGS="\"10000\""
    set -x
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c ${fcn_call} --isInit >&${LOG_DIR}/imsy.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/imsy.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

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

function adminMint() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/Admin@org${ORG_NUM}.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="AdminMint"
    CC_ARGS="\"\""
    set -x
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c ${fcn_call} >&${LOG_DIR}/imsyJuso.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/imsyJuso.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

export imsyJuso="0x7a4b92ecac928028bb7e014ec856584ce74e0b0f"
function client() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$1@org${ORG_NUM}.example.com/msp"
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="ClientByPartition"
    CC_ARGS="\"$imsyJuso\""
    set -x
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
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
    CC_ARGS="\"$imsyJuso\",\"10000\""
    set -x
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
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
    CC_ARGS="\"$imsyJuso\""
    set -x
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "/Users/park/code/purefabric/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/$1_balance.log
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

    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "/Users/park/code/purefabric/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/TotalSupply.log
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
    CC_ARGS="\"$imsyJuso\""
    set -x

    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "/Users/park/code/purefabric/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/TotalSupplyByPartition.log
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
    Address=`cat ./log/$2_Address.log`
    CC_INIT_FCN="BalanceOfByPartition"
    CC_ARGS="\"$Address\",\"$imsyJuso\""
    set -x


    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "/Users/park/code/purefabric/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/TotalSupplyByPartition.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/TotalSupplyByPartition.log

    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function allowanceByPartition() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$1@org${ORG_NUM}.example.com/msp"

    firstAddress=`cat ./log/$2_Address.log`
    secondAddress=`cat ./log/$3_Address.log`

    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="AllowanceByPartition"
    CC_ARGS="\"$firstAddress\",\"$secondAddress\",\"$imsyJuso\""
    set -x
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "query fcn call:${fcn_call}"
    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "/Users/park/code/purefabric/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c ${fcn_call} >&${LOG_DIR}/allowance.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/allowance.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function approveByPartition() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$1@org${ORG_NUM}.example.com/msp"

    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option

    Address=`cat ./log/$2_Address.log`

    CC_INIT_FCN="ApproveByPartition"
    CC_ARGS="\"$Address\",\"$imsyJuso\",\"$3\""
    set -x
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c ${fcn_call} >&${LOG_DIR}/approve.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/approve.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function transferFromByPartition() {
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$1@org${ORG_NUM}.example.com/msp"

    firstAddress=`cat ./log/$2_Address.log`
    secondAddress=`cat ./log/$3_Address.log`

    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    CC_INIT_FCN="TransferFromByPartition"
    CC_ARGS="\"$firstAddress\",\"$secondAddress\",\"$imsyJuso\",\"$4\""
    set -x
    
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":['${CC_ARGS}']}'
    echo "invoke fcn call:${fcn_call}"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c ${fcn_call} >&${LOG_DIR}/$1_transferFrom.log
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/$1_transferFrom.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function main() {
    ###### example erc1400
    imsy
    sleep 3
    init
    sleep 3
    org1
    adminMint
    sleep 3
    client Org1User1
    sleep 3
    client Org1User2
    sleep 3
    mint Org1User1
    sleep 3
    mint Org1User2
    sleep 3
    org2
    sleep 3
    client Org2User1
    sleep 3
    client Org2User2
    sleep 3
    mint Org2User1
    sleep 3
    mint Org2User2
    sleep 3
    org2
    clientAccountBalance Org2User2
    sleep 3
    org1
    balanceOfByPartition Org1User1 Org2User1
    sleep 3 
    totalSupply
    sleep 3
    totalSupplyByPartition
    sleep 3
    org2
    allowanceByPartition Org2User2 Org2User1 Org1User1
    sleep 5
    org1
    approveByPartition Org1User1 Org2User1 500
    sleep 3
    org2
    allowanceByPartition Org2User1 Org1User1 Org2User1
    sleep 5
    org2
    transferFromByPartition Org2User1 Org1User1 Org1User2 200
    sleep 5
    org1
    clientAccountBalance Org1User2
    sleep 3
    # org1
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