#!/bin/bash
set -e
set -o pipefail

echo "===== deploy start ====="

# 1. 서비스 디렉토리 이동
mkdir -p /home/ubuntu/${SERVICE_NAME}
cd /home/ubuntu/${SERVICE_NAME}

# 2. docker-compose.yml download
echo "Download latest compose..."
aws s3 cp \
  s3://bs-bucket-a/${SERVICE_NAME}/deploy/docker-compose.yml \
  docker-compose.yml

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
  --path /prod/board-system/${SERVICE_NAME} \
  --with-decryption \
  --query "Parameters[*].[Name,Value]" \
  --output text \
| awk '{split($1,a,"/"); print a[length(a)]"="$2}' >> .env

if [ ! -s .env ]; then
  echo ".env generation failed"
  exit 1
fi

# 4. ECR 로그인
echo "Login to ECR..."
aws ecr get-login-password --region ap-northeast-2 \
| docker login \
  --username AWS \
  --password-stdin 267837905230.dkr.ecr.ap-northeast-2.amazonaws.com

# 5. 최신 이미지 pull & 재시작
echo "Docker compose deploy..."
docker compose pull || exit 1
docker compose up -d
docker ps

echo "===== deploy finished ====="