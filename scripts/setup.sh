#!/bin/bash
# Script para preparar o ambiente antes do terraform init
# Cria o bucket de state se nao existir

BUCKET="terraform-state-windows-ad"
REGION="us-east-1"

echo "=== Setup do ambiente ==="

# Verificar se o bucket existe
if aws s3 ls "s3://$BUCKET" 2>&1 | grep -q 'NoSuchBucket'; then
    echo "Criando bucket $BUCKET..."
    aws s3 mb "s3://$BUCKET" --region $REGION
    aws s3api put-bucket-versioning \
        --bucket $BUCKET \
        --versioning-configuration Status=Enabled
    echo "Bucket criado com versionamento habilitado"
else
    echo "Bucket $BUCKET ja existe"
fi

echo "Setup concluido. Agora execute:"
echo "  cd environments/dev"
echo "  terraform init"
echo "  terraform apply"
