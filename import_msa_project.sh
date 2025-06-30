#!/bin/bash

# [1] 설정
REPO_URL="https://github.com/eGovFramework/egovframe-common-components-msa-krds"
TAG="v4.3.2"
TMP_DIR="./common-components-msa-temp"
echo "Import Project - egovframe-common-components-msa $TAG"

# [2] 복사 대상 디렉토리
DIRS=(
  ConfigServer
  EgovAuthor
  EgovBoard
  EgovCmmnCode
  EgovLogin
  EgovMain
  EgovMobileId
  EgovQuestionnaire
  EgovSearch-Config
  EgovSearch
  EurekaServer
  GatewayServer
)

# [3] 임시 디렉토리로 소스 다운로드 및 압축 해제
echo "[INFO] Downloading source from GitHub..."
mkdir -p "$TMP_DIR"
curl -L "$REPO_URL/archive/refs/tags/$TAG.zip" -o "$TMP_DIR/source.zip"

echo "[INFO] Extracting..."
unzip -q "$TMP_DIR/source.zip" -d "$TMP_DIR"

EXTRACTED_DIR="$TMP_DIR/egovframe-common-components-msa-krds-${TAG#v}"

# [4] 현재 디렉토리로 필요한 디렉토리 복사
for dir in "${DIRS[@]}"; do
  echo "[INFO] Copying $dir..."
  cp -r "$EXTRACTED_DIR/$dir" .
  
    # 특정 디렉토리는 Dockerfile 복사 생략
  if [ "$dir" == "EgovSearch-Config" ]; then
    echo "[SKIP] Skipping Dockerfile copy for $dir"
    continue
  fi
  
  cp ./docker-deploy/"$dir"/Dockerfile* "./$dir"
done

# [5] 임시 파일 제거
echo "[INFO] Cleaning up..."
#rm -rf "$TMP_DIR"

echo "[DONE] All selected components have been copied."

