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

export TEST_NETWORK_HOME=$(dirname $(readlink -f $0))
export BIN_DIR="${TEST_NETWORK_HOME}/bin"
# CA-BIN
export CA_BIN_DIR="${TEST_NETWORK_HOME}/ca-bin"
export LOG_DIR="${TEST_NETWORK_HOME}/log"
export FABRIC_CFG_PATH=${TEST_NETWORK_HOME}/config

. ${TEST_NETWORK_HOME}/scripts/utils/utils.sh

function startCA() {

    export FABRIC_CA_HOME=${TEST_NETWORK_HOME}/organizations/fabric-ca-server
    export FABRIC_CA_SERVER_CA_NAME="ca"
    export FABRIC_CA_SERVER_TLS_ENABLED=true
    export FABRIC_CA_SERVER_PORT="9999"
    export FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS="0.0.0.0:7443"

    nohup sh -c '${CA_BIN_DIR}/fabric-ca-server start -b admin:adminpw -d' >${LOG_DIR}/fabric-ca-server.log 2>&1 &
    echo $!
}

COMPOSE_FILE_CA=docker/docker-compose-ca.yaml
COMPOSE_FILE_BASE=docker/docker-compose-test-net.yaml
COMPOSE_FILE_COUCH=docker/docker-compose-couch.yaml

function registerEnroll() {

    docker-compose -f $COMPOSE_FILE_CA up -d 2>&1

    ${TEST_NETWORK_HOME}/scripts/utils/registerEnroll.sh
    # ${TEST_NETWORK_HOME}/aa.sh
}

function createGenesisBlock() {
    PROFILE_NAME=$1
    # createChannelTx
    echo "Generating channel genesis block '${CHANNEL_NAME}.block'"
    set -x
    ${BIN_DIR}/configtxgen -profile ${PROFILE_NAME} -outputBlock ${TEST_NETWORK_HOME}/channel-artifacts/${PROFILE_NAME}/genesis.block -channelID "system-channel"
    res=$?
    { set +x; } 2>/dev/null
    verifyResult $res "Failed to generate channel configuration transaction..."
}

function createChannelTx() {
    CHANNEL_NAME=$1
    PROFILE_NAME=$2
    set -x
    ${BIN_DIR}/configtxgen -profile ${PROFILE_NAME} -outputCreateChannelTx ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
    res=$?
    { set +x; } 2>/dev/null
    verifyResult $res "Failed to generate channel configuration transaction..."
}

function startNode() {
    # start Orderer, Peer Node
    docker-compose -f $COMPOSE_FILE_COUCH -f $COMPOSE_FILE_BASE up -d 2>&1
    # docker-compose -f $COMPOSE_FILE_BASE up -d 2>&1
}

function createChannel() {
    $2
    CHANNEL_NAME=$1
    # Poll in case the raft leader is not set yet
    local rc=1
    local COUNTER=1
    while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
        sleep $DELAY
        set -x
        # ${BIN_DIR}/peer channel create -o localhost:9050 --ordererTLSHostnameOverride orderer1.example.com -c $CHANNEL_NAME -f ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CHANNEL_NAME}.tx --outputBlock ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CHANNEL_NAME}.block --tls --cafile $ORDERER_CA >&${LOG_DIR}/${CHANNEL_NAME}.log
        # ${BIN_DIR}/peer channel create -o localhost:9050 -o localhost:5050 --ordererTLSHostnameOverride orderer1.example.com --ordererTLSHostnameOverride orderer2.example.com -c $CHANNEL_NAME -f ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CHANNEL_NAME}.tx --outputBlock ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CHANNEL_NAME}.block --tls --cafile $ORDERER_CA --cafile $ORDERER_CA2 >&${LOG_DIR}/${CHANNEL_NAME}.log
        # ${BIN_DIR}/peer channel create -o orderer1.example.com:9050 --ordererTLSHostnameOverride orderer1.example.com -o orderer2.example.com:5050 --ordererTLSHostnameOverride orderer2.example.com -c $CHANNEL_NAME -f ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CHANNEL_NAME}.tx --outputBlock ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CHANNEL_NAME}.block --tls --cafile $ORDERER_CA --cafile $ORDERER_CA2 >&${LOG_DIR}/${CHANNEL_NAME}.log
        ${BIN_DIR}/peer channel create -o localhost:9050 --ordererTLSHostnameOverride orderer1.example.com -o localhost:5050 --ordererTLSHostnameOverride orderer2.example.com -c $CHANNEL_NAME -f ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CHANNEL_NAME}.tx --outputBlock ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CHANNEL_NAME}.block --tls --cafile $ORDERER_CA --cafile $ORDERER_CA2 >&${LOG_DIR}/${CHANNEL_NAME}.log

        { set +x; } 2>/dev/null
        res=$?
        let rc=$res
        COUNTER=$(expr $COUNTER + 1)
    done
    cat ${LOG_DIR}/${CHANNEL_NAME}.log
    verifyResult $res "Channel creation failed"
}

## 조인 채널에서 config 바뀜
function joinChannel() {
    $2
    CHANNEL_NAME=$1
    local rc=1
    local COUNTER=1
    ## Sometimes Join takes time, hence retry
    while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
        sleep $DELAY
        set -x
        ${BIN_DIR}/peer channel join -b ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CHANNEL_NAME}.block >&${LOG_DIR}/$2-${CHANNEL_NAME}.log
        res=$?
        { set +x; } 2>/dev/null
        let rc=$res
        COUNTER=$(expr $COUNTER + 1)
    done
    cat ${LOG_DIR}/$2-${CHANNEL_NAME}.log
    verifyResult $res "After $MAX_RETRY attempts, peer0.org${ORG} has failed to join channel '$CHANNEL_NAME' "
}

function setAnchorPeer() {
    $2
    CHANNEL_NAME=$1
    echo "Fetching channel config for channel $CHANNEL_NAME"
    echo "Fetching the most recent configuration block for the channel"
    set -x
    ${BIN_DIR}/peer channel fetch config ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/config_block.pb -o orderer.example.com:9050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
    { set +x; } 2>/dev/null

    echo "Decoding config block to JSON and isolating config to ${ORG}MSP"
    set -x
    ${BIN_DIR}/configtxlator proto_decode --input ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/config_block.pb --type common.Block --output "${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${ORG}MSP.json"
    { set +x; } 2>/dev/null

    cat "${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${ORG}MSP.json" | jq .data.data[0].payload.data.config >"${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${ORG}MSPconfig.json"
    set -x

    echo "Generating anchor peer update transaction for Org${ORG} on channel $CHANNEL_NAME"

    # set Anchor Peer Config
    set -x
    # Modify the configuration to append the anchor peer
    jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": '$PORT'}]},"version": "0"}}' ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CORE_PEER_LOCALMSPID}config.json >${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CORE_PEER_LOCALMSPID}modified_config.json
    { set +x; } 2>/dev/null

    set -x
    ${BIN_DIR}/configtxlator proto_encode --input "${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${ORG}MSPconfig.json" --type common.Config --output ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/original_config.pb
    ${BIN_DIR}/configtxlator proto_encode --input "${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${ORG}MSPmodified_config.json" --type common.Config --output ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/modified_config.pb
    ${BIN_DIR}/configtxlator compute_update --channel_id "${CHANNEL_NAME}" --original ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/original_config.pb --updated ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/modified_config.pb --output ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/config_update.pb
    ${BIN_DIR}/configtxlator proto_decode --input ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/config_update.pb --type common.ConfigUpdate --output ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/config_update.json
    echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/config_update.json)'}}}' | jq . >${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/config_update_in_envelope.json
    ${BIN_DIR}/configtxlator proto_encode --input ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/config_update_in_envelope.json --type common.Envelope --output "${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${ORG}MSPanchors.tx"
    { set +x; } 2>/dev/null

    # channel update
    # tx파일로 업데이트
    ${BIN_DIR}/peer channel update -o orderer.example.com:9050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA >&${LOG_DIR}/$2-${CHANNEL_NAME}.log
    res=$?
    cat ${LOG_DIR}/$2-${CHANNEL_NAME}.log
    verifyResult $res "Anchor peer update failed"
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
    ${BIN_DIR}/peer lifecycle chaincode approveformyorg -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --package-id ${PACKAGE_ID} --sequence ${CHAINCODE_SEQUENCE} ${CHAINCODE_INIT_REQUIRED} ${CHAINCODE_END_POLICY} ${CHAINCODE_COLL_CONFIG} >&${LOG_DIR}/${ORG}-${CHANNEL_NAME}-chaincode.log
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
    ${BIN_DIR}/peer lifecycle chaincode commit -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} $PEER_CONN_PARMS --version ${CHAINCODE_VERSION} --sequence ${CHAINCODE_SEQUENCE} ${CHAINCODE_INIT_REQUIRED} ${CHAINCODE_END_POLICY} ${CHAINCODE_COLL_CONFIG} >&${LOG_DIR}/${ORG}-${CHANNEL_NAME}-chaincode.log
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
            $2
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

function runBlockExplorer() {
    ${TEST_NETWORK_HOME}/scripts/utils/runBlockExplorer.sh
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
    export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/orderers/orderer1.example.com/tls/ca.crt"
    export ORDERER_CA2="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/orderers/orderer2.example.com/tls/ca.crt"
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
    export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/orderers/orderer1.example.com/tls/ca.crt"
    export ORDERER_CA2="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/orderers/orderer2.example.com/tls/ca.crt"
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

function main() {
    # .gitignore 때문에 한줄 추가해놈 ㅎㅎㅎ.. ㅋ folder check
    mkdir -p log
    mkdir -p packages

    registerEnroll
    echo "finished to registerEnroll(create org1, org2, orderer)"
    sleep 1
    # # createGenesisBlock Org1Org2Org3OrdererGenesis
    # # echo "finished to create genesis block"
    # # sleep 1
    createGenesisBlock Org1Org2OrdererGenesis
    echo "finished to create genesis block"
    sleep 1
    # # # createGenesisBlock Org1Org3OrdererGenesis
    # # # echo "finished to create genesis block"
    # # # sleep 1
    # # # createChannelTx mychannel-all Org1Org2Org3Channel
    # # # echo "finished to create channel tx"
    # # # sleep 1
    createChannelTx mychannel-a Org1Org2Channel
    echo "finished to create channel tx"
    sleep 1
    # # # createChannelTx mychannel-b Org1Org3Channel
    # # # echo "finished to create channel tx"
    # # # sleep 1
    startNode
    echo "waiting for starting orderer, peer node completely"
    sleep 5
    # # # createChannel mychannel-all org1
    # # # echo "finished to create channel(org1이 생성)"
    # # # sleep 1
    createChannel mychannel-a org1
    echo "finished to create channel(org1이 생성)"
    sleep 1
    # # # # createChannel mychannel-b org1
    # # # # echo "finished to create channel(org1이 생성)"
    # # # # sleep 1
    # # # joinChannel mychannel-all org1
    # # # echo "finished to join channel org1"
    # # # sleep 1
    # # # joinChannel mychannel-all org2
    # # # echo "finished to join channel org2"
    # # # sleep 1
    # # # joinChannel mychannel-all org3
    # # # echo "finished to join channel org3"
    # # # sleep 1
    joinChannel mychannel-a org1
    echo "finished to join channel org1"
    sleep 1
    joinChannel mychannel-a org2
    echo "finished to join channel org2"
    sleep 1
    # # # # joinChannel mychannel-b org1
    # # # # echo "finished to join channel org1"
    # # # # sleep 1
    # # # # joinChannel mychannel-b org3
    # # # # echo "finished to join channel org3"
    # # # # sleep 1
    # # # setAnchorPeer mychannel-all org1
    # # # echo "finished to set anchor peer org1"
    # # # sleep 1
    # # setAnchorPeer mychannel-a org2
    # # echo "finished to set anchor peer org2"
    # # sleep 1
    # # # # setAnchorPeer mychannel-b org3
    # # # # echo "finished to set anchor peer org3"
    # # # # sleep 1
    # # # deployChaincode --cc STO --ch mychannel-all --i org1 --i org2 --i org3 --ap org1 --ap org2 --ap org3 --check org1 --check org2 --check org3 --c org1
    # # # echo "finished to deploy chaincode"
    # # # sleep 5
    # # # # deployChaincode --cc STO --ch mychannel-a --ap org1 --ap org2 --check org1 --check org2 --c org1
    # # # # echo "finished to deploy chaincode"
    # # # # sleep 5
    # # # # deployChaincode --cc STO --ch mychannel-b --ap org1 --ap org3 --check org1 --check org3 --c org3
    # # # # echo "finished to deploy chaincode"
    # # # # sleep 5
    # # # # deployChaincode --cc Dev --ch mychannel-all --i org1 --i org2 --i org3 --ap org1 --ap org2 --ap org3 --check org1 --check org2 --check org3 --c org1
    # # # # echo "finished to deploy chaincode"
    # # # # sleep 5
    # # # # deployChaincode --cc Dev --ch mychannel-a --ap org1 --ap org2 --check org1 --check org2 --c org1
    # # # # echo "finished to deploy chaincode"
    # # # # sleep 5
    # # # # deployChaincode --cc Dev --ch mychannel-b --ap org1 --ap org3 --check org1 --check org3 --c org3
    # # # # echo "finished to deploy chaincode"
    # # # # sleep 5

    # # # runBlockExplorer
}

function verifyResult() {
    if [ $1 -ne 0 ]; then
        echo -e "$2"
        exit 1
    fi
}

main
