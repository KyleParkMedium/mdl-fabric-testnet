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

  echo "Registering peer0"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client register --caname ca-org1 --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
  { set +x; } 2>/dev/null

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

  echo "Generating the peer0 msp"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-org1 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp --csr.hosts peer0.org1.example.com --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/config.yaml

  echo "Generating the peer0-tls certificates"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-org1 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls --enrollment.profile tls --csr.hosts peer0.org1.example.com --csr.hosts localhost --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
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

function createOrg2() {
  echo "Enrolling the CA admin"

  mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/

  export FABRIC_CA_CLIENT_HOME=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/

  Org2_address="fabric-ca/org2/tls-cert.pem"

  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca-org2 --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org2_address}
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
    Enable: true
    ClientOUIdentifier:
        Certificate: cacerts/localhost-8054-ca-org2.pem
        OrganizationalUnitIdentifier: client
    PeerOUIdentifier:
        Certificate: cacerts/localhost-8054-ca-org2.pem
        OrganizationalUnitIdentifier: peer
    AdminOUIdentifier:
        Certificate: cacerts/localhost-8054-ca-org2.pem
        OrganizationalUnitIdentifier: admin
    OrdererOUIdentifier:
        Certificate: cacerts/localhost-8054-ca-org2.pem
        OrganizationalUnitIdentifier: orderer' >${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/msp/config.yaml

  echo "Registering peer0"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client register --caname ca-org2 --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org2_address}
  { set +x; } 2>/dev/null

  echo "Registering user1"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client register --caname ca-org2 --id.name org2user1 --id.secret org2user1pw --id.type client --id.attrs '"hf.Registrar.Roles=client"' --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org2_address}
  { set +x; } 2>/dev/null

  echo "Registering user2"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client register --caname ca-org2 --id.name org2user2 --id.secret org2user2pw --id.type client --id.attrs '"hf.Registrar.Roles=client"' --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org2_address}
  { set +x; } 2>/dev/null

  echo "Registering user3"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client register --caname ca-org2 --id.name org2user3 --id.secret org2user3pw --id.type client --id.attrs '"hf.Registrar.Roles=client"' --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org2_address}
  { set +x; } 2>/dev/null

  echo "Registering the org admin"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client register --caname ca-org2 --id.name org2admin --id.secret org2adminpw --id.type admin --id.attrs '"hf.Registrar.Roles=admin",hf.Revoker=true' --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org2_address}
  { set +x; } 2>/dev/null

  echo "Generating the peer0 msp"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-org2 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp --csr.hosts peer0.org2.example.com --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org2_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp/config.yaml

  echo "Generating the peer0-tls certificates"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-org2 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls --enrollment.profile tls --csr.hosts peer0.org2.example.com --csr.hosts localhost --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org2_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/signcerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/server.crt
  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/keystore/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/server.key

  mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/msp/tlscacerts
  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/msp/tlscacerts/ca.crt

  mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/tlsca
  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem

  mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/ca
  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp/cacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/ca/ca.org2.example.com-cert.pem

  echo "Generating the user1 msp"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://org2user1:org2user1pw@localhost:8054 --caname ca-org2 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Org2User1@org2.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org2_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Org2User1@org2.example.com/msp/config.yaml

  echo "Generating the user2 msp"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://org2user2:org2user2pw@localhost:8054 --caname ca-org2 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Org2User2@org2.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org2_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Org2User2@org2.example.com/msp/config.yaml

  echo "Generating the user3 msp"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://org2user3:org2user3pw@localhost:8054 --caname ca-org2 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Org2User3@org2.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org2_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Org2User3@org2.example.com/msp/config.yaml

  echo "Generating the org admin msp"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://org2admin:org2adminpw@localhost:8054 --caname ca-org2 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org2_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/config.yaml
}

function createOrg3() {
  echo "Enrolling the CA admin"

  mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/

  export FABRIC_CA_CLIENT_HOME=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/

  Org3_address="fabric-ca/org3/tls-cert.pem"

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

  echo "Registering user2"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client register --caname ca-org3 --id.name org3user2 --id.secret org3user2pw --id.type client --id.attrs '"hf.Registrar.Roles=client"' --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org3_address}
  { set +x; } 2>/dev/null

  echo "Registering user3"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client register --caname ca-org3 --id.name org3user3 --id.secret org3user3pw --id.type client --id.attrs '"hf.Registrar.Roles=client"' --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org3_address}
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

  echo "Generating the user1 msp"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://org3user1:org3user1pw@localhost:6054 --caname ca-org3 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/users/Org3User1@org3.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org3_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/users/Org3User1@org3.example.com/msp/config.yaml

  echo "Generating the user2 msp"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://org3user2:org3user2pw@localhost:6054 --caname ca-org3 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/users/Org3User2@org3.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org3_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/users/Org3User2@org3.example.com/msp/config.yaml

  echo "Generating the user3 msp"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://org3user3:org3user3pw@localhost:6054 --caname ca-org3 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/users/Org3User3@org3.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org3_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/users/Org3User3@org3.example.com/msp/config.yaml

  echo "Generating the org admin msp"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://org3admin:org3adminpw@localhost:6054 --caname ca-org3 -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org3_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp/config.yaml
}

#!/bin/bash

function createOrderer1() {
  echo "Enrolling the CA admin"

  mkdir -p ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com

  export FABRIC_CA_CLIENT_HOME=${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com

  Orderer_address="fabric-ca/ordererOrg1/tls-cert.pem"

  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer1 --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Orderer_address}
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer1.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer1.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer1.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer1.pem
    OrganizationalUnitIdentifier: orderer' >${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/msp/config.yaml

  echo "Registering orderer1"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client register --caname ca-orderer1 --id.name orderer1 --id.secret orderer1pw --id.type orderer --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Orderer_address}
  { set +x; } 2>/dev/null

  echo "Registering the orderer1 admin"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client register --caname ca-orderer1 --id.name orderer1Admin --id.secret orderer1Adminpw --id.type admin --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Orderer_address}
  { set +x; } 2>/dev/null

  echo "Generating the orderer1 msp"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://orderer1:orderer1pw@localhost:9054 --caname ca-orderer1 -M ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/orderers/orderer1.example.com/msp --csr.hosts orderer1.example.com --csr.hosts localhost --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Orderer_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/orderers/orderer1.example.com/msp/config.yaml

  echo "Generating the orderer-tls certificates"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://orderer1:orderer1pw@localhost:9054 --caname ca-orderer1 -M ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/orderers/orderer1.example.com/tls --enrollment.profile tls --csr.hosts orderer1.example.com --csr.hosts localhost --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Orderer_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/orderers/orderer1.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/orderers/orderer1.example.com/tls/ca.crt
  cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/orderers/orderer1.example.com/tls/signcerts/* ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/orderers/orderer1.example.com/tls/server.crt
  cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/orderers/orderer1.example.com/tls/keystore/* ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/orderers/orderer1.example.com/tls/server.key

  mkdir -p ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/orderers/orderer1.example.com/msp/tlscacerts
  cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/orderers/orderer1.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

  mkdir -p ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/msp/tlscacerts
  cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/orderers/orderer1.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

  echo "Generating the admin msp"
  set -x
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://orderer1Admin:orderer1Adminpw@localhost:9054 --caname ca-orderer1 -M ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/users/Admin@example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Orderer_address}
  { set +x; } 2>/dev/null

  cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org1.example.com/users/Admin@example.com/msp/config.yaml
}

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
  ${CA_BIN_DIR}/fabric-ca-client enroll -u https://orderer2:orderer2pw@localhost:5054 --caname ca-orderer2 -M ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/org2.example.com/orderers/orderer2.example.com/tls --enrollment.profile tls --csr.hosts orderer2.example.com --csr.hosts localhost --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Orderer_address2}
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
    if [ ! -f "organizations/fabric-ca/org2/tls-cert.pem" ]; then
      sleep 1
    else

      break
    fi
  done
  createOrg2

  while :; do
    if [ ! -f "organizations/fabric-ca/org3/tls-cert.pem" ]; then
      sleep 1
    else

      break
    fi
  done
  createOrg3

  while :; do
    if [ ! -f "organizations/fabric-ca/ordererOrg1/tls-cert.pem" ]; then
      echo no
      sleep 1
    else
      break
    fi
  done
  createOrderer1

  while :; do
    if [ ! -f "organizations/fabric-ca/ordererOrg2/tls-cert.pem" ]; then
      echo no
      sleep 1
    else
      break
    fi
  done
  createOrderer2

  # ${TEST_NETWORK_HOME}/scripts/utils/ccp-generate.sh
  # ${TEST_NETWORK_HOME}/blockExplorer/profile-generate.sh
}

main
