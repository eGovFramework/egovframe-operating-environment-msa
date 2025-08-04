# EgovSearch 설정
### `docker-deploy/docker-compose.yml`
```
  egov-search:
    environment:
      - APP_SEARCH_CONFIG_PATH=/app/config/searchConfig-docker.json
      - OPENSEARCH_KEYSTORE_PATH=/opt/java/openjdk/lib/security/cacerts
    volumes:
      - ${EGOVSEARCH_CONFIG_PATH}:/app/config:ro
      - ${EGOVSEARCH_MODEL_PATH}:/app/model
      - ${EGOVSEARCH_CACERTS_PATH}:/app/cacerts:ro
      - ${EGOVSEARCH_EXAMPLE_PATH}:/app/example
```

1. **볼륨 마운트 구조**:
- 호스트 시스템
    ```
    ../EgovSearch-config/
        ├── config/
        │   └── searchConfig-docker.json
        ├── model/
        │   ├── model.onnx
        │   └── tokenizer.json
        ├── cacerts/
        │   └── cacerts
        └── example/
            ├── stoptags.txt
            ├── synonyms.txt
            └── dictionaryRules.txt
    ```
- 컨테이너 내부
    ```text
    /app/
        ├── config/
        │   └── searchConfig-docker.json
        ├── model/
        │   ├── model.onnx
        │   └── tokenizer.json
        ├── cacerts/
        │   └── cacerts
        └── example/
            ├── stoptags.txt
            ├── synonyms.txt
            └── dictionaryRules.txt
    ```
2. **각 볼륨의 목적**:
    - `config`: 검색 설정 파일 (읽기 전용)
    - `model`: ML 모델 파일
    - `cacerts` : SSL 인증서 (읽기 전용)
    - `example`: 사전 및 규칙 파일

`EgovSearch-config` 디렉토리에 다음 구성을 확인합니다:

3. `config/searchConfig-docker.json` 설정
```json
{
    "modelPath": "/app/model/model.onnx",
    "tokenizerPath": "/app/model/tokenizer.json",
    "stopTagsPath": "/app/example/stoptags.txt",
    "synonymsPath": "/app/example/synonyms.txt",
    "dictionaryRulesPath": "/app/example/dictionaryRules.txt"
}
```
`EgovSearch/Dockerfile` 에서 SSL 인증서 파일을 JDK 보안 디렉토리로 복사 후 JAR 파일이 실행되도록 구성합니다.
```Dockerfile
# 기본 이미지 설정
FROM eclipse-temurin:17-jre-jammy
...

# 시작 스크립트 생성
RUN echo '#!/bin/sh' > /app/start.sh && \
    echo 'cp /app/cacerts/* /opt/java/openjdk/lib/security/' >> /app/start.sh && \
    echo 'exec java -jar /app/app.jar' >> /app/start.sh && \
    chmod +x /app/start.sh

...
```
### 비고
EgovSearch 서비스를 사용하기 위해서는 OpenSearch 서버가 구성되어있어야합니다.   
관련 사항은 [EgovSearch_REAMDME](https://github.com/eGovFramework/egovframe-common-components-msa-krds/tree/main/EgovSearch) 참조