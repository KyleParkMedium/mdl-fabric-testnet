#!/bin/bash

function createOrg1() {
  echo "Enrolling the CA admin"

  mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/

  export FABRIC_CA_CLIENT_HOME=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/

  Org1_address="fabric-ca/org1/tls-cert.pem"

  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-org1 --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
    Enable: true
    ClientOUIdentifier:
        Certificate: cacerts/localhost-7054-ca-org1.pem
        OrganizationalUnitIdentifier: client
    PeerOUIdentifier:
        Certificate: cacerts/localhost-7054-ca-org1.pem
        OrganizationalUnitIdentifier: peer
    AdminOUIdentifier:
        Certificate: cacerts/localhost-7054-ca-org1.pem
        OrganizationalUnitIdentifier: admin
    OrdererOUIdentifier:
        Certificate: cacerts/localhost-7054-ca-org1.pem
        OrganizationalUnitIdentifier: orderer' >${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/config.yaml

  echo "Registering user1"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client register --caname ca-org1 --id.name org1user1 --id.secret org1user1pw --id.type client --id.attrs '"hf.Registrar.Roles=client"' --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
  { set +x; } 2>/dev/null
  echo "Registering user2"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client register --caname ca-org1 --id.name org1user2 --id.secret org1user2pw --id.type client --id.attrs '"hf.Registrar.Roles=client"' --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
  { set +x; } 2>/dev/null
  echo "Registering user3"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client register --caname ca-org1 --id.name org1user3 --id.secret org1user3pw --id.type client --id.attrs '"hf.Registrar.Roles=client"' --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
  { set +x; } 2>/dev/null

  echo "Registering the org admin"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client register --caname ca-org1 --id.name org1admin --id.secret org1adminpw --id.type admin --id.attrs '"hf.Registrar.Roles=admin",hf.Revoker=true' --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
  { set +x; } 2>/dev/null

  peer_array=("peer0" "peer1" "peer2" "peer3" "peer4" "peer5")
  # peer_array=("peer0")
  for element in "${peer_array[@]}"; do
    setPeer $element
  done

  ## create client
  echo "Generating the user1 msp"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://org1user1:org1user1pw@localhost:7054 --caname ca-org1 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Org1User1@org1.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Org1User1@org1.example.com/msp/config.yaml

  echo "Generating the user2 msp"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://org1user2:org1user2pw@localhost:7054 --caname ca-org1 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Org1User2@org1.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Org1User2@org1.example.com/msp/config.yaml

  echo "Generating the user3 msp"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://org1user3:org1user3pw@localhost:7054 --caname ca-org1 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Org1User3@org1.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Org1User3@org1.example.com/msp/config.yaml

  echo "Generating the org admin msp"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://org1admin:org1adminpw@localhost:7054 --caname ca-org1 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/config.yaml
}

function setPeer() {
  peer=$1

  echo "Registering ${peer}"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client register --caname ca-org1 --id.name ${peer} --id.secret ${peer}pw --id.type peer --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
  { set +x; } 2>/dev/null

  echo "Generating the ${peer} msp"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://${peer}:${peer}pw@localhost:7054 --caname ca-org1 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/${peer}.org1.example.com/msp --csr.hosts ${peer}.org1.example.com --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
  { set +x; } 2>/dev/null
  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/${peer}.org1.example.com/msp/config.yaml

  echo "Generating the ${peer}-tls certificates"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://${peer}:${peer}pw@localhost:7054 --caname ca-org1 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/${peer}.org1.example.com/tls --enrollment.profile tls --csr.hosts ${peer}.org1.example.com --csr.hosts localhost --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/${peer}.org1.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/${peer}.org1.example.com/tls/ca.crt
  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/${peer}.org1.example.com/tls/signcerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/${peer}.org1.example.com/tls/server.crt
  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/${peer}.org1.example.com/tls/keystore/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/${peer}.org1.example.com/tls/server.key

  # mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/tlscacerts
  # cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/${peer}.org1.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/tlscacerts/ca.crt

  # mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/tlsca
  # cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/${peer}.org1.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem

  # mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/ca
  # cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/${peer}.org1.example.com/msp/cacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem
}

function createOrderer() {
  echo "Enrolling the CA admin"

  mkdir -p ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com

  export FABRIC_CA_CLIENT_HOME=${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com

  Orderer_address="fabric-ca/ordererOrg/tls-cert.pem"

  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Orderer_address}
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' >${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/msp/config.yaml

  echo "Registering orderer"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Orderer_address}
  { set +x; } 2>/dev/null

  echo "Registering the orderer admin"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Orderer_address}
  { set +x; } 2>/dev/null

  echo "Generating the orderer msp"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp --csr.hosts orderer.example.com --csr.hosts localhost --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Orderer_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/config.yaml

  echo "Generating the orderer-tls certificates"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls --enrollment.profile tls --csr.hosts orderer.example.com --csr.hosts localhost --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Orderer_address}
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
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-orderer -M ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Orderer_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp/config.yaml
}

function main() {

  while :; do
    if [ ! -f "organizations/fabric-ca/org1/tls-cert.pem" ]; then
      sleep 1
    else
      break
    fi
  done

  createOrg1

  while :; do
    if [ ! -f "organizations/fabric-ca/ordererOrg/tls-cert.pem" ]; then
      echo no
      sleep 1
    else
      break
    fi
  done

  createOrderer

  # ./ccp-generate.sh
}

main
