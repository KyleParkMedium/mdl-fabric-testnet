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
# export TEST_NETWORK_HOME=$(dirname $(readlink -f $0))
export TEST_NETWORK_HOME="/Users/park/test/mdl-fabric-testnet"

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

export BIN_DIR="${TEST_NETWORK_HOME}/bin"
# ${BIN_DIR}/peer chaincode list --installed

## query example
# CC_ARGS="{\"selector\":{\"Name\":\"0\"}}"

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

    local string
    local OPTIND OPT p
    while getopts ":p:" OPT; do
        case $OPT in
        p)
            partition=$OPTARG
            string+="\\\"partition\\\":\\\"$partition\\\","
            ;;
        esac
    done
    shift "$((OPTIND - 1))"
    string=${string%\,}

    ## query sample
    # '{"Args":["IssueToken","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
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
    export FABRIC_CFG_PATH=${TEST_NETWORK_HOME}/config/org1
    export HOST="peer0.org1.example.com"
    export PORT=7050
    export ORG="Org1"
    ############ Peer Vasic Setting ############
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_ID="peer0.org1.example.com"
    export CORE_PEER_ENDORSER_ENABLED=true
    export CORE_PEER_ADDRESS="peer0.org1.example.com:7050"
    # export CORE_PEER_ADDRESS="localhost:7050"
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"
}

function org2() {
    export FABRIC_CFG_PATH=${TEST_NETWORK_HOME}/config/org2
    export HOST="peer0.org2.example.com"
    export PORT=8050
    export ORG="Org2"
    ############ Peer Vasic Setting ############
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_ID="peer0.org2.example.com"
    export CORE_PEER_ENDORSER_ENABLED=true
    export CORE_PEER_ADDRESS="peer0.org2.example.com:8050"
    # export CORE_PEER_ADDRESS="localhost:7050"
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp"
    export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"
}

function org3() {
    export FABRIC_CFG_PATH=${TEST_NETWORK_HOME}/config/org3
    export HOST="peer0.org3.example.com"
    export PORT=6050
    export ORG="Org3"
    ############ Peer Vasic Setting ############
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_ID="peer0.org3.example.com"
    export CORE_PEER_ENDORSER_ENABLED=true
    export CORE_PEER_ADDRESS="peer0.org3.example.com:6050"
    # export CORE_PEER_ADDRESS="localhost:7050"
    export CORE_PEER_LOCALMSPID="Org3MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp"
    export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"
}

function BalanceOfByPartition() {

    # set query
    echo ${FUNCNAME[0]}

    local string
    local OPTIND OPT u p
    while getopts ":u:p:" OPT; do
        case $OPT in
        u)
            tokenHolder0=$OPTARG
            tokenHolder=$(cat ./log/${tokenHolder0}_Address.log)
            string+="\\\"tokenHolder\\\":\\\"$tokenHolder\\\","
            ;;
        p)
            partition=$OPTARG
            string+="\\\"partition\\\":\\\"$partition\\\","
            ;;
        esac
    done
    shift "$((OPTIND - 1))"
    string=${string%\,}

    ## query sample
    # '{"Args":["IssueToken","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
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

    local string
    local OPTIND OPT u p o s
    while getopts ":u:p:o:s:" OPT; do
        case $OPT in
        u)
            who=$OPTARG
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
        p)
            partition=$OPTARG
            string+="\\\"partition\\\":\\\"$partition\\\","
            ;;
        esac
    done
    shift "$((OPTIND - 1))"
    string=${string%\,}

    ## query sample
    # '{"Args":["IssueToken","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
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

    local string
    local OPTIND OPT u p a s
    while getopts ":u:p:a:s:" OPT; do
        case $OPT in
        u)
            who=$OPTARG
            ;;
        s)
            spender0=$OPTARG
            spender=$(cat ./log/${spender0}_Address.log)
            string+="\\\"spender\\\":\\\"$spender\\\","
            ;;
        p)
            partition=$OPTARG
            string+="\\\"partition\\\":\\\"$partition\\\","
            ;;
        a)
            amount=$OPTARG
            string+="\\\"amount\\\":$amount,"
            ;;
        esac
    done
    shift "$((OPTIND - 1))"
    string=${string%\,}

    ## query sample
    # '{"Args":["IssueToken","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
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

    local string
    local OPTIND OPT u p a s
    while getopts ":u:p:a:s:" OPT; do
        case $OPT in
        u)
            who=$OPTARG
            ;;
        s)
            spender0=$OPTARG
            spender=$(cat ./log/${spender0}_Address.log)
            string+="\\\"spender\\\":\\\"$spender\\\","
            ;;
        p)
            partition=$OPTARG
            string+="\\\"partition\\\":\\\"$partition\\\","
            ;;
        a)
            amount=$OPTARG
            string+="\\\"amount\\\":$amount,"
            ;;
        esac
    done
    shift "$((OPTIND - 1))"
    string=${string%\,}

    ## query sample
    # '{"Args":["IssueToken","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
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

    local string
    local OPTIND OPT u p a s
    while getopts ":u:p:s:a:" OPT; do
        case $OPT in
        u)
            who=$OPTARG
            ;;
        s)
            spender0=$OPTARG
            spender=$(cat ./log/${spender0}_Address.log)
            string+="\\\"spender\\\":\\\"$spender\\\","
            ;;
        p)
            partition=$OPTARG
            string+="\\\"partition\\\":\\\"$partition\\\","
            ;;
        a)
            amount=$OPTARG
            string+="\\\"amount\\\":$amount,"
            ;;
        esac
    done
    shift "$((OPTIND - 1))"
    string=${string%\,}

    ## query sample
    # '{"Args":["IssueToken","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
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

    local string
    local OPTIND OPT u p a r
    while getopts ":u:r:p:a:" OPT; do
        case $OPT in
        u)
            who=$OPTARG
            ;;
        r)
            recipient0=$OPTARG
            recipient=$(cat ./log/${recipient0}_Address.log)
            string+="\\\"recipient\\\":\\\"$recipient\\\","
            ;;
        p)
            partition=$OPTARG
            string+="\\\"partition\\\":\\\"$partition\\\","
            ;;
        a)
            amount=$OPTARG
            string+="\\\"amount\\\":$amount,"
            ;;
        esac
    done
    shift "$((OPTIND - 1))"
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

    local string
    local OPTIND OPT u p a f t
    while getopts ":u:f:t:p:a:" OPT; do
        case $OPT in
        u)
            who=$OPTARG
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
        p)
            partition=$OPTARG
            string+="\\\"partition\\\":\\\"$partition\\\","
            ;;
        a)
            amount=$OPTARG
            string+="\\\"amount\\\":$amount,"
            ;;
        esac
    done
    shift "$((OPTIND - 1))"
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

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        --ch)
            export CHANNEL_NAME="$2"
            shift 2
            ;;
        --p)
            $2
            export PEER_CONN_PARMS="${PEER_CONN_PARMS} --peerAddresses ${CORE_PEER_ADDRESS}"
            TLSINFO=$(eval echo "--tlsRootCertFiles \$CORE_PEER_TLS_ROOTCERT_FILE")
            export PEER_CONN_PARMS="${PEER_CONN_PARMS} ${TLSINFO}"
            shift 2
            ;;
        *)
            echo "Unknown parameter: $1"
            exit 1
            ;;
        esac
    done

    # set query
    echo ${FUNCNAME[0]}

    param="{\"Args\":[\"${FUNCNAME[0]}\"]}"
    echo $param

    # set
    set -x

    # set env
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param --isInit >&${LOG_DIR}/IsInit.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/IsInit.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    PEER_CONN_PARMS=""
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

    # set query
    echo ${FUNCNAME[0]}

    local string
    local OPTIND OPT u p
    while getopts ":u:p:" OPT; do
        case $OPT in
        u)
            who=$OPTARG
            ;;
        p)
            partition=$OPTARG
            string+="\\\"partition\\\":\\\"$partition\\\","
            ;;
        esac
    done
    shift "$((OPTIND - 1))"
    string=${string%\,}

    ## query sample
    # '{"Args":["IssueToken","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
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

    local string
    local OPTIND OPT u p a
    while getopts ":u:p:a:" OPT; do
        case $OPT in
        u)
            who=$OPTARG
            ;;
        p)
            partition=$OPTARG
            string+="\\\"partition\\\":\\\"$partition\\\","
            ;;
        a)
            amount=$OPTARG
            string+="\\\"amount\\\":$amount,"
            ;;
        esac
    done
    shift "$((OPTIND - 1))"
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

    local string
    local OPTIND OPT u p a
    local who
    while getopts ":u:p:a:" OPT; do
        case $OPT in
        u)
            who=$OPTARG
            ;;
        p)
            partition=$OPTARG
            string+="\\\"partition\\\":\\\"$partition\\\","
            ;;
        a)
            amount=$OPTARG
            string+="\\\"amount\\\":$amount,"
            ;;
        esac
    done
    shift "$((OPTIND - 1))"
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

    local string
    local OPTIND OPT u p a
    local who
    while getopts ":u:p:a:" OPT; do
        case $OPT in
        u)
            who=$OPTARG
            ;;
        p)
            partition=$OPTARG
            string+="\\\"partition\\\":\\\"$partition\\\","
            ;;
        a)
            amount=$OPTARG
            string+="\\\"amount\\\":$amount,"
            ;;
        esac
    done
    shift "$((OPTIND - 1))"
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

    local string
    local array
    local OPTIND OPT u r p a
    while getopts ":u:r:p:a:" OPT; do
        case $OPT in
        u)
            who=$OPTARG
            ;;
        r)
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
        esac
    done
    shift "$((OPTIND - 1))"
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

function DistributeToken() {

    # set query
    echo ${FUNCNAME[0]}

    local string
    local array
    local OPTIND OPT u r p a
    while getopts ":u:r:p:" OPT; do
        case $OPT in
        u)
            who=$OPTARG
            ;;
        r)
            recipient0=$OPTARG
            recipient=$(cat ./log/${recipient0}_Address.log)
            # array+="\\\"${recipient0}\\\":$amount,"
            array+="\\\"${recipient}\\\":100,"
            ;;
        p)
            partition=$OPTARG
            string+="\\\"partition\\\":\\\"$partition\\\","
            ;;
        esac
    done
    shift "$((OPTIND - 1))"
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
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/DistributeToken.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/DistributeToken.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function GetTokenWalletList() {

    # set query
    echo ${FUNCNAME[0]}

    local string
    local OPTIND OPT u b p
    while getopts ":u:b:p:" OPT; do
        case $OPT in
        u)
            who=$OPTARG
            ;;

        b)
            bookmark=$OPTARG
            string+="\\\"bookmark\\\":\\\"$bookmark\\\","
            ;;

        p)
            pageSize=$OPTARG
            string+="\\\"pageSize\\\":$pageSize,"
            ;;
        esac
    done
    shift "$((OPTIND - 1))"
    string=${string%\,}
    # ,false

    ## query sample
    # '{"Args":["IssueToken","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
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

function GetHolderList() {

    # set query
    echo ${FUNCNAME[0]}

    local string
    local OPTIND OPT p
    while getopts ":p:" OPT; do
        case $OPT in
        p)
            partition=$OPTARG
            string+="\\\"partition\\\":\\\"$partition\\\","
            ;;
        esac
    done
    shift "$((OPTIND - 1))"
    string=${string%\,}

    ## query sample
    # '{"Args":["IssueToken","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
    param="{\"Args\":[\"${FUNCNAME[0]}\",\"{$string}\"]}"
    echo $param

    # set
    set -x

    # set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/Admin@org${ORG_NUM}.example.com/msp"

    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/${partition}_HolderList.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${partition}_HolderList.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function InitLedger() {

    # set query
    echo ${FUNCNAME[0]}

    param="{\"Args\":[\"${FUNCNAME[0]}\"]}"
    echo $param

    # set
    set -x

    # set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"

    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param --isInit >&${LOG_DIR}/InitLedger.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/InitLedger.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function GetData() {

    # set query
    echo ${FUNCNAME[0]}

    ddd='{
    "selector": {
        "docType": "DOCTYPE_TOKEN_WALLET"
    },
    "fields": [],
    "sort": [
        {"docType": "asc"},
        {"tokenWalletId": "asc"},
        {"tokenId": "asc"}
    ],
    "use_index": [
        "_design/GetDataDoc",
        "GetDataIndex"
    ],
    "bookmark": "",
    "pageSize": 10
}'

    ## query sample
    # '{"Args":["IssueToken","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
    param="{\"Args\":[\"${FUNCNAME[0]}\",\"{$ddd}\"]}"
    echo $param

    # set
    set -x

    # set env
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"

    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/AAA.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/AAA.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function BulkCreateWallet() {

    for var in {1..100}; do

        aa=""
        aa="$var"
        string=""
        string+="\\\"key\\\":\\\"$aa\\\""

        # set query
        echo ${FUNCNAME[0]}

        ## query sample
        # '{"Args":["MintByPartition","{\"partition\":\"imsyToken\",\"amount\":100}"]}'
        param="{\"Args\":[\"${FUNCNAME[0]}\",\"{$string}\"]}"
        echo $param

        # set
        # set -x

        ## set env
        export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/Admin@org${ORG_NUM}.example.com/msp"

        echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
        ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/Bulk.log

        { set +x; } 2>/dev/null
        cat ${LOG_DIR}/Bulk.log
        echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    done

}

function main() {

    # GetData
    # InitLedger
    # sleep 3

    IsInit --ch mychannel-all --p org2 --p org1 --p org3
    sleep 3

    # BulkCreateWallet
    # sleep 3
    # BulkCreateWallet2
    # sleep 3

    # Init
    # sleep 3
    # org1
    # sleep 3
    # CreateWallet -u Org1User1 -p mediumToken -a 50
    # sleep 3
    # CreateWallet -u Org1User2 -p mediumToken -a 50
    # sleep 3
    # org2
    # sleep 3
    # CreateWallet -u Org2User1 -p mediumToken -a 50
    # sleep 3
    # CreateWallet -u Org2User2 -p mediumToken -a 50
    # sleep 3
    # org1
    # sleep 3
    # IssueToken -u Org1User1 -p mediumToken
    # sleep 3
    # org1
    # sleep 3
    # DistributeToken -u Org1User1 -p mediumToken -r Org1User1 -r Org1User2 -r Org2User1
    # sleep 3

    # # IssueToken -u Org1User1 -p mediumToken
    # # sleep 3
    # CreateWallet -u Org1User1 -p mediumToken -a 50
    # sleep 3
    # # # MintByPartition -u Org1User1 -p mediumToken -a 50
    # # # sleep 3

    # CreateWallet -u Org1User2 -p mediumToken -a 50
    # sleep 3
    # # MintByPartition -u Org1User2 -p mediumToken -a
    # # sleep 31

    # # org1
    # # sleep 3
    # # TotalSupplyByPartition -p mediumToken
    # # sleep 3

    # # # MintByPartition -u Org1User1 -p mediumToken -a 50
    # # # sleep 3
    # # # MintByPartition -u Org1User1 -p mediumToken -a 50
    # # # sleep 3
    # # # MintByPartition -u Org1User1 -p mediumToken -a 50
    # # # sleep 3

    # # # BalanceOfByPartition -u Org2User1 -p mediumToken
    # # # sleep 3
    # # # BalanceOfByPartition -u Org1User1 -p mediumToken
    # # # sleep 3

    # # org2
    # # sleep 3

    # # # BalanceOfByPartition -u Org1User1 -p mediumToken
    # # # sleep 3
    # # # BalanceOfByPartition -u Org1User2 -p mediumToken
    # # # sleep 3

    # org2
    # sleep 3
    # CreateWallet -u Org2User1 -p mediumToken -a 50
    # sleep 3
    # CreateWallet -u Org2User2 -p mediumToken -a 50
    # sleep 3
    # MintByPartition -u Org2User1 -p mediumToken -a 50
    # sleep 3

    # GetHolderList -p mediumToken

    # org2
    # sleep 3
    # AirDrop -u Org2User2 -p mediumToken -r Org1User1 -r Org1User2 -r Org2User1
    # sleep 3

    # org1
    # sleep 3
    # BurnByPartition -u Org1User1 -p mediumToken -a 5
    # sleep 3

    # TotalSupply
    # sleep 3
    # TotalSupplyByPartition -p mediumToken
    # sleep 3

    # org1
    # sleep 3
    # TransferByPartition -u Org1User1 -r Org1User2 -p mediumToken -a 2
    # sleep 3
    # BalanceOfByPartition -u Org1User1 -p mediumToken
    # sleep 3

    # org1
    # sleep 3
    # ApproveByPartition -u Org1User1 -s Org1User2 -p mediumToken -a 10
    # sleep 3
    # IncreaseAllowanceByPartition -u Org1User1 -s Org1User2 -p mediumToken -a 100
    # sleep 3
    # DecreaseAllowanceByPartition -u Org1User1 -s Org1User2 -p mediumToken -a 5
    # sleep 3
    # AllowanceByPartition -u Org1User1 -o Org1User1 -s Org1User2 -p mediumToken
    # sleep 3

    # TransferFromByPartition -u Org1User2 -f Org1User1 -t Org1User2 -p mediumToken -a 10
    # sleep 3

    # org2
    # sleep 3
    # GetTokenWalletList -u Org2User1 -b "" -p 10
    # sleep 3
}

function verifyResult() {
    if [ $1 -ne 0 ]; then
        echo -e "$2"
        exit 1
    fi
}

main

# function GetID() {

#     # set query
#     echo ${FUNCNAME[0]}

#     param="{\"Args\":[\"${FUNCNAME[0]}\"]}"
#     echo $param

#     # set
#     set -x

#     # set env
#     export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$1@org${ORG_NUM}.example.com/msp"

#     echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
#     ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/$1_ID.log

#     { set +x; } 2>/dev/null
#     cat ${LOG_DIR}/$1_ID.log
#     echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
# }

# function GetMSPID() {

#     # set query
#     echo ${FUNCNAME[0]}

#     param="{\"Args\":[\"${FUNCNAME[0]}\"]}"
#     echo $param

#     # set
#     set -x

#     # set env
#     export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/$1@org${ORG_NUM}.example.com/msp"

#     echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
#     ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/$1_MSPID.log

#     { set +x; } 2>/dev/null
#     cat ${LOG_DIR}/$1_MSPID.log
#     echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
# }
