#!/bin/bash
export TEST_NETWORK_HOME="/Users/park/code/mdl-fabric-testnet"
export ORG3_DIR="/Users/park/code/mdl-fabric-testnet/new"
export BIN_DIR="${TEST_NETWORK_HOME}/bin"
export CA_BIN_DIR="${TEST_NETWORK_HOME}/ca-bin"
export LOG_DIR="${TEST_NETWORK_HOME}/log"

# Config Path
export FABRIC_CFG_PATH=${ORG3_DIR}/config

export CHANNEL_NAME="mychannel0"
CHAINCODE_NAME="ERC20"
# MAX_RETRY="10"
DELAY="$2"
: ${DELAY:="3"}
MAX_RETRY="$3"
: ${MAX_RETRY:="4"}
VERBOSE="$4"
: ${VERBOSE:="false"}

# configtx.yaml 필요
function createGenesisBlock() {
    echo "Generating channel genesis block '${CHANNEL_NAME}.block'"

    set -x
    ${BIN_DIR}/configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ${TEST_NETWORK_HOME}/channel-artifacts/genesis.block -channelID system-channel

    res=$?
    { set +x; } 2>/dev/null
    verifyResult $res "Failed to generate channel configuration transaction..."
}

function startNode() {
    # docker-compose -f "${ORG3_DIR}/docker/docker-org3.yaml" -f "${ORG3_DIR}/docker/docker-org3-couch.yaml" up -d 2>&1
    docker-compose -f "${ORG3_DIR}/docker/docker-compose-node.yaml" up -d 2>&1
}

# configtx.yaml 필요
function createChannelTx() {
    CHANNEL_NAME=$1

    set -x
    ${BIN_DIR}/configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CHANNEL_NAME}.tx -channelID ${CHANNEL_NAME}

    res=$?
    { set +x; } 2>/dev/null
    verifyResult $res "Failed to generate channel configuration transaction..."
}

## org3 create channel org3channel
# core.yaml 필요(안에 내용을 읽는지는 모르겠음)
# 채널 생성시 오더러는 컨소시엄(이름, 안에 구성 노드)로 판단함.
# 다시 말한다면 이름, 노드만 같다면 다른 config 파일로 실행해도 동작한다는 소리.
function createChannel() {

    # export CORE_PEER_TLS_ENABLED=true
    # export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
    # export CORE_PEER_LOCALMSPID="Org3MSP"
    # export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt"
    # export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp"
    # export CORE_PEER_ADDRESS="localhost:6050"

    export CORE_PEER_TLS_ENABLED=true
    export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp"
    export CORE_PEER_ADDRESS="localhost:8050"

    CHANNEL_NAME=$1
    # Poll in case the raft leader is not set yet
    local rc=1
    local COUNTER=1
    while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
        sleep $DELAY
        set -x
        ${BIN_DIR}/peer channel create -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f ${ORG3_DIR}/channel-artifacts/${CHANNEL_NAME}/${CHANNEL_NAME}.tx --outputBlock ${ORG3_DIR}/channel-artifacts/${CHANNEL_NAME}/${CHANNEL_NAME}.block --tls --cafile $ORDERER_CA >&${LOG_DIR}/${CHANNEL_NAME}.log

        res=$?
        { set +x; } 2>/dev/null
        let rc=$res
        COUNTER=$(expr $COUNTER + 1)
    done
    cat ${LOG_DIR}/${CHANNEL_NAME}.log
    verifyResult $res "Channel creation failed"
}

function joinChannel() {

    $2

    CHANNEL_NAME=$1
    local rc=1
    local COUNTER=1
    ## Sometimes Join takes time, hence retry
    while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
        sleep $DELAY
        set -x
        ${BIN_DIR}/peer channel join -b ${ORG3_DIR}/channel-artifacts/${CHANNEL_NAME}/${CHANNEL_NAME}.block >&${LOG_DIR}/${CHANNEL_NAME}.log
        res=$?
        { set +x; } 2>/dev/null
        let rc=$res
        COUNTER=$(expr $COUNTER + 1)
    done
    cat ${LOG_DIR}/${CHANNEL_NAME}.log
    verifyResult $res "After $MAX_RETRY attempts, peer0.org${ORG} has failed to join channel '$CHANNEL_NAME' "
}

function org1() {
    ############ Peer Vasic Setting ############
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_ID="peer0.org1.example.com"
    export CORE_PEER_ENDORSER_ENABLED=true
    export CORE_PEER_ADDRESS="peer0.org1.example.com:7050"
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"
}

function org2() {
    ############ Peer Vasic Setting ############
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_ID="peer0.org2.example.com"
    export CORE_PEER_ENDORSER_ENABLED=true
    export CORE_PEER_ADDRESS="peer0.org2.example.com:8050"
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp"
    export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"
}

function org3() {
    ############ Peer Vasic Setting ############
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_ID="peer0.org3.example.com"
    export CORE_PEER_ENDORSER_ENABLED=true
    export CORE_PEER_ADDRESS="peer0.org3.example.com:6050"
    export CORE_PEER_LOCALMSPID="Org3MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp"
    export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"
}

function main() {

    createGenesisBlock
    echo "finished to create genesis block(channelTx)"
    sleep 1

    startNode
    echo "waiting for starting org3"
    sleep 5

    createChannelTx mychannel0
    echo "finished to create channel tx"
    sleep 1

    # createChannel org3channel
    # echo "finished to create channel(org3이 생성)"
    # sleep 1

    # joinChannel org3channel org1
    # echo "finished to join channel org1"
}

function verifyResult() {
    if [ $1 -ne 0 ]; then
        echo -e "$2"
        exit 1
    fi
}

main
