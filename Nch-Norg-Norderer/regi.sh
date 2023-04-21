#!/bin/bash

function createOrderer2() {
  echo "Enrolling the CA admin"

  mkdir -p ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com

  export FABRIC_CA_CLIENT_HOME=${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com

  Orderer_address2="fabric-ca/ordererOrg2/tls-cert.pem"

  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://admin:adminpw@localhost:5054 --caname ca-orderer2 --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Orderer_address2}
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-5054-ca-orderer2.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-5054-ca-orderer2.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-5054-ca-orderer2.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-5054-ca-orderer2.pem
    OrganizationalUnitIdentifier: orderer' >${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/msp/config.yaml

  echo "Registering orderer2"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client register --caname ca-orderer2 --id.name orderer2 --id.secret orderer2pw --id.type orderer --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Orderer_address2}
  { set +x; } 2>/dev/null

  echo "Registering the orderer2 admin"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client register --caname ca-orderer2 --id.name orderer2Admin --id.secret orderer2Adminpw --id.type admin --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Orderer_address2}
  { set +x; } 2>/dev/null

  echo "Generating the orderer2 msp"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://orderer2:orderer2pw@localhost:5054 --caname ca-orderer2 -M ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/orderers/orderer2.example.com/msp --csr.hosts orderer2.example.com --csr.hosts localhost --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Orderer_address2}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/orderers/orderer2.example.com/msp/config.yaml

  echo "Generating the orderer-tls certificates"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://orderer2:orderer2pw@localhost:5054 --caname ca-orderer -M ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/orderers/orderer2.example.com/tls --enrollment.profile tls --csr.hosts orderer2.example.com --csr.hosts localhost --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Orderer_address2}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/orderers/orderer2.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/orderers/orderer2.example.com/tls/ca.crt
  cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/orderers/orderer2.example.com/tls/signcerts/* ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/orderers/orderer2.example.com/tls/server.crt
  cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/orderers/orderer2.example.com/tls/keystore/* ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/orderers/orderer2.example.com/tls/server.key

  mkdir -p ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/orderers/orderer2.example.com/msp/tlscacerts
  cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/orderers/orderer2.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/orderers/orderer2.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

  mkdir -p ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/msp/tlscacerts
  cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/orderers/orderer2.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

  echo "Generating the admin msp"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://orderer2Admin:orderer2Adminpw@localhost:5054 --caname ca-orderer2 -M ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/users/Admin@example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Orderer_address2}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/users/Admin@example.com/msp/config.yaml
}
