#!/bin/bash
export TEST_NETWORK_HOME=$(dirname $(readlink -f $0))

if [ -d ${TEST_NETWORK_HOME}/organizations ]; then
    rm -rf ${TEST_NETWORK_HOME}/organizations
fi
if [ -d ${TEST_NETWORK_HOME}/channel-artifacts ]; then
    rm -rf ${TEST_NETWORK_HOME}/channel-artifacts
    mkdir -p ${TEST_NETWORK_HOME}/channel-artifacts
fi
if [ -d ${TEST_NETWORK_HOME}/log ]; then
    rm -rf ${TEST_NETWORK_HOME}/log
    mkdir -p ${TEST_NETWORK_HOME}/log
fi
if [ -d ${TEST_NETWORK_HOME}/packages ]; then
    rm -rf ${TEST_NETWORK_HOME}/packages
    mkdir -p ${TEST_NETWORK_HOME}/packages
fi
docker rm -f $(docker ps -aq) 
docker rmi $(docker images -q --filter "reference=dev-*")
# docker volume prune 

############ Process initialization ############
PROCESS=`pgrep fabric-ca-server`
if [ -n "$PROCESS" ]; then
    echo "kill $PROCESS"
    kill -9 $PROCESS
fi

PROCESS=`pgrep orderer`
if [ -n "$PROCESS" ]; then
    echo "kill $PROCESS"
    kill -9 $PROCESS
fi

############ Process initialization ############
PROCESS=`pgrep peer`
if [ -n "$PROCESS" ]; then
    echo "kill $PROCESS"
    kill -9 $PROCESS
fi