#!/bin/bash
CHANNEL_NAME="$1"
: ${CHANNEL_NAME:="mychannel"}
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

export TEST_NETWORK_HOME=$(dirname $(readlink -f $0))
export BIN_DIR="${TEST_NETWORK_HOME}/bin"
# CA-BIN
export CA_BIN_DIR="${TEST_NETWORK_HOME}/ca-bin"
export LOG_DIR="${TEST_NETWORK_HOME}/log"
export FABRIC_CFG_PATH=${TEST_NETWORK_HOME}/config

function startCA() {

    export FABRIC_CA_HOME=${TEST_NETWORK_HOME}/organizations/fabric-ca-server
    export FABRIC_CA_SERVER_CA_NAME="ca"
    export FABRIC_CA_SERVER_TLS_ENABLED=true
    export FABRIC_CA_SERVER_PORT="7054"
    export FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS="0.0.0.0:7443"

    nohup sh -c '${CA_BIN_DIR}/fabric-ca-server start -b admin:adminpw -d' > ${LOG_DIR}/fabric-ca-server.log 2>&1 &
    echo $! 
}

function createOrg1() {
    echo "Enrolling the CA admin"
    
    mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/
    
    export FABRIC_CA_CLIENT_HOME=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/

    set -x
    ${CA_BIN_DIR}/fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
    { set +x; } 2>/dev/null

    echo 'NodeOUs:
    Enable: true
    ClientOUIdentifier:
        Certificate: cacerts/localhost-7054-ca.pem
        OrganizationalUnitIdentifier: client
    PeerOUIdentifier:
        Certificate: cacerts/localhost-7054-ca.pem
        OrganizationalUnitIdentifier: peer
    AdminOUIdentifier:
        Certificate: cacerts/localhost-7054-ca.pem
        OrganizationalUnitIdentifier: admin
    OrdererOUIdentifier:
        Certificate: cacerts/localhost-7054-ca.pem
        OrganizationalUnitIdentifier: orderer' >${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/config.yaml
    
    echo "Registering peer0"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client register --caname ca --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
    { set +x; } 2>/dev/null

    echo "Registering user1"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client register --caname ca --id.name user1 --id.secret user1pw --id.type client --id.attrs '"hf.Registrar.Roles=client"' --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
    { set +x; } 2>/dev/null

    echo "Registering user2"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client register --caname ca --id.name user2 --id.secret user2pw --id.type client --id.attrs '"hf.Registrar.Roles=client"' --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
    { set +x; } 2>/dev/null

    echo "Registering user3"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client register --caname ca --id.name user3 --id.secret user3pw --id.type client --id.attrs '"hf.Registrar.Roles=client"' --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
    { set +x; } 2>/dev/null

    echo "Registering the org admin"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client register --caname ca --id.name org1admin --id.secret org1adminpw --id.type admin --id.attrs '"hf.Registrar.Roles=admin",hf.Revoker=true' --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
    { set +x; } 2>/dev/null

    echo "Generating the peer0 msp"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp --csr.hosts peer0.org1.example.com --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
    { set +x; } 2>/dev/null

    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/config.yaml

    echo "Generating the peer0-tls certificates"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls --enrollment.profile tls --csr.hosts peer0.org1.example.com --csr.hosts localhost --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
    { set +x; } 2>/dev/null

    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/signcerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.crt
    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/keystore/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key

    mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/tlscacerts
    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/tlscacerts/ca.crt

    mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/tlsca
    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem

    mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/ca
    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/cacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem

    echo "Generating the user1 msp"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
    { set +x; } 2>/dev/null

    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/config.yaml

    echo "Generating the user2 msp"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client enroll -u https://user2:user2pw@localhost:7054 --caname ca -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/User2@org1.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
    { set +x; } 2>/dev/null

    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/User2@org1.example.com/msp/config.yaml

    echo "Generating the user3 msp"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client enroll -u https://user3:user3pw@localhost:7054 --caname ca -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/User3@org1.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
    { set +x; } 2>/dev/null

    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/User3@org1.example.com/msp/config.yaml

    echo "Generating the org admin msp"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client enroll -u https://org1admin:org1adminpw@localhost:7054 --caname ca -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
    { set +x; } 2>/dev/null

    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/config.yaml
}

function createOrderer() {
    echo "Enrolling the CA admin"
    mkdir -p ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com

    export FABRIC_CA_CLIENT_HOME=${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com

    set -x
    ${CA_BIN_DIR}/fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
    { set +x; } 2>/dev/null

    echo 'NodeOUs:
    Enable: true
    ClientOUIdentifier:
        Certificate: cacerts/localhost-7054-ca.pem
        OrganizationalUnitIdentifier: client
    PeerOUIdentifier:
        Certificate: cacerts/localhost-7054-ca.pem
        OrganizationalUnitIdentifier: peer
    AdminOUIdentifier:
        Certificate: cacerts/localhost-7054-ca.pem
        OrganizationalUnitIdentifier: admin
    OrdererOUIdentifier:
        Certificate: cacerts/localhost-7054-ca.pem
        OrganizationalUnitIdentifier: orderer' >${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/msp/config.yaml

    echo "Registering orderer"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client register --caname ca --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
    { set +x; } 2>/dev/null

    echo "Registering the orderer admin"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client register --caname ca --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
    { set +x; } 2>/dev/null

    echo "Generating the orderer msp"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client enroll -u https://orderer:ordererpw@localhost:7054 --caname ca -M ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp --csr.hosts orderer.example.com --csr.hosts localhost --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
    { set +x; } 2>/dev/null

    cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/config.yaml

    echo "Generating the orderer-tls certificates"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client enroll -u https://orderer:ordererpw@localhost:7054 --caname ca -M ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls --enrollment.profile tls --csr.hosts orderer.example.com --csr.hosts localhost --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
    { set +x; } 2>/dev/null
    
    cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt
    cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/signcerts/* ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
    cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/keystore/* ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key

    mkdir -p ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts
    cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

    mkdir -p ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/msp/tlscacerts
    cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/msp/tlscacerts/tlsca.example.com-cert.pem

    echo "Generating the admin msp"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:7054 --caname ca -M ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
    { set +x; } 2>/dev/null

    cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp/config.yaml
}

function createGenesisBlock() {
    echo "Generating channel genesis block '${CHANNEL_NAME}.block'"
    set -x
    ${BIN_DIR}/configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ${TEST_NETWORK_HOME}/channel-artifacts/genesis.block -channelID system-channel
    res=$?
    { set +x; } 2>/dev/null
    verifyResult $res "Failed to generate channel configuration transaction..."
}

function startOrderer() {

    export FABRIC_LOGGING_SPEC="INFO"
    export ORDERER_GENERAL_LISTENADDRESS="0.0.0.0"
    export ORDERER_GENERAL_LISTENPORT="7050"
    # export ORDERER_GENERAL_GENESISMETHOD=file
    # export ORDERER_GENERAL_GENESISFILE=${TEST_NETWORK_HOME}/channel-artifacts/genesis.block
    export ORDERER_GENERAL_BOOTSTRAPMETHOD="file"
    export ORDERER_GENERAL_BOOTSTRAPFILE="${TEST_NETWORK_HOME}/channel-artifacts/genesis.block"
    export ORDERER_GENERAL_LOCALMSPID="OrdererMSP"
    export ORDERER_GENERAL_LOCALMSPDIR="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp"
    export ORDERER_OPERATIONS_LISTENADDRESS="0.0.0.0:7444"
    export ORDERER_GENERAL_TLS_ENABLED=true
    export ORDERER_GENERAL_TLS_PRIVATEKEY="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key"
    export ORDERER_GENERAL_TLS_CERTIFICATE="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt"
    export ORDERER_GENERAL_TLS_ROOTCAS=["${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"]
    export ORDERER_KAFKA_TOPIC_REPLICATIONFACTOR=1
    export ORDERER_KAFKA_VERBOSE=true
    # export ORDERER_GENERAL_CLUSTER_LISTENADDRESS=orderer.example.com
    # export ORDERER_GENERAL_CLUSTER_LISTENPORT=7050
    # export ORDERER_GENERAL_CLUSTER_SERVERCERTIFICATE=${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
    # export ORDERER_GENERAL_CLUSTER_SERVERPRIVATEKEY=${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key
    # export ORDERER_GENERAL_CLUSTER_CLIENTCERTIFICATE=${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
    # export ORDERER_GENERAL_CLUSTER_CLIENTPRIVATEKEY=${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key
    # export ORDERER_GENERAL_CLUSTER_ROOTCAS=[${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt]
    export ORDERER_FILELEDGER_LOCATION="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com"
    export ORDERER_CONSENSUS_WALDIR="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/etcdraft/wal"
    export ORDERER_CONSENSUS_SNAPDIR="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/etcdraft/snapshot"

    nohup sh -c '${BIN_DIR}/orderer' > ${LOG_DIR}/orderer.log 2>&1 &
    echo $! 
}

function startPeer() {

    export FABRIC_LOGGING_SPEC="INFO"
    export CORE_VM_ENDPOINT=""
    export CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=""
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp"
    export CORE_PEER_TLS_CERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.crt"
    export CORE_PEER_TLS_KEY_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key"
    export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
    export CORE_PEER_ID="peer0.org1.example.com"
    export CORE_PEER_ADDRESS="peer0.org1.example.com:7051"
    export CORE_PEER_LISTENADDRESS="0.0.0.0:7051"
    export CORE_PEER_CHAINCODEADDRESS="peer0.org1.example.com:7052"
    export CORE_PEER_CHAINCODELISTENADDRESS="0.0.0.0:7052"
    export CORE_PEER_GOSSIP_BOOTSTRAP="peer0.org1.example.com:7051"
    export CORE_PEER_GOSSIP_EXTERNALENDPOINT="peer0.org1.example.com:7051"
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_OPERATIONS_LISTENADDRESS="0.0.0.0:7445"
    export CORE_PEER_FILESYSTEMPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/"
    export CORE_LEDGER_SNAPSHOTS_ROOTDIR="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/snapshots"

    nohup sh -c '${BIN_DIR}/peer node start' > ${LOG_DIR}/peer.log 2>&1 &
}

function createChannelTx() {
    CHANNEL_NAME=$1
	set -x
	${BIN_DIR}/configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
	res=$?
	{ set +x; } 2>/dev/null
    verifyResult $res "Failed to generate channel configuration transaction..."
}

function createChannel() {

    export CORE_PEER_TLS_ENABLED=true
    export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    export CORE_PEER_ADDRESS="localhost:7051"
    CHANNEL_NAME=$1
	# Poll in case the raft leader is not set yet
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		${BIN_DIR}/peer channel create -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CHANNEL_NAME}.tx --outputBlock ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CHANNEL_NAME}.block --tls --cafile $ORDERER_CA >&${LOG_DIR}/${CHANNEL_NAME}.log
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat ${LOG_DIR}/${CHANNEL_NAME}.log
	verifyResult $res "Channel creation failed"
}

function joinChannel() {

    export CORE_PEER_TLS_ENABLED=true
    export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    export CORE_PEER_ADDRESS="localhost:7051"
    CHANNEL_NAME=$1
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    ${BIN_DIR}/peer channel join -b ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CHANNEL_NAME}.block >&${LOG_DIR}/${CHANNEL_NAME}.log
    res=$?
    { set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat ${LOG_DIR}/${CHANNEL_NAME}.log
	verifyResult $res "After $MAX_RETRY attempts, peer0.org${ORG} has failed to join channel '$CHANNEL_NAME' "
}

function setAnchorPeer() {
    # setGlobalCLI
    export CORE_PEER_ADDRESS="peer0.org1.example.com:7051"
    export CORE_PEER_TLS_ENABLED=true
    export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    export CORE_PEER_ADDRESS="localhost:7051"
    CHANNEL_NAME=$1
    # fetchChannelConfig
    echo "Fetching the most recent configuration block for the channel"
    set -x
    ${BIN_DIR}/peer channel fetch config ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/config_block.pb -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME  --tls --cafile $ORDERER_CA
    { set +x; } 2>/dev/null

    echo "Decoding config block to JSON and isolating config to ${CORE_PEER_LOCALMSPID}config.json"
    set -x
    ${BIN_DIR}/configtxlator proto_decode --input "${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/config_block.pb" --type common.Block --output "${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CORE_PEER_LOCALMSPID}.json" 
    { set +x; } 2>/dev/null
    
    cat "${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CORE_PEER_LOCALMSPID}.json" | jq .data.data[0].payload.data.config >"${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CORE_PEER_LOCALMSPID}config.json"
    set -x
    # Modify the configuration to append the anchor peer 
    jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'"peer0.org1.example.com"'","port": '"7051"'}]},"version": "0"}}' ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CORE_PEER_LOCALMSPID}config.json > ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CORE_PEER_LOCALMSPID}modified_config.json
    { set +x; } 2>/dev/null

    # createConfigUpdate
    set -x
    ${BIN_DIR}/configtxlator proto_encode --input "${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CORE_PEER_LOCALMSPID}config.json" --type common.Config --output ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/original_config.pb
    ${BIN_DIR}/configtxlator proto_encode --input "${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CORE_PEER_LOCALMSPID}modified_config.json" --type common.Config --output ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/modified_config.pb
    ${BIN_DIR}/configtxlator compute_update --channel_id "${CHANNEL_NAME}" --original ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/original_config.pb --updated ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/modified_config.pb --output ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/config_update.pb
    ${BIN_DIR}/configtxlator proto_decode --input ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/config_update.pb --type common.ConfigUpdate --output ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/config_update.json
    echo '{"payload":{"header":{"channel_header":{"channel_id":"'${CHANNEL_NAME}'", "type":2}},"data":{"config_update":'$(cat ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/config_update.json)'}}}' | jq . >${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/config_update_in_envelope.json
    ${BIN_DIR}/configtxlator proto_encode --input ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/config_update_in_envelope.json --type common.Envelope --output "${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CORE_PEER_LOCALMSPID}anchors.tx"
    { set +x; } 2>/dev/null

    # updateAnchorPeer
    ${BIN_DIR}/peer channel update -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA >&${LOG_DIR}/${CHANNEL_NAME}.log
    res=$?
    cat ${LOG_DIR}/${CHANNEL_NAME}.log
    verifyResult $res "Anchor peer update failed"
}

# function deployChaincode() {
#     CHANNEL_NAME=$1
#     CHAINCODE_NAME=$2
#     shift 2
#     pushd ${TEST_NETWORK_HOME}/chaincodes/${CHAINCODE_NAME}/go
#     GO111MODULE=on go mod vendor
#     popd
#     echo "Finished vendoring Go dependencies"

#     set -x
#     ${BIN_DIR}/peer lifecycle chaincode package ${TEST_NETWORK_HOME}/packages/${CHAINCODE_NAME}.tar.gz --path ${TEST_NETWORK_HOME}/chaincodes/${CHAINCODE_NAME}/go --lang "golang" --label ${CHAINCODE_NAME}_${CHAINCODE_VERSION} >&${LOG_DIR}/chaincode.log
#     res=$?
#     { set +x; } 2>/dev/null
#     cat ${LOG_DIR}/chaincode.log
#     verifyResult $res "Chaincode packaging has failed"
#     echo "Chaincode is packaged"

#     export CORE_PEER_TLS_ENABLED=true
#     export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
#     export CORE_PEER_LOCALMSPID="Org1MSP"
#     export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
#     export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
#     export CORE_PEER_ADDRESS="localhost:7051"
    
#     set -x
#     ${BIN_DIR}/peer lifecycle chaincode install ${TEST_NETWORK_HOME}/packages/${CHAINCODE_NAME}.tar.gz >&${LOG_DIR}/chaincode.log
#     res=$?
#     { set +x; } 2>/dev/null
#     cat ${LOG_DIR}/chaincode.log
#     verifyResult $res "Chaincode installation on peer0.org${ORG} has failed"
#     echo "Chaincode is installed on peer0.org1"

#     set -x
#     ${BIN_DIR}/peer lifecycle chaincode queryinstalled >&${LOG_DIR}/chaincode.log
#     res=$?
#     { set +x; } 2>/dev/null
#     cat ${LOG_DIR}/chaincode.log
#     PACKAGE_ID=$(sed -n "/${CHAINCODE_NAME}_${CHAINCODE_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" ${LOG_DIR}/chaincode.log)
#     verifyResult $res "Query installed on peer0.org1 has failed"
#     echo "Query installed successful on peer0.org1 on channel"

#     set -x
#     ${BIN_DIR}/peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --package-id ${PACKAGE_ID} --sequence ${CHAINCODE_SEQUENCE} ${CHAINCODE_INIT_REQUIRED} ${CHAINCODE_END_POLICY} ${CHAINCODE_COLL_CONFIG} >&${LOG_DIR}/chaincode.log
#     res=$?
#     { set +x; } 2>/dev/null
#     cat ${LOG_DIR}/chaincode.log
#     verifyResult $res "Chaincode definition approved on peer0.org1 on channel '${CHANNEL_NAME}' failed"
#     echo "Chaincode definition approved on peer0.org1 on channel '${CHANNEL_NAME}'"

#     local rc=1
#     local COUNTER=1
#     # continue to poll
#     # we either get a successful response, or reach MAX RETRY
#     while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
#         sleep $DELAY
#         echo "Attempting to check the commit readiness of the chaincode definition on peer0.org1, Retry after $DELAY seconds."
#         set -x
#         ${BIN_DIR}/peer lifecycle chaincode checkcommitreadiness --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --sequence ${CHAINCODE_SEQUENCE} ${CHAINCODE_INIT_REQUIRED} ${CHAINCODE_END_POLICY} ${CHAINCODE_COLL_CONFIG} --output json >&${LOG_DIR}/chaincode.log
#         res=$?
#         { set +x; } 2>/dev/null
#         let rc=0
#         for var in "$@"; do
#         grep "$var" ${LOG_DIR}/chaincode.log &>/dev/null || let rc=1
#         done
#         COUNTER=$(expr $COUNTER + 1)
#     done
#     cat ${LOG_DIR}/chaincode.log
#     if test $rc -eq 0; then
#         echo "Checking the commit readiness of the chaincode definition successful on peer0.org on channel '${CHANNEL_NAME}'"
#     else
#         echo "After $MAX_RETRY attempts, Check commit readiness result on peer0.org1 is INVALID!"
#         exit 1
#     fi

#     PEER_CONN_PARMS="${PEER_CONN_PARMS} --peerAddresses ${CORE_PEER_ADDRESS}"
#     TLSINFO=$(eval echo "--tlsRootCertFiles \$CORE_PEER_TLS_ROOTCERT_FILE")
#     PEER_CONN_PARMS="${PEER_CONN_PARMS} ${TLSINFO}"
#     # while 'peer chaincode' command can get the orderer endpoint from the
#     # peer (if join was successful), let's supply it directly as we know
#     # it using the "-o" option
#     set -x
#     ${BIN_DIR}/peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} $PEER_CONN_PARMS --version ${CHAINCODE_VERSION} --sequence ${CHAINCODE_SEQUENCE} ${CHAINCODE_INIT_REQUIRED} ${CHAINCODE_END_POLICY} ${CHAINCODE_COLL_CONFIG} >&${LOG_DIR}/chaincode.log
#     res=$?
#     { set +x; } 2>/dev/null
#     cat ${LOG_DIR}/chaincode.log
#     verifyResult $res "Chaincode definition commit failed on peer0.org1 on channel '${CHANNEL_NAME}' failed"
#     echo "Chaincode definition committed on channel '${CHANNEL_NAME}'"

#     EXPECTED_RESULT="Version: ${CHAINCODE_VERSION}, Sequence: ${CHAINCODE_SEQUENCE}, Endorsement Plugin: escc, Validation Plugin: vscc"
#     echo "Querying chaincode definition on peer0.org$ on channel '${CHANNEL_NAME}'..."
#     local rc=1
#     local COUNTER=1
#     # continue to poll
#     # we either get a successful response, or reach MAX RETRY
#     while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
#         sleep $DELAY
#         echo "Attempting to Query committed status on peer0.org1, Retry after $DELAY seconds."
#         set -x
#         ${BIN_DIR}/peer lifecycle chaincode querycommitted --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} >&${LOG_DIR}/chaincode.log
#         res=$?
#         { set +x; } 2>/dev/null
#         test $res -eq 0 && VALUE=$(cat ${LOG_DIR}/chaincode.log | grep -o '^Version: '$CHAINCODE_VERSION', Sequence: [0-9]*, Endorsement Plugin: escc, Validation Plugin: vscc')
#         test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
#         COUNTER=$(expr $COUNTER + 1)
#     done
#     cat ${LOG_DIR}/chaincode.log
#     if test $rc -eq 0; then
#         echo "Query chaincode definition successful on peer0.org1 on channel '${CHANNEL_NAME}'"
#     else
#         echo "After $MAX_RETRY attempts, Query chaincode definition result on peer0.org1 is INVALID!"
#         exit 1
#     fi

# }

function main() {
    startCA
    echo "waiting for starting fabric-ca-server completely"
    sleep 5
    createOrg1
    echo "finished to create org1"
    sleep 1
    createOrderer
    echo "finished to create orderer"
    sleep 1
    createGenesisBlock
    echo "finished to create genesis block"
    sleep 1
    startOrderer
    echo "waiting for starting orderer completely"
    sleep 5
    startPeer
    echo "waiting for starting peer completely"
    sleep 5
    createChannelTx mychannel0
    echo "finished to create channel tx"
    sleep 1
    createChannel mychannel0
    echo "finished to create channel"
    sleep 1
    joinChannel mychannel0
    echo "finished to join channel org1"
    sleep 1
    setAnchorPeer mychannel0
    echo "finished to set anchor peer"
    sleep 1
    deployChaincode mychannel0 token-erc-20 "\"Org1MSP\": true"
    echo "finished to deploy chaincode"
    sleep 5
    # createChannelTx mychannel1
    # echo "finished to create channel tx"
    # sleep 1
    # createChannel mychannel1
    # echo "finished to create channel"
    # sleep 1
    # joinChannel mychannel1
    # echo "finished to join channel org1"
    # sleep 1
    # setAnchorPeer mychannel1
    # echo "finished to set anchor peer"
    # sleep 1
    # deployChaincode mychannel1 coin-erc-20 "\"Org1MSP\": true"
    # echo "finished to deploy chaincode"
}

function verifyResult() {
    if [ $1 -ne 0 ]; then
        echo -e "$2"
        exit 1
    fi
}

main



