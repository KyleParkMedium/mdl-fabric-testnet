# mdl(fabric)-testnet

### 로컬 테스트 환경 설정 방법

작성일 23-01-16 기준,

1. install fabric-ca 1.5.5, fabric 2.2.6(2.2~)  
   [How to install - Fabric Docs](https://hyperledger-fabric.readthedocs.io/en/release-2.5/install.html)

2. MDL-CORE, Fabric-CA 바이너리 연결.  
   [MDL v2.2 로컬 개발 환경(darwin-arm64) 구성](https://www.notion.so/MDL-v2-2-darwin-arm64-c3e643fa7eb34c11b98645388016bc4b) 참조.

3. 필요에 따라 ./config, ./docker config 파일 수정  
   README.md 파일 작성 기준  
   Org1User1, Org1User2, Org1User3, Org2User1, Org2User2, Org2User3 이용 가능

4. 개인 로컬 환경에 각 노드 주소 개방

   ```bash
   ifconfig | grep inet
   ```

   ```bash
   sudo vim /etc/hosts
   192.168.2.186 ca ca.org1.example.com peer0.org1.example.com peer1.org1.example.com peer2.org1.example.com orderer0.example.com orderer1.example.com orderer2.example.com peer0 peer1 peer2 orderer0 orderer1 orderer2 cli ca_org1 ca_org2 ca_orderer users orderer peer peer0 ca ca-org1 ca-org2 ca-orderer orderer.example.com peer0.org1.example.com peer0.org2.example.com ca.org1.example.com ca.org2.example.com
   ```

5. 체인코트 테스트 시 ,  
   ./chaincode/STO/go 내 체인코드 복사  
   테스트할 체인코드는 mdl-chaincodes 레포지토리 참고.  
   [mdl-chaincodes](https://github.com/the-medium-tech/mdl-chaincodes)  
   23.01.11 기준 최신 sto chaincode는 아래 위치 [dev-kyle-sto_token](https://github.com/the-medium-tech/mdl-chaincodes/tree/develop-kyle-sto_token)

6. ./start.sh 실행
7. ./stoTokenChaincode.sh or ./long_ver.sh 스크립트 실행  
   or 웹 서버 api 호출.  
    각 스크립트 내용 참고.
8. 환경 초기화 ./clear.sh + 필요에 따라 docker volume prune
