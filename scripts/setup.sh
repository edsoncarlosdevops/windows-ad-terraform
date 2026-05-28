#!/bin/bash
# Script para preparar o ambiente antes do terraform init
# Cria o bucket de state com nome unico

RANDOM_SUFFIX=$(date +%s | md5 | head -c 8)
BUCKET="terraform-state-windows-ad-${RANDOM_SUFFIX}"
REGION="us-east-1"

echo "=== Setup do ambiente ==="
echo "Bucket: $BUCKET"

# Cria o bucket
aws s3 mb "s3://$BUCKET" --region $REGION
aws s3api put-bucket-versioning \
    --bucket $BUCKET \
    --versioning-configuration Status=Enabled

echo "Bucket criado com versionamento"

# Atualiza o provider.tf com o nome do bucket
cd environments/dev
sed -i '' "s/bucket         = \"terraform-state-windows-ad.*\"/bucket         = \"$BUCKET\"/" provider.tf

echo ""
echo "Setup concluido! Agora execute:"
echo "  cd environments/dev"
echo "  terraform init"
echo "  terraform apply"
