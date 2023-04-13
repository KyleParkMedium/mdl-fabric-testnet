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
export TEST_NETWORK_HOME=$(dirname $(readlink -f $0))/../..

echo "chaincode invoke"
export PEERPATH="${TEST_NETWORK_HOME}"
export LOG_DIR="${TEST_NETWORK_HOME}/log"

export BIN_DIR="${TEST_NETWORK_HOME}/bin"
# ${BIN_DIR}/peer chaincode list --installed

## query example
# CC_ARGS="{\"selector\":{\"Name\":\"0\"}}"

param=""
func=""
string=""

function org1() {
    export FABRIC_CFG_PATH=${TEST_NETWORK_HOME}/config/org1
    export HOST="peer0.org1.example.com"
    export PORT=7050
    export ORG="Org1"
    export ORG_NUM=1
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
    export ORG_NUM=2
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
    export ORG_NUM=3
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

function Constructor() {

    local string
    string+="\\\"tokenId\\\":\\\"AA\\\","
    string+="\\\"publisher\\\":\\\"AA\\\","
    string+="\\\"publisherUuid\\\":\\\"AA\\\","
    string+="\\\"ror\\\":\\\"AA\\\","
    string+="\\\"investmentPeriod\\\":\\\"AA\\\","
    string+="\\\"grade\\\":\\\"AA\\\","
    string+="\\\"publicOfferingAmount\\\":\\\"5000\\\","
    string+="\\\"startDate\\\":\\\"AA\\\","
    string+="\\\"endDate\\\":\\\"AA\\\","
    string+="\\\"productName\\\":\\\"AA\\\","
    string+="\\\"channelNm\\\":\\\"AA\\\","

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        --cc)
            export CHAINCODE_NAME="$2"
            shift 2
            ;;
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
    string=${string%\,}

    # set query
    echo ${FUNCNAME[0]}

    param="{\"Args\":[\"${FUNCNAME[0]}\",\"{$string}\"]}"
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

function Invoke() {
    echo Invoke chaincode
    # set flag
    echo set flag $@
    flag $@

    # set query
    param="{\"Args\":[\"${func}\",\"{$string}\"]}"
    echo $param

    # set
    set -x

    # set env
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/Invoke-${ORG}-${CHANNEL_NAME}-${CHAINCODE_NAME}-${func}.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Invoke-${ORG}-${CHANNEL_NAME}-${CHAINCODE_NAME}-${func}.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    PEER_CONN_PARMS=""
    func=""
    string=""
    param=""
}

function Query() {
    echo Query chaincode
    # set flag
    echo set flag $@
    flag $@

    # set query
    param="{\"Args\":[\"${func}\",\"{$string}\"]}"
    echo $param

    # set
    set -x

    # set env
    echo "query peer connection parameters:"
    ${BIN_DIR}/peer chaincode query -o localhost:9050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses ${CORE_PEER_ADDRESS} --tlsRootCertFiles ${CORE_PEER_TLS_ROOTCERT_FILE} -c $param >&${LOG_DIR}/Query-${ORG}-${CHANNEL_NAME}-${CHAINCODE_NAME}-${func}.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Query-${ORG}-${CHANNEL_NAME}-${CHAINCODE_NAME}-${func}.log
    echo "Query transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    PEER_CONN_PARMS=""
    func=""
    string=""
    param=""
}

function flag() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        --cc)
            export CHAINCODE_NAME="$2"
            shift 2
            ;;
        --ch)
            export CHANNEL_NAME="$2"
            shift 2
            ;;
        --func)
            func=$2
            shift 2
            ;;
        --caller)
            string+="\\\"_caller\\\":\\\"$2\\\","
            shift 2
            ;;
        --tokenHolder)
            string+="\\\"_tokenHolder\\\":\\\"$2\\\","
            shift 2
            ;;
        --partition)
            if [ "$2" == "-" ]; then
                string+="\\\"_partition\\\":\\\"\\\","
            else
                string+="\\\"_partition\\\":\\\"$2\\\","
            fi
            shift 2
            ;;
        --value)
            string+="\\\"_value\\\":\\\"$2\\\","
            shift 2
            ;;
        --data)
            string+="\\\"_data\\\":\\\"$2\\\","
            shift 2
            ;;
        --from)
            string+="\\\"_from\\\":\\\"$2\\\","
            shift 2
            ;;
        --to)
            string+="\\\"_to\\\":\\\"$2\\\","
            shift 2
            ;;
        --operator)
            string+="\\\"_operator\\\":\\\"$2\\\","
            shift 2
            ;;
        --tokenWalletId)
            string+="\\\"tokenWalletId\\\":\\\"$2\\\","
            shift 2
            ;;
        --role)
            string+="\\\"role\\\":\\\"$2\\\","
            shift 2
            ;;
        --accountNumber)
            string+="\\\"accountNumber\\\":\\\"$2\\\","
            shift 2
            ;;
        --channelNm)
            string+="\\\"channelNm\\\":\\\"$2\\\","
            shift 2
            ;;
        --tokenId)
            string+="\\\"tokenId\\\":\\\"$2\\\","
            shift 2
            ;;
        --publicOfferingAmount)
            string+="\\\"publicOfferingAmount\\\":\\\"$2\\\","
            shift 2
            ;;
        --recipients)
            string+="\\\"recipients\\\":{\\\"Kyle1\\\":\\\"5000\\\"},"
            shift 2
            ;;
        --spender)
            string+="\\\"_spender\\\":\\\"$2\\\","
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
    string=${string%\,}
}

function main() {
    Constructor --cc STO --ch mychannel-all --p org2 --p org3 --p org1
    sleep 3
    Invoke --func CreateWallet --cc STO --ch mychannel-all --tokenWalletId Kyle --role ipo --accountNumber 100 --channelNm dev --p org2 --p org3 --p org1
    sleep 5
    Invoke --func CreateWallet --cc STO --ch mychannel-all --tokenWalletId Tom --role ipo --accountNumber 100 --channelNm dev --p org2 --p org3 --p org1
    sleep 5
    Invoke --func Issue --cc STO --ch mychannel-all --caller Kyle --tokenHolder Kyle --value 1000 --data 1a --p org2 --p org3 --p org1
    sleep 3
    Invoke --func IssueByPartition --cc STO --ch mychannel-all --caller Kyle --tokenHolder Kyle --partition 0x4ab21cd45c038f9b3d96c64ec46196774d762129989175922a6f01d71c3bb19e --value 100 --data 1a --p org2 --p org3 --p org1
    sleep 3
    Query --func BalanceOfByPartition --cc STO --ch mychannel-all --partition - --tokenHolder Kyle --p org1
    sleep 3
    Query --func BalanceOfByPartition --cc STO --ch mychannel-all --partition 0x4ab21cd45c038f9b3d96c64ec46196774d762129989175922a6f01d71c3bb19e --tokenHolder Kyle --p org1
    sleep 3
    Query --func TotalSupply --cc STO --ch mychannel-all --p org1
    sleep 3
    Query --func PartitionsOf --cc STO --ch mychannel-all --tokenHolder Kyle --p org1
    sleep 3

    Invoke --func Redeem --cc STO --ch mychannel-all --caller Kyle --tokenHolder Kyle --value 1000 --data 1a --p org2 --p org3 --p org1
    sleep 3
    Invoke --func RedeemByPartition --cc STO --ch mychannel-all --caller Kyle --tokenHolder Kyle --partition 0x4ab21cd45c038f9b3d96c64ec46196774d762129989175922a6f01d71c3bb19e --value 300 --data 1a --p org2 --p org3 --p org1
    sleep 3
    Invoke --func ApproveByPartition --cc STO --ch mychannel-all --caller Kyle --spender Kyle --tokenHolder Kyle --partition - --value 300 --data 1a --p org2 --p org3 --p org1
    sleep 3
    Invoke --func RedeemFrom --cc STO --ch mychannel-all --caller Kyle --tokenHolder Kyle --partition - --value 1000 --data 1a --p org2 --p org3 --p org1
    sleep 3

    Query --func CanTransfer --cc STO --ch mychannel-all --caller Kyle --to Kyle --value 100 --data 1a --p org1
    sleep 3
    Query --func CanTransferFrom --cc STO --ch mychannel-all --caller Kyle --from Kyle --to Kyle1 --value 100 --data 1a --p org1
    sleep 3
    Query --func CanTransferByPartition --cc STO --ch mychannel-all --caller Kyle --to Kyle --partition 0x4ab21cd45c038f9b3d96c64ec46196774d762129989175922a6f01d71c3bb19e --value 100 --data 1a --p org1
    sleep 3

    Invoke --func AuthorizeOperator --cc STO --ch mychannel-all --caller Kyle --operator Kyle --partition - --p org2 --p org1 --p org3
    sleep 3
    Invoke --func RevokeOperatorByPartition --cc STO --ch mychannel-all --caller Kyle --operator Kyle --partition 0x4ab21cd45c038f9b3d96c64ec46196774d762129989175922a6f01d71c3bb19e --p org2 --p org1 --p org3
    sleep 3
    Query --func IsControllable --cc STO --ch mychannel-all --p org1
    sleep 3
    Query --func IsOperator --cc STO --ch mychannel-all --operator Kyle --tokenHolder Kyle --p org1
    sleep 3
    Query --func IsOperatorForPartition --cc STO --ch mychannel-all --operator Kyle --tokenHolder Kyle --partition 0x4ab21cd45c038f9b3d96c64ec46196774d762129989175922a6f01d71c3bb19e --p org1
    sleep 3

    Invoke --func TransferWithData --cc STO --ch mychannel-all --caller Kyle --to Kyle --value 800 --data 1a --p org2 --p org3 --p org1
    sleep 3
    Invoke --func TransferFromWithData --cc STO --ch mychannel-all --caller Kyle --from Kyle --to Tom --value 100 --data 1a --p org2 --p org3 --p org1
    sleep 3
    Query --func BalanceOfByPartition --cc STO --ch mychannel-all --partition - --tokenHolder Kyle --p org1
    sleep 3
    Query --func BalanceOfByPartition --cc STO --ch mychannel-all --partition - --tokenHolder Tom --p org1
    sleep 3

    Invoke --func AuthorizeOperator --cc STO --ch mychannel-all --caller Kyle --operator Kyle --partition 0x4ab21cd45c038f9b3d96c64ec46196774d762129989175922a6f01d71c3bb19e --p org2 --p org1 --p org3
    sleep 3
    Invoke --func IssueByPartition --cc STO --ch mychannel-all --caller Kyle --tokenHolder Tom --partition 0x4ab21cd45c038f9b3d96c64ec46196774d762129989175922a6f01d71c3bb19e --value 100 --data 1a --p org2 --p org3 --p org1
    sleep 3
    Invoke --func ApproveByPartition --cc STO --ch mychannel-all --caller Kyle --spender Kyle --tokenHolder Kyle --partition 0x4ab21cd45c038f9b3d96c64ec46196774d762129989175922a6f01d71c3bb19e --value 3000 --data 1a --p org2 --p org3 --p org1
    sleep 3
    Invoke --func OperatorTransferByPartition --cc STO --ch mychannel-all --caller Kyle --from Kyle --to Tom --partition 0x4ab21cd45c038f9b3d96c64ec46196774d762129989175922a6f01d71c3bb19e --value 800 --data 1a --p org2 --p org3 --p org1
    sleep 3
    Query --func BalanceOfByPartition --cc STO --ch mychannel-all --partition 0x4ab21cd45c038f9b3d96c64ec46196774d762129989175922a6f01d71c3bb19e --tokenHolder Tom --p org1
    sleep 3
}

main
