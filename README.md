# 로컬 개발 환경 구축

## 빌드 전 설정

### ConfigServer 설정
- `ConfigServer/src/main/resources/application.yml` 에서 search-locations를 실제 설정 저장소 경로로 변경

### EgovMobileId 설정
다음 파일들의 존재 여부 및 내용을 확인:
- `verifyConfig.json`
- `sp.wallet`
- `sp.did`

### EgovSearch 설정
- `EgovSearch/src/main/resources/application.yml` 에서 다음 항목을 실제 사용할 값으로 변경
  - opensearch.password: yourStrongPassword123!
  - opensearch.keystore.path: /Library/Java/JavaVirtualMachines/jdk-17.0.1.jdk/Contents/Home/lib/security/cacerts
  - opensearch.keystore.password: changeit
  - app.search-config-path: ./searchConfig.json

## 쉘 스크립트

- 실행권한 확인

```
chmod +x *.sh
```

- 쉘 스크립트 사용방법

```
./build.sh # 모든 서비스 빌드
./build.sh EgovMobileId # 특정 서비스만 빌드
./start.sh # 모든 서비스 시작
./start.sh EgovMobileId # 특정 서비스만 시작
./stop.sh # 모든 서비스 중지
./stop.sh EgovMobileId # 특정 서비스만 중지
./status.sh # 모든 서비스 상태 확인

./rebuild.sh # 모든 서비스 재빌드 (중지, 빌드, 시작)
./rebuild.sh EgovMobileId # 특정 서비스만 재빌드 (중지, 빌드, 시작)
```

# 배포 환경 구축

## Docker 배포
Docker를 사용한 배포 방법은 [docker-deploy/README.md](docker-deploy/README.md)를 참조하세요.

## Kubernetes 배포
Kubernetes를 사용한 배포 방법은 [k8s-deploy/README.md](k8s-deploy/README.md)를 참조하세요.
