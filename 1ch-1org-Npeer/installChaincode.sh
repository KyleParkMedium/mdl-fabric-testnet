#!/bin/bash
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
# CHAINCODE_INIT_REQUIRED="--init-required"
CHAINCODE_INIT_REQUIRED=""
CHAINCODE_END_POLICY="$8"
: ${CHAINCODE_END_POLICY:=""}
CHAINCODE_COLL_CONFIG="$9"
: ${CHAINCODE_COLL_CONFIG:=""}

export TEST_NETWORK_HOME=$(dirname $(readlink -f $0))
export BIN_DIR="${TEST_NETWORK_HOME}/bin"
export LOG_DIR="${TEST_NETWORK_HOME}/log"

function org1() {
    export FABRIC_CFG_PATH=${TEST_NETWORK_HOME}/config
    export HOST="peer0.org1.example.com"
    export ORG="Org1"
    ############ Peer Vasic Setting ############
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_ID="peer0.org1.example.com"
    export CORE_PEER_ENDORSER_ENABLED=true
    export CORE_PEER_ADDRESS="peer0.org1.example.com:7051"
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"
}

function changePeer() {
    peer=$1

    if [ "${peer}" = "peer0" ]; then
        export PORT=7051
    elif [ "${peer}" = "peer1" ]; then
        export PORT=6051
    elif [ "${peer}" = "peer2" ]; then
        export PORT=5051
    elif [ "${peer}" = "peer3" ]; then
        export PORT=4051
    elif [ "${peer}" = "peer4" ]; then
        export PORT=3051
    elif [ "${peer}" = "peer5" ]; then
        export PORT=2051
    fi

    export FABRIC_CFG_PATH=${TEST_NETWORK_HOME}/config
    export HOST="${peer}.org1.example.com"
    export ORG="Org1"

    ############ Peer Vasic Setting ############
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_ID="${peer}.org1.example.com"
    export CORE_PEER_ENDORSER_ENABLED=true
    export CORE_PEER_ADDRESS="${peer}.org1.example.com:${PORT}"
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/${peer}.org1.example.com/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"
}

function setChaincode() {
    if [ -d ${TEST_NETWORK_HOME}/chaincodes/STO ]; then
        rm -rf ${TEST_NETWORK_HOME}/chaincodes/STO
        mkdir -p ${TEST_NETWORK_HOME}/chaincodes/STO
        cp -r "/Users/park/code/mdl-chaincodes" ${TEST_NETWORK_HOME}/chaincodes/STO
        mv ${TEST_NETWORK_HOME}/chaincodes/STO/mdl-chaincodes ${TEST_NETWORK_HOME}/chaincodes/STO/go
    else
        mkdir -p ${TEST_NETWORK_HOME}/chaincodes/STO
        cp -r "/Users/park/code/mdl-chaincodes" ${TEST_NETWORK_HOME}/chaincodes/STO
        mv ${TEST_NETWORK_HOME}/chaincodes/STO/mdl-chaincodes ${TEST_NETWORK_HOME}/chaincodes/STO/go
    fi
}

function install() {

    set -x
    ${BIN_DIR}/peer lifecycle chaincode install ${TEST_NETWORK_HOME}/packages/${CHAINCODE_NAME}.tar.gz >&${LOG_DIR}/${ORG}-${CHANNEL_NAME}-chaincode.log
    res=$?
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${ORG}-${CHANNEL_NAME}-chaincode.log
    verifyResult $res "Chaincode installation on peer0.org${ORG} has failed"
    echo "Chaincode is installed on peer0.org1"

}

function approve() {

    export PEER_CONN_PARMS="${PEER_CONN_PARMS} --peerAddresses ${CORE_PEER_ADDRESS}"
    TLSINFO=$(eval echo "--tlsRootCertFiles \$CORE_PEER_TLS_ROOTCERT_FILE")
    export PEER_CONN_PARMS="${PEER_CONN_PARMS} ${TLSINFO}"

    set -x
    ${BIN_DIR}/peer lifecycle chaincode queryinstalled >&${LOG_DIR}/${ORG}-${CHANNEL_NAME}-${CHAINCODE_VERSION}-chaincode.log
    res=$?
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${ORG}-${CHANNEL_NAME}-${CHAINCODE_VERSION}-chaincode.log
    PACKAGE_ID=$(sed -n "/${CHAINCODE_NAME}_${CHAINCODE_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" ${LOG_DIR}/${ORG}-${CHANNEL_NAME}-${CHAINCODE_VERSION}-chaincode.log)
    verifyResult $res "Query installed on peer0.org1 has failed"
    echo "Query installed successful on peer0.org1 on channel"

    set -x
    ${BIN_DIR}/peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --package-id ${PACKAGE_ID} --sequence ${CHAINCODE_SEQUENCE} ${CHAINCODE_INIT_REQUIRED} ${CHAINCODE_END_POLICY} ${CHAINCODE_COLL_CONFIG} >&${LOG_DIR}/${ORG}-${CHANNEL_NAME}-chaincode.log
    res=$?
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${ORG}-${CHANNEL_NAME}-chaincode.log
    verifyResult $res "Chaincode definition approved on peer0.org1 on channel '${CHANNEL_NAME}' failed"
    echo "Chaincode definition approved on peer0.org1 on channel '${CHANNEL_NAME}'"
}

function checkcommit() {
    local rc=1
    local COUNTER=1
    # continue to poll
    # we either get a successful response, or reach MAX RETRY
    while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
        sleep $DELAY
        echo "Attempting to check the commit readiness of the chaincode definition on peer0.org1, Retry after $DELAY seconds."
        set -x
        ${BIN_DIR}/peer lifecycle chaincode checkcommitreadiness --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --sequence ${CHAINCODE_SEQUENCE} ${CHAINCODE_INIT_REQUIRED} ${CHAINCODE_END_POLICY} ${CHAINCODE_COLL_CONFIG} --output json >&${LOG_DIR}/${ORG}-${CHANNEL_NAME}-chaincode.log
        res=$?
        { set +x; } 2>/dev/null
        let rc=0
        for var in "$@"; do
            grep "$var" ${LOG_DIR}/${ORG}-${CHANNEL_NAME}-chaincode.log &>/dev/null || let rc=1
        done
        COUNTER=$(expr $COUNTER + 1)
    done
    cat ${LOG_DIR}/${ORG}-${CHANNEL_NAME}-chaincode.log
    if test $rc -eq 0; then
        echo "Checking the commit readiness of the chaincode definition successful on peer0.org1 on channel '${CHANNEL_NAME}'"
    else
        echo "After $MAX_RETRY attempts, Check commit readiness result on peer0.org1 is INVALID!"
        exit 1
    fi
}

function commit() {

    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    set -x
    ${BIN_DIR}/peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} $PEER_CONN_PARMS --version ${CHAINCODE_VERSION} --sequence ${CHAINCODE_SEQUENCE} ${CHAINCODE_INIT_REQUIRED} ${CHAINCODE_END_POLICY} ${CHAINCODE_COLL_CONFIG} >&${LOG_DIR}/${ORG}-${CHANNEL_NAME}-chaincode.log
    res=$?
    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${ORG}-${CHANNEL_NAME}-chaincode.log
    verifyResult $res "Chaincode definition commit failed on peer0.org1 on channel '${CHANNEL_NAME}' failed"
    echo "Chaincode definition committed on channel '${CHANNEL_NAME}'"

    EXPECTED_RESULT="Version: ${CHAINCODE_VERSION}, Sequence: ${CHAINCODE_SEQUENCE}, Endorsement Plugin: escc, Validation Plugin: vscc"
    echo "Querying chaincode definition on peer0.org$ on channel '${CHANNEL_NAME}'..."
    local rc=1
    local COUNTER=1
    # continue to poll
    # we either get a successful response, or reach MAX RETRY

    while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
        sleep $DELAY
        echo "Attempting to Query committed status on peer0.org1, Retry after $DELAY seconds."
        set -x
        ${BIN_DIR}/peer lifecycle chaincode querycommitted --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} >&${LOG_DIR}/${ORG}-${CHANNEL_NAME}-chaincode.log
        res=$?
        { set +x; } 2>/dev/null
        test $res -eq 0 && VALUE=$(cat ${LOG_DIR}/${ORG}-${CHANNEL_NAME}-chaincode.log | grep -o '^Version: '$CHAINCODE_VERSION', Sequence: [0-9]*, Endorsement Plugin: escc, Validation Plugin: vscc')
        test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
        COUNTER=$(expr $COUNTER + 1)
    done
    cat ${LOG_DIR}/${ORG}-${CHANNEL_NAME}-chaincode.log
    if test $rc -eq 0; then
        echo "Query chaincode definition successful on peer0.org1 on channel '${CHANNEL_NAME}'"
        ${BIN_DIR}/peer chaincode list --installed
        ${BIN_DIR}/peer chaincode list --instantiated -C ${CHANNEL_NAME}
        PEER_CONN_PARMS=""
    else
        echo "After $MAX_RETRY attempts, Query chaincode definition result on peer0.org1 is INVALID!"
        exit 1
    fi

}

function deployChaincode() {

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        --v)
            export CHAINCODE_VERSION="$2"
            shift 2
            ;;
        --s)
            export CHAINCODE_SEQUENCE="$2"
            shift 2
            ;;
        --cc)
            org1
            export CHAINCODE_NAME="$2"
            pushd ${TEST_NETWORK_HOME}/chaincodes/${CHAINCODE_NAME}/go
            GO111MODULE=on go mod vendor
            popd
            echo "Finished vendoring Go dependencies"

            set -x
            ${BIN_DIR}/peer lifecycle chaincode package ${TEST_NETWORK_HOME}/packages/${CHAINCODE_NAME}.tar.gz --path ${TEST_NETWORK_HOME}/chaincodes/${CHAINCODE_NAME}/go --lang "golang" --label ${CHAINCODE_NAME}_${CHAINCODE_VERSION} >&${LOG_DIR}/${CHAINCODE_NAME}-chaincode.log
            res=$?
            { set +x; } 2>/dev/null
            cat ${LOG_DIR}/${CHAINCODE_NAME}-chaincode.log
            verifyResult $res "Chaincode packaging has failed"
            echo "Chaincode is packaged"

            shift 2
            ;;
        --ch)
            export CHANNEL_NAME="$2"
            shift 2
            ;;
        --i)
            changePeer $2
            install
            sleep 1
            shift 2
            ;;
        --ap)
            $2
            approve
            sleep 1
            shift 2
            ;;
        --check)
            $2
            checkcommit
            sleep 1
            shift 2
            ;;
        --c)
            $2
            commit
            sleep 1
            shift 2
            ;;
        *)
            echo "Unknown parameter: $1"
            exit 1
            ;;
        esac
    done
}

function main() {
    # setChaincode
    # sleep 3

    deployChaincode --v v7 --s 2 --cc Dev --ch mychannel0 --i peer0 --i peer1 --ap org1 --check org1 --c org1
    echo "finished to deploy chaincode"
    sleep 5

}

function verifyResult() {
    if [ $1 -ne 0 ]; then
        echo -e "$2"
        exit 1
    fi
}

main
