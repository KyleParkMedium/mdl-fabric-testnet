#!/bin/bash
export TEST_NETWORK_HOME="/Users/park/code/mdl-fabric-testnet"
export CHAINCODE_DIR="${TEST_NETWORK_HOME}/scripts/chaincode"

CHANNEL_NAME="mychannel0"
CHAINCODE_NAME="STO"
CHAINCODE_VERSION="v1"
CHAINCODE_SEQUENCE="1"
CHAINCODE_INIT_REQUIRED="--init-required"
CHAINCODE_END_POLICY=""
CHAINCODE_COLL_CONFIG=""
DELAY=3
MAX_RETRY=10
VERBOSE=false

# CHANNEL_NAME="$1"
# : ${CHANNEL_NAME:="mychannel0"}
# DELAY="$2"
# : ${DELAY:="3"}
# MAX_RETRY="$3"
# : ${MAX_RETRY:="10"}
# VERBOSE="$4"
# : ${VERBOSE:="false"}
# CHAINCODE_NAME="$5"
# : ${CHAINCODE_NAME:="STO"}
# CHAINCODE_VERSION="$6"
# : ${CHAINCODE_VERSION:="v1"}
# CHAINCODE_SEQUENCE="$7"
# : ${CHAINCODE_SEQUENCE:="1"}
# CHAINCODE_INIT_REQUIRED="--init-required"
# CHAINCODE_END_POLICY="$8"
# : ${CHAINCODE_END_POLICY:=""}
# CHAINCODE_COLL_CONFIG="$9"
# : ${CHAINCODE_COLL_CONFIG:=""}
# ORG_NUM="1"
# : ${ORG_NUM:="1"}

LOG_LEVEL=info
export CALIPER_SCRIPT=${PWD}
export CALIPER_HOME=${CALIPER_SCRIPT%/*}
export CALIPER_BENCHMARKS=$CALIPER_HOME/benchmarks

############ Set core.yaml ############
PEERID="peer0"
# export TEST_NETWORK_HOME=$(dirname $(readlink -f $0))
# export TEST_NETWORK_HOME="${TEST_NETWORK_HOME}"
export FABRIC_CFG_PATH=${TEST_NETWORK_HOME}/config

# ############ Peer Vasic Setting ############
# export CORE_PEER_TLS_ENABLED=true
# export CORE_PEER_ID="$PEERID.org1.example.com"
# export CORE_PEER_ENDORSER_ENABLED=true
# export CORE_PEER_ADDRESS="$PEERID.org1.example.com:7050"
# # export CORE_PEER_ADDRESS="localhost:7050"
# export CORE_PEER_LOCALMSPID="Org1MSP"
# export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
# export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp"
# export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"

############ Start Peer ############
echo "MspPath : $CORE_PEER_MSPCONFIGPATH"

echo "chaincode invoke"
export PEERPATH="${TEST_NETWORK_HOME}"
export LOG_DIR="${TEST_NETWORK_HOME}/log"

# ## Invoke
# PEER_CONN_PARMS="${PEER_CONN_PARMS} --peerAddresses ${CORE_PEER_ADDRESS}"
# TLSINFO=$(eval echo "--tlsRootCertFiles \$CORE_PEER_TLS_ROOTCERT_FILE")
# # PEER_CONN_PARMS="${PEER_CONN_PARMS} ${TLSINFO}"
# PEER_CONN_PARMS="${PEER_CONN_PARMS} ${TLSINFO} --peerAddresses localhost:8050 --tlsRootCertFiles ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
PEER_CONN_PARMS="--peerAddresses peer0.org1.example.com:7050 --tlsRootCertFiles ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:8050 --tlsRootCertFiles ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"

export BIN_DIR="${TEST_NETWORK_HOME}/bin"
# ${BIN_DIR}/peer chaincode list --installed

## query example
# CC_ARGS="{\"selector\":{\"Name\":\"0\"}}"

## init string
array=""
abcd=""
string=""

## function list
function TotalSupply() {
    org1

    # set query
    echo ${FUNCNAME[0]}

    param="{\"Args\":[\"${FUNCNAME[0]}\"]}"
    echo $param

    # set
    set -x

    # set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    # export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/Admin@org${ORG_NUM}.example.com/msp"

    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/TotalSupply.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/TotalSupply.log
    cp ${LOG_DIR}/TotalSupply.log ${LOG_DIR}/Response.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function TotalSupplyByPartition() {

    org1

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
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    # export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/Admin@org${ORG_NUM}.example.com/msp"

    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/${partition}_TotalSupplyByPartition.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${partition}_TotalSupplyByPartition.log
    cp ${LOG_DIR}/${partition}_TotalSupplyByPartition.log ${LOG_DIR}/Response.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function BalanceOfByPartition() {
    org2
    ORG_NUM=2

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
    cp ${LOG_DIR}/${tokenHolder0}_TotalSupplyByPartition.log ${LOG_DIR}/Response.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function AllowanceByPartition() {

    ORG_NUM=${who:3:1}
    User=${who:4:5}

    org$ORG_NUM

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
    cp ${LOG_DIR}/${owner0}_${spender0}_${partitiion}_Allowance.log ${LOG_DIR}/Response.log
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
    cp ${LOG_DIR}/${who}_${spender0}_${partition}_IncreaseAllowance.log ${LOG_DIR}/Response.log
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
    cp ${LOG_DIR}/${who}_${spender0}_${partition}_DecreaseAllowance.log ${LOG_DIR}/Response.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function ApproveByPartition() {

    ORG_NUM=${who:3:1}
    User=${who:4:5}

    org$ORG_NUM

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
    cp ${LOG_DIR}/${who}_${spender0}_${partition}_Approve.log ${LOG_DIR}/Response.log
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
    cp ${LOG_DIR}/${who}_${recipient0}_TransferByPartition.log ${LOG_DIR}/Response.log
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
    cp ${LOG_DIR}/${who}_${from0}_${to0}_${partition}_TransferFromByPartition.log ${LOG_DIR}/Response.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function IsInit() {

    org1

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
    cp ${LOG_DIR}/IsInit.log ${LOG_DIR}/Response.log

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
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/Org1User1_Address.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Org1User1_Address.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Org1User2@org1.example.com/msp"

    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/Org1User2_Address.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Org1User2_Address.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    # set org2
    org2

    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp"

    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org2.example.com:8050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/Org2Admin_Address.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Org2Admin_Address.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Org2User1@org2.example.com/msp"

    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org2.example.com:8050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/Org2User1_Address.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Org2User1_Address.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Org2User2@org2.example.com/msp"

    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org2.example.com:8050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/Org2User2_Address.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Org2User2_Address.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function IssueToken() {

    ORG_NUM=${who:3:1}
    User=${who:4:5}

    org$ORG_NUM

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
    # export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$who@org${ORG_NUM}.example.com/msp"
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$who@org${ORG_NUM}.example.com/msp"

    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/${who}_Asset_${partition}.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${who}_Asset_${partition}.log
    cp ${LOG_DIR}/${who}_Asset_${partition}.log ${LOG_DIR}/Response.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function UndoIssueToken() {

    ORG_NUM=${who:3:1}
    User=${who:4:5}

    org$ORG_NUM

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
    # export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$who@org${ORG_NUM}.example.com/msp"
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$who@org${ORG_NUM}.example.com/msp"

    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/${who}_Undo_${partition}.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${who}_Undo_${partition}.log
    cp ${LOG_DIR}/${who}_Undo_${partition}.log ${LOG_DIR}/Response.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function CreateWallet() {
    ORG_NUM=${who:3:1}
    User=${who:4:5}

    org$ORG_NUM

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
    cp ${LOG_DIR}/${who}_Wallet.log ${LOG_DIR}/Response.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function MintByPartition() {

    ORG_NUM=${who:3:1}
    User=${who:4:5}

    org$ORG_NUM

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
    cp ${LOG_DIR}/${who}_Mint_${partition}.log ${LOG_DIR}/Response.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function BurnByPartition() {

    ORG_NUM=${who:3:1}
    User=${who:4:5}

    org$ORG_NUM

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
    cp ${LOG_DIR}/${who}_Burn_${partition}.log ${LOG_DIR}/Response.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function AirDrop() {

    org1

    # set query
    echo ${FUNCNAME[0]}

    string=${string%\,}
    array=${array%\,}

    ## query sample
    # '{"Args":["CreateWallet","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
    # param="{\"Args\":[\"${FUNCNAME[0]}\",\"{\\\"AA\\\":[{$string}]}\"]}"
    param="{\"Args\":[\"${FUNCNAME[0]}\",\"{\\\"recipients\\\":{$array},$string}\"]}"
    # param="{\"Args\":[\"${FUNCNAME[0]}\",\"{$string}\"]}"
    echo $param

    # '{"Args":["AirDrop","{\"from\":\"0x47a7a67edf2e0f1e89d1ab7b547dc67d0ce334df\",\"to\":\"0x7eddc225c347da6b844b87baeecdfd7be35eb1c0\",\"partition\":\"mediumToken\",\"amount\":10}"]}'
    # '{"Args":["AirDrop","{"AA":[\"from\":\"0x47a7a67edf2e0f1e89d1ab7b547dc67d0ce334df\",\"to\":\"0x7eddc225c347da6b844b87baeecdfd7be35eb1c0\",\"partition\":\"mediumToken\",\"amount\":10]}"]}'

    # set
    set -x

    ## set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    # export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$who@org${ORG_NUM}.example.com/msp"

    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/AirDrop.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/AirDrop.log
    cp ${LOG_DIR}/AirDrop.log ${LOG_DIR}/Response.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function GetTokenWalletList() {

    ORG_NUM=${who:3:1}
    User=${who:4:5}
    org$ORG_NUM

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
    cp ${LOG_DIR}/GetTokenWalletList.log ${LOG_DIR}/Response.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function GetAdminWallet() {

    ORG_NUM=${who:3:1}
    User=${who:4:5}
    org$ORG_NUM

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
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/GetAdminWallet.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/GetAdminWallet.log
    cp ${LOG_DIR}/GetAdminWallet.log ${LOG_DIR}/Response.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function GetTokenList() {

    ORG_NUM=${who:3:1}
    User=${who:4:5}
    org$ORG_NUM

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
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/GetTokenList.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/GetTokenList.log
    cp ${LOG_DIR}/GetTokenList.log ${LOG_DIR}/Response.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function GetTokenHolderList() {

    ORG_NUM=${who:3:1}
    User=${who:4:5}
    org$ORG_NUM

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
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/GetTokenHolderList.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/GetTokenHolderList.log
    cp ${LOG_DIR}/GetTokenHolderList.log ${LOG_DIR}/Response.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function GetHolderList() {

    ORG_NUM=${who:3:1}
    User=${who:4:5}
    org$ORG_NUM

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

    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/GetHolderList.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/GetHolderList.log
    cp ${LOG_DIR}/GetHolderList.log ${LOG_DIR}/Response.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function GetData() {

    ORG_NUM=${who:3:1}
    User=${who:4:5}
    org$ORG_NUM

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

    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/GetHolderList.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/GetHolderList.log
    cp ${LOG_DIR}/GetHolderList.log ${LOG_DIR}/Response.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function DistributeToken() {

    org1

    # set query
    echo ${FUNCNAME[0]}

    string=${string%\,}
    array=${array%\,}

    ## query sample
    # '{"Args":["CreateWallet","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
    # param="{\"Args\":[\"${FUNCNAME[0]}\",\"{\\\"AA\\\":[{$string}]}\"]}"
    param="{\"Args\":[\"${FUNCNAME[0]}\",\"{\\\"recipients\\\":{$array},$string}\"]}"
    # param="{\"Args\":[\"${FUNCNAME[0]}\",\"{$string}\"]}"
    echo $param

    # '{"Args":["AirDrop","{\"from\":\"0x47a7a67edf2e0f1e89d1ab7b547dc67d0ce334df\",\"to\":\"0x7eddc225c347da6b844b87baeecdfd7be35eb1c0\",\"partition\":\"mediumToken\",\"amount\":10}"]}'
    # '{"Args":["AirDrop","{"AA":[\"from\":\"0x47a7a67edf2e0f1e89d1ab7b547dc67d0ce334df\",\"to\":\"0x7eddc225c347da6b844b87baeecdfd7be35eb1c0\",\"partition\":\"mediumToken\",\"amount\":10]}"]}'

    # set
    set -x

    ## set env
    # export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/Admin@org${ORG_NUM}.example.com/msp"
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"

    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/Check.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Check.log
    cp ${LOG_DIR}/Check.log ${LOG_DIR}/Response.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function RedeemToken2() {

    ORG_NUM=${who:3:1}
    User=${who:4:5}

    org$ORG_NUM

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
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/${who}_Redeem_${partition}.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${who}_Redeem2_${partition}.log
    cp ${LOG_DIR}/${who}_Redeem2_${partition}.log ${LOG_DIR}/Response.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function RedeemToken() {

    ORG_NUM=${who:3:1}
    User=${who:4:5}

    org$ORG_NUM

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
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/${who}_Redeem_${partition}.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${who}_Redeem_${partition}.log
    cp ${LOG_DIR}/${who}_Redeem_${partition}.log ${LOG_DIR}/Response.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function IsIssuable() {

    ORG_NUM=${who:3:1}
    User=${who:4:5}
    org$ORG_NUM

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
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/${partition}_IsIssuable.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${partition}_IsIssuable.log
    cp ${LOG_DIR}/${partition}_IsIssuable.log ${LOG_DIR}/Response.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function IsOperatorByPartition() {

    ORG_NUM=${who:3:1}
    User=${who:4:5}
    org$ORG_NUM

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
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/${operator}_${partition}_IsOperatorByPartition.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${operator}_${partition}_IsOperatorByPartition.log
    cp ${LOG_DIR}/${operator}_${partition}_IsOperatorByPartition.log ${LOG_DIR}/Response.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function AuthorizeOperatorByPartition() {

    ORG_NUM=${who:3:1}
    User=${who:4:5}
    org$ORG_NUM

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
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/${operator}_${partition}_AuthorizeOperatorByPartition.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${operator}_${partition}_AuthorizeOperatorByPartition.log
    cp ${LOG_DIR}/${operator}_${partition}_AuthorizeOperatorByPartition.log ${LOG_DIR}/Response.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function RevokeOperatorByPartition() {

    ORG_NUM=${who:3:1}
    User=${who:4:5}
    org$ORG_NUM

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
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/${operator}_${partition}_RevokeOperatorByPartition.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${operator}_${partition}_RevokeOperatorByPartition.log
    cp ${LOG_DIR}/${operator}_${partition}_RevokeOperatorByPartition.log ${LOG_DIR}/Response.log
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
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/$User@org1.example.com/msp"
    export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"
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
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/$User@org2.example.com/msp"
    export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"
}

function usage() {
    cat <<EOM
Request 잘못 입력.
Usage: $0 [options] <url>
Options:
 -X, --request COMMAND   Specify request command to use
 -v, --verbose           Make the operation more talkative
 -F, --Function          Chaincode function name
 -c, --caller            체인코드 호출자 혹은 백엔드 호출자 아직 미정
 -O, --operator          Operator By Partition
 -h, --tokenHolder       Token holder
 -o, --owner             Token owner
 -s, --spender           Who wants to send token
 -f, --from              Token Spender ( TransferFrom )
 -t, --to                Token Recipient ( TransferFrom )
 -r, --recipient         Token Recipient
 -d, --airdrop           AirDrop
 -p, --partiton          Partition token address
 -a, --amount            Amount
 -b, --bookmark          Searching for a query by bookmark
 -z, --pageSize          Searching for a query by pageSize
EOM

    exit 1
}

function set_options() {
    while [ "${1:-}" != "" ]; do
        case "$1" in
        -F | --function)
            shift
            function=$1
            ;;
        -c | --caller)
            shift
            who=$1
            string+="\\\"caller\\\":\\\"$who\\\","
            ;;
        -h | --tokenHolder)
            shift
            tokenHolder0=$1
            # tokenHolder=$(cat ./log/${tokenHolder0}_Address.log)
            # tokenHolder=$(cat ${TEST_NETWORK_HOME}/log/${tokenHolder0}_Address.log)
            string+="\\\"tokenHolder\\\":\\\"$tokenHolder0\\\","
            ;;
        -O | --operator)
            shift
            operator0=$1
            # tokenHolder=$(cat ./log/${tokenHolder0}_Address.log)
            # operator=$(cat ${TEST_NETWORK_HOME}/log/${operator0}_Address.log)
            string+="\\\"operator\\\":\\\"$operator0\\\","
            ;;
        -o | --owner)
            shift
            owner0=$1
            owner=$(cat ${TEST_NETWORK_HOME}/log/${owner0}_Address.log)
            string+="\\\"owner\\\":\\\"$owner0\\\","
            ;;
        -s | --spender)
            shift
            spender0=$1
            spender=$(cat ${TEST_NETWORK_HOME}/log/${spender0}_Address.log)
            string+="\\\"spender\\\":\\\"$spender0\\\","
            ;;
        -f | --from)
            shift
            from0=$1
            from=$(cat ${TEST_NETWORK_HOME}/log/${from0}_Address.log)
            string+="\\\"from\\\":\\\"$from0\\\","
            ;;
        -t | --to)
            shift
            to0=$1
            to=$(cat ${TEST_NETWORK_HOME}/log/${to0}_Address.log)
            string+="\\\"to\\\":\\\"$to0\\\","
            ;;
        -r | --recipient)
            shift
            # recipient0=$1
            # recipient=$(cat ${TEST_NETWORK_HOME}/log/${recipient0}_Address.log)
            recipient=$1
            string+="\\\"recipient\\\":\\\"$recipient\\\","
            ;;
        -d | --drop)
            shift
            # recipient0=$1
            # recipient=$(cat ./log/${recipient0}_Address.log)
            # array+="\\\"${recipient0}\\\":\\\"$recipient\\\","
            array=$1
            # echo $abcd
            # array += "\"$1\""
            ;;
        -p | --partition)
            shift
            partition=$1
            string+="\\\"partition\\\":\\\"$partition\\\","
            ;;
        -a | --amount)
            shift
            amount=$1
            string+="\\\"amount\\\":\\\"$amount\\\","
            ;;
        -b | --bookmark)
            shift
            bookmark=$1
            string+="\\\"bookmark\\\":\\\"$bookmark\\\","
            ;;
        -p | --pageSize)
            shift
            pageSize=$1
            INT=$((pageSize))
            string+="\\\"pageSize\\\":$INT,"
            ;;
        -p | --tokenWalletId)
            shift
            tokenWalletId=$1
            string+="\\\"tokenWalletId\\\":\\\"$tokenWalletId\\\","
            ;;
        -p | --role)
            shift
            role=$1
            string+="\\\"role\\\":\\\"$role\\\","
            ;;
        -p | --accountNumber)
            shift
            accountNumber=$1
            string+="\\\"accountNumber\\\":\\\"$accountNumber\\\","
            ;;
        -p | --tokenId)
            shift
            tokenId=$1
            string+="\\\"tokenId\\\":\\\"$tokenId\\\","
            ;;
        -p | --productName)
            shift
            productName=$1
            string+="\\\"productName\\\":\\\"$productName\\\","
            ;;
        -p | --publisher)
            shift
            publisher=$1
            string+="\\\"publisher\\\":\\\"$publisher\\\","
            ;;
        -p | --publisherUuid)
            shift
            publisherUuid=$1
            string+="\\\"publisherUuid\\\":\\\"$publisherUuid\\\","
            ;;
        -p | --ror)
            shift
            ror=$1
            string+="\\\"ror\\\":\\\"$ror\\\","
            ;;
        -p | --investmentPeriod)
            shift
            investmentPeriod=$1
            string+="\\\"investmentPeriod\\\":\\\"$investmentPeriod\\\","
            ;;
        -p | --grade)
            shift
            grade=$1
            string+="\\\"grade\\\":\\\"$grade\\\","
            ;;
        -p | --publicOfferingAmount)
            shift
            publicOfferingAmount=$1
            string+="\\\"publicOfferingAmount\\\":\\\"$publicOfferingAmount\\\","
            ;;
        -p | --startDate)
            shift
            startDate=$1
            string+="\\\"startDate\\\":\\\"$startDate\\\","
            ;;
        -p | --endDate)
            shift
            endDate=$1
            string+="\\\"endDate\\\":\\\"$endDate\\\","
            ;;
        -p | --docType)
            shift
            docType=$1
            string+="\\\"docType\\\":\\\"$docType\\\","
            ;;
        -p | --partitionTokens)
            shift
            partitionTokens=$1
            string+="\\\"partitionTokens\\\":\\\"$partitionTokens\\\","
            ;;
        -p | --tokenHolderId)
            shift
            tokenHolderId=$1
            string+="\\\"tokenHolderId\\\":\\\"$tokenHolderId\\\","
            ;;
        -p | --channelNm)
            shift
            channelNm=$1
            string+="\\\"channelNm\\\":\\\"$channelNm\\\","
            ;;
        *)
            usage
            ;;
        esac
        shift
    done
}

set_options "$@"

$function
