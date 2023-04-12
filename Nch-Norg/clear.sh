#!/bin/bash
export TEST_NETWORK_HOME=$(dirname $(readlink -f $0))

if [ -d ${TEST_NETWORK_HOME}/organizations ]; then
    rm -rf ${TEST_NETWORK_HOME}/organizations
    mkdir -p ${TEST_NETWORK_HOME}/organizations
    cp ${TEST_NETWORK_HOME}/scripts/utils/ccp-template.json ${TEST_NETWORK_HOME}/organizations
    cp ${TEST_NETWORK_HOME}/scripts/utils//ccp-template.yaml ${TEST_NETWORK_HOME}/organizations
else
    mkdir -p ${TEST_NETWORK_HOME}/organizations
fi
if [ -d ${TEST_NETWORK_HOME}/channel-artifacts ]; then
    rm -rf ${TEST_NETWORK_HOME}/channel-artifacts
    mkdir -p ${TEST_NETWORK_HOME}/channel-artifacts
else
    mkdir -p ${TEST_NETWORK_HOME}/channel-artifacts
fi
if [ -d ${TEST_NETWORK_HOME}/org3/channel-artifacts ]; then
    rm -rf ${TEST_NETWORK_HOME}/org3/channel-artifacts
    mkdir -p ${TEST_NETWORK_HOME}/org3/channel-artifacts
else
    mkdir -p ${TEST_NETWORK_HOME}/org3/channel-artifacts
fi
if [ -d ${TEST_NETWORK_HOME}/log ]; then
    rm -rf ${TEST_NETWORK_HOME}/log
    mkdir -p ${TEST_NETWORK_HOME}/log
else
    mkdir -p ${TEST_NETWORK_HOME}/log
fi
if [ -d ${TEST_NETWORK_HOME}/packages ]; then
    rm -rf ${TEST_NETWORK_HOME}/packages
    mkdir -p ${TEST_NETWORK_HOME}/packages
else
    mkdir -p ${TEST_NETWORK_HOME}/packages
fi
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
if [ -d ${TEST_NETWORK_HOME}/chaincodes/Dev ]; then
    rm -rf ${TEST_NETWORK_HOME}/chaincodes/Dev
    mkdir -p ${TEST_NETWORK_HOME}/chaincodes/Dev
    cp -r "/Users/park/test/chaincodes/getset" ${TEST_NETWORK_HOME}/chaincodes/Dev
    mv ${TEST_NETWORK_HOME}/chaincodes/Dev/getset ${TEST_NETWORK_HOME}/chaincodes/Dev/go
else
    mkdir -p ${TEST_NETWORK_HOME}/chaincodes/Dev
    cp -r "/Users/park/test/chaincodes/getset" ${TEST_NETWORK_HOME}/chaincodes/Dev
    mv ${TEST_NETWORK_HOME}/chaincodes/Dev/getset ${TEST_NETWORK_HOME}/chaincodes/Dev/go
fi
if [ ! -d ${TEST_NETWORK_HOME}/bin ]; then
    ln -s /Users/park/code/mdl-core-2.2/release/darwin-arm64/bin bin
fi
if [ ! -d ${TEST_NETWORK_HOME}/ca-bin ]; then
    ln -s /Users/park/code/fabric-ca/release/darwin-arm64/bin ca-bin
fi

docker rm -f $(docker ps -aq)
docker rmi $(docker images -q --filter "reference=dev-*")
# docker volume prune

############ Process initialization ############
PROCESS=$(pgrep fabric-ca-server)
if [ -n "$PROCESS" ]; then
    echo "kill $PROCESS"
    kill -9 $PROCESS
fi

PROCESS=$(pgrep orderer)
if [ -n "$PROCESS" ]; then
    echo "kill $PROCESS"
    kill -9 $PROCESS
fi

############ Process initialization ############
PROCESS=$(pgrep peer)
if [ -n "$PROCESS" ]; then
    echo "kill $PROCESS"
    kill -9 $PROCESS
fi
