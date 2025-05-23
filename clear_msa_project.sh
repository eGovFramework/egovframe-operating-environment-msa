#!/bin/bash

# [1] 삭제 대상 디렉토리
DIRS=(
  common-components-msa-temp
  ConfigServer
  EgovAuthor
  EgovBoard
  EgovCmmnCode
  EgovLogin
  EgovLoginPolicy
  EgovMain
  EgovMobileId
  EgovQuestionnaire
  EgovSearch-Config
  EgovSearch
  EurekaServer
  GatewayServer
)

echo "Are you sure you want to delete the imported components directories? (yes/no)"
read -r answer

if [ "$answer" == "yes" ]; then
  for dir in "${DIRS[@]}"; do
    if [ -d "$dir" ]; then
      echo "[INFO] Deleting $dir..."
      rm -rf "$dir"
    else
      echo "[SKIP] $dir does not exist."
    fi
  done
  echo "[DONE] Selected directories have been deleted."
else
  echo "[CANCELLED] No directories were deleted."
fi