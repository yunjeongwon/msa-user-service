#!/bin/bash
set -e

echo "===== deploy start ====="

# 1. 서비스 디렉토리 이동
cd /home/ubuntu/msa-user-service

# 2. 최신 compose / deploy 스크립트 반영
echo "Updating source..."
git fetch origin
git reset --hard origin/master
git clean -fd

# 3. SSM Parameter → .env 생성
echo "Fetching SSM parameters..."

# common
aws ssm get-parameters-by-path \
  --region ap-northeast-2 \
  --path /prod/board-system/common \
  --with-decryption \
  --query "Parameters[*].[Name,Value]" \
  --output text \
| awk '{split($1,a,"/"); print a[length(a)]"="$2}' > .env

# user-service 전용
aws ssm get-parameters-by-path \
  --region ap-northeast-2 \
  --path /prod/board-system/user-service \
  --with-decryption \
  --query "Parameters[*].[Name,Value]" \
  --output text \
| awk '{split($1,a,"/"); print a[length(a)]"="$2}' >> .env

echo ".env generated"

# 4. ECR 로그인
echo "Login to ECR..."
aws ecr get-login-password --region ap-northeast-2 \
| docker login \
  --username AWS \
  --password-stdin 267837905230.dkr.ecr.ap-northeast-2.amazonaws.com

# 5. 최신 이미지 pull & 재시작
echo "Docker compose deploy..."
docker compose pull
docker compose up -d

echo "===== deploy finished ====="