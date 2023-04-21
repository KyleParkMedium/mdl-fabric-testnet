#!/bin/bash
export TEST_NETWORK_HOME="/Users/park/code/mdl-fabric-testnet"
export ORG1_DIR="/Users/park/code/mdl-fabric-testnet/org1"
export BIN_DIR="${TEST_NETWORK_HOME}/bin"
export CA_BIN_DIR="${TEST_NETWORK_HOME}/ca-bin"
export LOG_DIR="${TEST_NETWORK_HOME}/log"

# Config Path
export FABRIC_CFG_PATH=${ORG1_DIR}/config

export CHANNEL_NAME="mychannel0"
CHAINCODE_NAME="STO"
# MAX_RETRY="10"
DELAY="$2"
: ${DELAY:="3"}
MAX_RETRY="$3"
: ${MAX_RETRY:="4"}
VERBOSE="$4"
: ${VERBOSE:="false"}

export FABRIC_CFG_PATH=${TEST_NETWORK_HOME}/config

function enroll() {

    mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/

    export FABRIC_CA_CLIENT_HOME=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/

    Org1_address="fabric-ca/org1/tls-cert.pem"

    echo "Registering peer1"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client register --caname ca-org1 --id.name peer1 --id.secret peer1pw --id.type peer --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
    { set +x; } 2>/dev/null

    echo "Registering user4"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client register --caname ca-org1 --id.name org1user4 --id.secret org1user4pw --id.type client --id.attrs '"hf.Registrar.Roles=client"' --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
    { set +x; } 2>/dev/null

    echo "Generating the peer1 msp"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client enroll -u https://peer1:peer1pw@localhost:7054 --caname ca-org1 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/msp --csr.hosts peer1.org1.example.com --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
    { set +x; } 2>/dev/null

    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/msp/config.yaml

    echo "Generating the peer1-tls certificates"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client enroll -u https://peer1:peer1pw@localhost:7054 --caname ca-org1 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls --enrollment.profile tls --csr.hosts peer1.org1.example.com --csr.hosts localhost --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
    { set +x; } 2>/dev/null

    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt
    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/signcerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/server.crt
    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/keystore/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/server.key

    mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/tlscacerts
    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/tlscacerts/ca.crt

    mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/tlsca
    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem

    mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/ca
    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/msp/cacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem

    ## create client
    echo "Generating the user4 msp"
    set -x
    ${CA_BIN_DIR}/fabric-ca-client enroll -u https://org1user4:org1user4pw@localhost:7054 --caname ca-org1 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Org1User4@org1.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
    { set +x; } 2>/dev/null

    cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Org1User4@org1.example.com/msp/config.yaml
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

function start() {
    while :; do
        if [ ! -f "../organizations/fabric-ca/org1/tls-cert.pem" ]; then
            sleep 1
        else
            break
        fi
    done

    enroll
    echo "finished to registerEnroll(create org1)"
    sleep 1

}

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
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Org1User4@org1.example.com/msp"
    # export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG_NUM}.example.com/users/Admin@org${ORG_NUM}.example.com/msp"

    echo "query peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses "peer0.org1.example.com:7050" --tlsRootCertFiles "${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c $param >&${LOG_DIR}/TotalSupply.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/TotalSupply.log
    cp ${LOG_DIR}/TotalSupply.log ${LOG_DIR}/Response.log
    echo "query transaction successful on peer0 on channel '${CHANNEL_NAME}'"
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
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/$who@org1.example.com/msp"

    PEER_CONN_PARMS="${PEER_CONN_PARMS} ${TLSINFO} --peerAddresses localhost:8050 --tlsRootCertFiles ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/${who}_Wallet.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/${who}_Wallet.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"
}

function main() {
    start
    sleep 3

    TotalSupply
    sleep 3

    CreateWallet -u Org1User4 -p mediumToken -a 50
    sleep 3
}

function verifyResult() {
    if [ $1 -ne 0 ]; then
        echo -e "$2"
        exit 1
    fi
}

main
