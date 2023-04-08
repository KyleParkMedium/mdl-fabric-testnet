#!/bin/bash
export TEST_NETWORK_HOME="/Users/park/code/mdl-fabric-testnet"
export CHAINCODE_DIR="${TEST_NETWORK_HOME}/scripts/chaincode"

CHANNEL_NAME="mychannel0"
CHAINCODE_NAME="Random"
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
# : ${CHAINCODE_NAME:="Random"}
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

function Minter() {

    org1

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
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"

    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/Check.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Check.log
    cp ${LOG_DIR}/Check.log ${LOG_DIR}/Response.log
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
            ;;
        -h | --tokenHolder)
            shift
            tokenHolder0=$1
            # tokenHolder=$(cat ./log/${tokenHolder0}_Address.log)
            tokenHolder=$(cat ${TEST_NETWORK_HOME}/log/${tokenHolder0}_Address.log)
            string+="\\\"tokenHolder\\\":\\\"$tokenHolder\\\","
            ;;
        -O | --operator)
            shift
            operator0=$1
            # tokenHolder=$(cat ./log/${tokenHolder0}_Address.log)
            operator=$(cat ${TEST_NETWORK_HOME}/log/${operator0}_Address.log)
            string+="\\\"operator\\\":\\\"$operator\\\","
            ;;
        -o | --owner)
            shift
            owner0=$1
            owner=$(cat ${TEST_NETWORK_HOME}/log/${owner0}_Address.log)
            string+="\\\"owner\\\":\\\"$owner\\\","
            ;;
        -s | --spender)
            shift
            spender0=$1
            spender=$(cat ${TEST_NETWORK_HOME}/log/${spender0}_Address.log)
            string+="\\\"spender\\\":\\\"$spender\\\","
            ;;
        -f | --from)
            shift
            from0=$1
            from=$(cat ${TEST_NETWORK_HOME}/log/${from0}_Address.log)
            string+="\\\"from\\\":\\\"$from\\\","
            ;;
        -t | --to)
            shift
            to0=$1
            to=$(cat ${TEST_NETWORK_HOME}/log/${to0}_Address.log)
            string+="\\\"to\\\":\\\"$to\\\","
            ;;
        -r | --recipient)
            shift
            recipient0=$1
            recipient=$(cat ${TEST_NETWORK_HOME}/log/${recipient0}_Address.log)
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
            INT=$((amount))
            string+="\\\"amount\\\":$INT,"
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
        *)
            usage
            ;;
        esac
        shift
    done
}

set_options "$@"

$function
