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

## query example
# CC_ARGS="{\"selector\":{\"Name\":\"0\"}}"

## init string
string=""
array=""
## function list
function TotalSupply() {

    # set query
    echo ${FUNCNAME[0]}

    param="{\"Args\":[\"${FUNCNAME[0]}\"]}"
    echo $param

    # set
    set -x

    # set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/Admin@org${ORG_NUM}.example.com/msp"

    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/TotalSupply.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/TotalSupply.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function TotalSupplyByPartition() {

    # set query
    echo ${FUNCNAME[0]}

    string=${string%\,}

    ## query sample
    # '{"Args":["IssuanceAsset","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
    param="{\"Args\":[\"${FUNCNAME[0]}\",\"{$string}\"]}"
    echo $param

    # set
    set -x

    # set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/Admin@org${ORG_NUM}.example.com/msp"

    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/${partition}_TotalSupplyByPartition.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${partition}_TotalSupplyByPartition.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
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

function BalanceOfByPartition() {

    # set query
    echo ${FUNCNAME[0]}

    string=${string%\,}

    ## query sample
    # '{"Args":["IssuanceAsset","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
    param="{\"Args\":[\"${FUNCNAME[0]}\",\"{$string}\"]}"
    echo $param

    # set
    set -x

    ## set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/Admin@org${ORG_NUM}.example.com/msp"

    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/${tokenHolder0}_TotalSupplyByPartition.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${tokenHolder0}_TotalSupplyByPartition.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function AllowanceByPartition() {

    # set query
    echo ${FUNCNAME[0]}

    string=${string%\,}

    ## query sample
    # '{"Args":["IssuanceAsset","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
    param="{\"Args\":[\"${FUNCNAME[0]}\",\"{$string}\"]}"
    echo $param

    # set
    set -x

    ## set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$who@org${ORG_NUM}.example.com/msp"

    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/${owner0}_${spender0}_${partitiion}_Allowance.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${owner0}_${spender0}_${partitiion}_Allowance.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function IncreaseAllowanceByPartition() {

    # set query
    echo ${FUNCNAME[0]}

    string=${string%\,}

    ## query sample
    # '{"Args":["IssuanceAsset","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
    param="{\"Args\":[\"${FUNCNAME[0]}\",\"{$string}\"]}"
    echo $param

    # set
    set -x

    ## set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$who@org${ORG_NUM}.example.com/msp"

    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/${who}_${spender0}_${partition}_IncreaseAllowance.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${who}_${spender0}_${partition}_IncreaseAllowance.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function DecreaseAllowanceByPartition() {

    # set query
    echo ${FUNCNAME[0]}

    string=${string%\,}

    ## query sample
    # '{"Args":["IssuanceAsset","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
    param="{\"Args\":[\"${FUNCNAME[0]}\",\"{$string}\"]}"
    echo $param

    # set
    set -x

    ## set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$who@org${ORG_NUM}.example.com/msp"

    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/${who}_${spender0}_${partition}_DecreaseAllowance.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${who}_${spender0}_${partition}_DecreaseAllowance.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function ApproveByPartition() {

    # set query
    echo ${FUNCNAME[0]}

    string=${string%\,}

    ## query sample
    # '{"Args":["IssuanceAsset","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
    param="{\"Args\":[\"${FUNCNAME[0]}\",\"{$string}\"]}"
    echo $param

    # set
    set -x

    ## set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$who@org${ORG_NUM}.example.com/msp"

    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/${who}_${spender0}_${partition}_Approve.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${who}_${spender0}_${partition}_Approve.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function TransferByPartition() {

    # set query
    echo ${FUNCNAME[0]}

    string=${string%\,}

    ## query sample
    # '{"Args":["CreateWallet","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
    param="{\"Args\":[\"${FUNCNAME[0]}\",\"{$string}\"]}"
    echo $param

    # set
    set -x

    ## set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/${who}@org${ORG_NUM}.example.com/msp"

    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/${who}_${recipient0}_TransferByPartition.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${who}_${recipient0}_TransferByPartition.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function TransferFromByPartition() {

    # set query
    echo ${FUNCNAME[0]}

    string=${string%\,}

    ## query sample
    # '{"Args":["CreateWallet","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
    param="{\"Args\":[\"${FUNCNAME[0]}\",\"{$string}\"]}"
    echo $param

    # set
    set -x

    ## set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$who@org${ORG_NUM}.example.com/msp"

    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/${who}_${from0}_${to0}_${partition}_TransferFromByPartition.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${who}_${from0}_${to0}_${partition}_TransferFromByPartition.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function IsInit() {

    # set query
    echo ${FUNCNAME[0]}

    param="{\"Args\":[\"${FUNCNAME[0]}\"]}"
    echo $param

    # set
    set -x

    # set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"

    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param --isInit >&${LOG_DIR}/IsInit.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/IsInit.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function Init() {

    # set query
    echo ${FUNCNAME[0]}

    param="{\"Args\":[\"${FUNCNAME[0]}\"]}"
    echo $param

    # set
    set -x

    # set org
    org1

    ## set Client Address
    # set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"

    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/Org1Admin_Address.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Org1Admin_Address.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Org1User1@org1.example.com/msp"

    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/Org1User1_address.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Org1User1_address.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Org1User2@org1.example.com/msp"

    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/Org1User2_address.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Org1User2_address.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    # set org2
    org2

    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp"

    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org2.example.com:8050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/Org2Admin_address.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Org2Admin_address.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Org2User1@org2.example.com/msp"

    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org2.example.com:8050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/Org2User1_address.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Org2User1_address.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Org2User2@org2.example.com/msp"

    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org2.example.com:8050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/Org2User2_address.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Org2User2_address.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function IssuanceAsset() {

    # set query
    echo ${FUNCNAME[0]}

    string=${string%\,}

    ## query sample
    # '{"Args":["IssuanceAsset","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
    param="{\"Args\":[\"${FUNCNAME[0]}\",\"{$string}\"]}"
    echo $param

    # set
    set -x

    ## set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$who@org${ORG_NUM}.example.com/msp"

    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/${who}_Asset_${partition}.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${who}_Asset_${partition}.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function CreateWallet() {

    # set query
    echo ${FUNCNAME[0]}

    string=${string%\,}

    ## query sample
    # '{"Args":["CreateWallet","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
    param="{\"Args\":[\"${FUNCNAME[0]}\",\"{$string}\"]}"
    echo $param

    # set
    set -x

    ## set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$who@org${ORG_NUM}.example.com/msp"

    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/${who}_Wallet.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${who}_Wallet.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function MintByPartition() {

    # set query
    echo ${FUNCNAME[0]}

    string=${string%\,}

    ## query sample
    # '{"Args":["MintByPartition","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
    param="{\"Args\":[\"${FUNCNAME[0]}\",\"{$string}\"]}"
    echo $param

    # set
    set -x

    ## set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$who@org${ORG_NUM}.example.com/msp"

    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/${who}_Mint_${partition}.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${who}_Mint_${partition}.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function BurnByPartition() {

    # set query
    echo ${FUNCNAME[0]}

    string=${string%\,}

    ## query sample
    # '{"Args":["MintByPartition","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
    param="{\"Args\":[\"${FUNCNAME[0]}\",\"{$string}\"]}"
    echo $param

    # set
    set -x

    ## set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$who@org${ORG_NUM}.example.com/msp"

    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/${who}_Burn_${partition}.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${who}_Burn_${partition}.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function AirDrop() {

    # set query
    echo ${FUNCNAME[0]}

    string=${string%\,}
    array=${array%\,}

    ## query sample
    # '{"Args":["CreateWallet","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
    # param="{\"Args\":[\"${FUNCNAME[0]}\",\"{\\\"AA\\\":[{$string}]}\"]}"
    param="{\"Args\":[\"${FUNCNAME[0]}\",\"{\\\"Recipients\\\":{$array},$string}\"]}"
    # param="{\"Args\":[\"${FUNCNAME[0]}\",\"{$string}\"]}"
    echo $param

    # '{"Args":["AirDrop","{\"from\":\"0x47a7a67edf2e0f1e89d1ab7b547dc67d0ce334df\",\"to\":\"0x7eddc225c347da6b844b87baeecdfd7be35eb1c0\",\"partition\":\"mediumToken\",\"amount\":10}"]}'
    # '{"Args":["AirDrop","{"AA":[\"from\":\"0x47a7a67edf2e0f1e89d1ab7b547dc67d0ce334df\",\"to\":\"0x7eddc225c347da6b844b87baeecdfd7be35eb1c0\",\"partition\":\"mediumToken\",\"amount\":10]}"]}'

    # set
    set -x

    ## set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$who@org${ORG_NUM}.example.com/msp"

    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/aaa.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/aaa.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function GetTokenWalletList() {

    # set query
    echo ${FUNCNAME[0]}

    string=${string%\,}
    # ,false

    ## query sample
    # '{"Args":["IssuanceAsset","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
    param="{\"Args\":[\"${FUNCNAME[0]}\",\"{$string}\"]}"
    echo $param

    # set
    set -x

    ## set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$who@org${ORG_NUM}.example.com/msp"

    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/GetTokenWalletList.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/GetTokenWalletList.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function A() {
    touch sample.txt
    echo "cehc"
}

while getopts ":F:u:h:o:s:f:t:r:d:p:a:b:z:" OPT; do
    case $OPT in
    F)
        function=$OPTARG
        ;;
    u)
        who=$OPTARG
        ;;
    h)
        tokenHolder0=$OPTARG
        tokenHolder=$(cat ./log/${tokenHolder0}_Address.log)
        string+="\\\"tokenHolder\\\":\\\"$tokenHolder\\\","
        ;;
    o)
        owner0=$OPTARG
        owner=$(cat ./log/${owner0}_Address.log)
        string+="\\\"owner\\\":\\\"$owner\\\","
        ;;
    s)
        spender0=$OPTARG
        spender=$(cat ./log/${spender0}_Address.log)
        string+="\\\"spender\\\":\\\"$spender\\\","
        ;;
    f)
        from0=$OPTARG
        from=$(cat ./log/${from0}_Address.log)
        string+="\\\"from\\\":\\\"$from\\\","
        ;;
    t)
        to0=$OPTARG
        to=$(cat ./log/${to0}_Address.log)
        string+="\\\"to\\\":\\\"$to\\\","
        ;;
    r)
        recipient0=$OPTARG
        recipient=$(cat ./log/${recipient0}_Address.log)
        string+="\\\"recipient\\\":\\\"$recipient\\\","
        ;;
    d)
        recipient0=$OPTARG
        recipient=$(cat ./log/${recipient0}_Address.log)
        array+="\\\"${recipient0}\\\":\\\"$recipient\\\","
        ;;
    p)
        partition=$OPTARG
        string+="\\\"partition\\\":\\\"$partition\\\","
        ;;
    a)
        amount=$OPTARG
        string+="\\\"amount\\\":$amount,"
        ;;

    b)
        bookmark=$OPTARG
        string+="\\\"bookmark\\\":\\\"$bookmark\\\","
        ;;
    z)
        pageSize=$OPTARG
        string+="\\\"pageSize\\\":$pageSize,"
        ;;
    esac
done
shift "$((OPTIND - 1))"

$function
