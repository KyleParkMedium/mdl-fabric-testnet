#!/bin/bash

function one_line_pem {
    echo "$(awk 'NF {sub(/\\n/, ""); printf "%s\\\\n",$0;}' $1)"
}

function json_ccp {
    sed -e "s/\${ORG}/$1/g" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${ADMIN_PK}/$3/" \
        ${TEST_NETWORK_HOME}/blockExplorer/profile-template.json
}

ORG=1
P0PORT=7050
ADMIN_PK_DIR=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org${ORG}.example.com/msp/keystore
ADMIN_PK=$(ls $ADMIN_PK_DIR)

echo "$(json_ccp $ORG $P0PORT $ADMIN_PK)" >${TEST_NETWORK_HOME}/blockExplorer/connection-profile/test-network.json
