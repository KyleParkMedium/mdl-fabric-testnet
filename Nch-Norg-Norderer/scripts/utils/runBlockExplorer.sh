#!/bin/bash
IMAGE_LIST=$(docker image ls)

EXPLORER_NAME="explorer"
EXPLORER_TAG="latest"
EXPLORER_DB_NAME="explorer-db"
EXPLORER_DB_TAG="latest"

if ! echo "$IMAGE_LIST" | grep -q "$EXPLORER_NAME.*$EXPLORER_TAG"; then
    docker pull hyperledger/explorer
fi
if ! echo "$IMAGE_LIST" | grep -q "$EXPLORER_DB_NAME.*$EXPLORER_DB_TAG"; then
    docker pull hyperledger/explorer-db
fi

export EXPLORER_CONFIG_FILE_PATH=${TEST_NETWORK_HOME}/blockExplorer/config.json
export EXPLORER_PROFILE_DIR_PATH=${TEST_NETWORK_HOME}/blockExplorer/connection-profile
export FABRIC_CRYPTO_PATH=${TEST_NETWORK_HOME}/organizations

export COMPOSE_BLOCK_EXPLORER=${TEST_NETWORK_HOME}/blockExplorer/docker-compose.yaml

docker-compose -f $COMPOSE_BLOCK_EXPLORER up -d 2>&1
