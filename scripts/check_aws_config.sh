#!/bin/bash
# Script simple para verificar la configuración de AWS

echo "================================================"
echo "Verificación de Configuración AWS"
echo "================================================"
echo ""

# Verificar AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI no está instalado"
    echo "   Instalar: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

echo "✓ AWS CLI instalado: $(aws --version)"
echo ""

# Verificar credenciales
echo "Verificando credenciales..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ No hay credenciales de AWS configuradas"
    echo ""
    echo "Para configurar AWS CLI, ejecuta:"
    echo "  aws configure"
    echo ""
    echo "Necesitarás:"
    echo "  - AWS Access Key ID"
    echo "  - AWS Secret Access Key"
    echo "  - Default region (ej: us-east-1)"
    exit 1
fi

# Mostrar información
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region || echo "us-east-1")
USER_ARN=$(aws sts get-caller-identity --query Arn --output text)

echo "✓ Credenciales válidas"
echo ""
echo "Información de la cuenta:"
echo "  Account ID: $ACCOUNT_ID"
echo "  Region:     $REGION"
echo "  User/Role:  $USER_ARN"
echo ""

# Verificar permisos básicos
echo "Verificando permisos..."

# S3
if aws s3 ls &> /dev/null; then
    echo "✓ Permisos S3: OK"
else
    echo "⚠️  Permisos S3: LIMITADOS O NO DISPONIBLES"
fi

# Athena
if aws athena list-work-groups --region $REGION &> /dev/null; then
    echo "✓ Permisos Athena: OK"
else
    echo "⚠️  Permisos Athena: LIMITADOS O NO DISPONIBLES"
fi

echo ""
echo "================================================"
echo "Nombres de buckets que se usarán:"
echo "  Raw:    dbt-adventureworks-raw-$ACCOUNT_ID"
echo "  Silver: dbt-adventureworks-silver-$ACCOUNT_ID"
echo "================================================"
echo ""
echo "Si todo está OK, ejecuta: make setup-aws"
