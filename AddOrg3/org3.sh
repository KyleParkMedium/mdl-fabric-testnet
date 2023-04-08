#!/bin/bash
export TEST_NETWORK_HOME="/Users/park/code/mdl-fabric-testnet"
export ORG3_DIR="/Users/park/code/mdl-fabric-testnet/org3"
export BIN_DIR="${TEST_NETWORK_HOME}/bin"
export CA_BIN_DIR="${TEST_NETWORK_HOME}/ca-bin"
export LOG_DIR="${TEST_NETWORK_HOME}/log"

# Config Path
export FABRIC_CFG_PATH=${ORG3_DIR}/config

export CHANNEL_NAME="org3channel"
CHAINCODE_NAME="ERC20"
# MAX_RETRY="10"
DELAY="$2"
: ${DELAY:="3"}
MAX_RETRY="$3"
: ${MAX_RETRY:="4"}
VERBOSE="$4"
: ${VERBOSE:="false"}

# function initEnv() {
# }

function runCaServer() {
    docker-compose -f "${ORG3_DIR}/docker/docker-org3-ca.yaml" up -d 2>&1
}

function enroll() {

    mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/

    export FABRIC_CA_CLIENT_HOME=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/

    Org3_address="fabric-ca/org3/tls-cert.pem"

    echo "Enrolling the CA admin"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client enroll -u https://admin:adminpw@localhost:6054 --caname ca-org3 --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org3_address}
    { set +x; } 2>/dev/null

    echo 'NodeOUs:
    Enable: true
    ClientOUIdentifier:
        Certificate: cacerts/localhost-6054-ca-org3.pem
        OrganizationalUnitIdentifier: client
    PeerOUIdentifier:
        Certificate: cacerts/localhost-6054-ca-org3.pem
        OrganizationalUnitIdentifier: peer
    AdminOUIdentifier:
        Certificate: cacerts/localhost-6054-ca-org3.pem
        OrganizationalUnitIdentifier: admin
    OrdererOUIdentifier:
        Certificate: cacerts/localhost-6054-ca-org3.pem
        OrganizationalUnitIdentifier: orderer' >${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/msp/config.yaml

    echo "Registering peer0"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client register --caname ca-org3 --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org3_address}
    { set +x; } 2>/dev/null

    echo "Registering user1"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client register --caname ca-org3 --id.name org3user1 --id.secret org3user1pw --id.type client --id.attrs '"hf.Registrar.Roles=client"' --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org3_address}
    { set +x; } 2>/dev/null

    echo "Registering the org admin"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client register --caname ca-org3 --id.name org3admin --id.secret org3adminpw --id.type admin --id.attrs '"hf.Registrar.Roles=admin",hf.Revoker=true' --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org3_address}
    { set +x; } 2>/dev/null

    echo "Generating the peer0 msp"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client enroll -u https://peer0:peer0pw@localhost:6054 --caname ca-org3 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/msp --csr.hosts peer0.org3.example.com --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org3_address}
    { set +x; } 2>/dev/null

    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/msp/config.yaml

    echo "Generating the peer0-tls certificates"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client enroll -u https://peer0:peer0pw@localhost:6054 --caname ca-org3 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls --enrollment.profile tls --csr.hosts peer0.org3.example.com --csr.hosts localhost --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org3_address}
    { set +x; } 2>/dev/null

    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/signcerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/server.crt
    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/keystore/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/server.key

    mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/msp/tlscacerts
    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/msp/tlscacerts/ca.crt

    mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/tlsca
    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/tlsca/tlsca.org3.example.com-cert.pem

    mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/ca
    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/msp/cacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/ca/ca.org3.example.com-cert.pem

    ## create client
    echo "Generating the user1 msp"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client enroll -u https://org3user1:org3user1pw@localhost:6054 --caname ca-org3 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/users/Org3User1@org3.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org3_address}
    { set +x; } 2>/dev/null

    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/users/Org3User1@org3.example.com/msp/config.yaml

    echo "Generating the org admin msp"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client enroll -u https://org3admin:org3adminpw@localhost:6054 --caname ca-org3 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org3_address}
    { set +x; } 2>/dev/null

    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp/config.yaml
}

# configtx.yaml 필요
function createGenesisBlock() {
    echo "Generating channel genesis block '${CHANNEL_NAME}.block'"

    set -x
    ${BIN_DIR}/configtxgen -profile Org3MakeOrderer -outputBlock ${ORG3_DIR}/channel-artifacts/genesis.block -channelID system-channel

    res=$?
    { set +x; } 2>/dev/null
    verifyResult $res "Failed to generate channel configuration transaction..."
}

function startNode() {
    # docker-compose -f "${ORG3_DIR}/docker/docker-org3.yaml" -f "${ORG3_DIR}/docker/docker-org3-couch.yaml" up -d 2>&1
    docker-compose -f "${ORG3_DIR}/docker/docker-org3.yaml" up -d 2>&1
}

# configtx.yaml 필요
function createChannelTx() {
    CHANNEL_NAME=$1

    set -x
    ${BIN_DIR}/configtxgen -profile Org3Make -outputCreateChannelTx ${ORG3_DIR}/channel-artifacts/${CHANNEL_NAME}/${CHANNEL_NAME}.tx -channelID ${CHANNEL_NAME}

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

function start() {
    while :; do
        if [ ! -f "organizations/fabric-ca/org3/tls-cert.pem" ]; then
            sleep 1
        else
            break
        fi
    done

    enroll
    echo "finished to registerEnroll(create org3)"
    sleep 1

}

function main() {
    runCaServer
    echo "finished to run CA-Org3"
    sleep 1

    start
    sleep 1

    # createGenesisBlock
    # echo "finished to create genesis block(channelTx)"
    # sleep 1

    # startNode
    # echo "waiting for starting org3"
    # sleep 5

    # createChannelTx org3channel
    # echo "finished to create channel tx"
    # sleep 1

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
