# EgovMobileId 설정

###  `docker-deploy/docker-compose.yml`
    ```
    egov-mobileid:
        environment:
        - APP_VERIFY_FILE_PATH=/app/config/verifyConfig-docker.json
        volumes:
        - ${EGOVMOBILEID_CONFIG_PATH}:/app/config:ro
    ```

1. **볼륨 마운트**:
    - `${EGOVMOBILEID_CONFIG_PATH}:/app/config:ro`
    - 호스트의 `EGOVMOBILEID_CONFIG_PATH` 경로(예: `../EgovMobileId/config`)가 컨테이너의 `/app/config` 디렉토리로 마운트됩니다.
    - `:ro`는 read-only 마운트를 의미합니다.
2. **설정 파일 경로**:
    - `APP_VERIFY_FILE_PATH=/app/config/verifyConfig-docker.json`
    - 애플리케이션이 참조하는 설정 파일의 컨테이너 내부 경로입니다.
3. 실제 파일 구조

- 호스트 시스템
    ```text
    ../EgovMobileId/config/
        ├── verifyConfig-docker.json
        ├── sp.wallet
        └── sp.did
    ```
- 컨테이너 내부
    ```text
    /app/config/
        ├── verifyConfig-docker.json
        ├── sp.wallet
        └── sp.did
    ```

### `EgovMobileId/config`

- `verifyConfig-docker.json` 설정
    ```json
    {
        "blockchain": {
            "account": "egovframe.sp",
            "serverDomain": "https://bcdev.mobileid.go.kr:18888",
            "connectTimeout": "3000",
            "readTimeout": "3000",
            "useCache": true,
            "sdkDetailLog": true
        },
        "didWalletFile": {
            "keymanagerPath": "/app/config/sp.wallet",
            "keymanagerPassword": "egovframe",
            "signKeyId": "omni.sp",
            "encryptKeyId": "omni.sp.rsa",
            "didFilePath": "/app/config/sp.did"
        },
        "sp": {
            "serverDomain": "http://61.253.112.177:9991",
            "biImageUrl": "https://www.mobileId.go.kr/resources/images/main/mdl_ico_homepage.ico"
        }
    }
    ```

### 필수 파일 구성
- `sp.wallet`: 전자지갑 파일
- `sp.did`: DID 파일

### 비고
모바일신분증 개발을 위해서는 모바일 신분증 지원센터에 서비스를 접수하고 운영용 Wallet과 DID를 받는 등의 절차가 필요하므로 자세한 사항은 [EgovMoibileId_README](https://github.com/eGovFramework/egovframe-common-components-msa-krds/tree/main/EgovMobileId) 참조