#!/bin/bash
# Script para configurar credenciales de AWS (especialmente AWS Academy)

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Configuración de Credenciales AWS                     ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "Este script te ayudará a configurar tus credenciales AWS."
echo ""
echo "¿Qué tipo de credenciales tienes?"
echo "  1) AWS Academy (credenciales temporales con session token)"
echo "  2) IAM User (credenciales permanentes)"
echo "  3) Ya tengo las variables exportadas"
echo ""
read -p "Selecciona (1/2/3): " CRED_TYPE

case $CRED_TYPE in
    1)
        echo ""
        echo -e "${YELLOW}Configurando credenciales de AWS Academy...${NC}"
        echo ""
        echo "Pasos:"
        echo "1. Ve a tu AWS Academy Lab"
        echo "2. Haz clic en 'AWS Details'"
        echo "3. Copia las credenciales (deberías ver algo como:)"
        echo ""
        echo "   [default]"
        echo "   aws_access_key_id=ASIA..."
        echo "   aws_secret_access_key=..."
        echo "   aws_session_token=..."
        echo ""
        read -p "¿Ya tienes las credenciales copiadas? (y/n): " READY
        
        if [ "$READY" != "y" ]; then
            echo "Ve a copiarlas primero y ejecuta este script de nuevo."
            exit 0
        fi
        
        echo ""
        echo "Pega tus credenciales AWS aquí:"
        echo "(Pega las 3 líneas: aws_access_key_id, aws_secret_access_key, aws_session_token)"
        echo "Presiona Ctrl+D cuando termines"
        echo ""
        
        # Crear directorio .aws si no existe
        mkdir -p ~/.aws
        
        # Leer entrada del usuario
        TEMP_FILE=$(mktemp)
        cat > "$TEMP_FILE"
        
        # Parsear las credenciales
        ACCESS_KEY=$(grep -i "aws_access_key_id" "$TEMP_FILE" | cut -d'=' -f2 | tr -d ' ')
        SECRET_KEY=$(grep -i "aws_secret_access_key" "$TEMP_FILE" | cut -d'=' -f2 | tr -d ' ')
        SESSION_TOKEN=$(grep -i "aws_session_token" "$TEMP_FILE" | cut -d'=' -f2 | tr -d ' ')
        
        rm "$TEMP_FILE"
        
        if [ -z "$ACCESS_KEY" ] || [ -z "$SECRET_KEY" ] || [ -z "$SESSION_TOKEN" ]; then
            echo -e "${RED}Error: No se pudieron parsear las credenciales${NC}"
            echo "Asegúrate de pegar las 3 líneas completas."
            exit 1
        fi
        
        # Escribir a ~/.aws/credentials
        cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = $ACCESS_KEY
aws_secret_access_key = $SECRET_KEY
aws_session_token = $SESSION_TOKEN
EOF
        
        # Configurar región si no existe
        if [ ! -f ~/.aws/config ]; then
            cat > ~/.aws/config << EOF
[default]
region = us-east-1
output = json
EOF
        fi
        
        echo -e "${GREEN}✓${NC} Credenciales configuradas en ~/.aws/credentials"
        ;;
        
    2)
        echo ""
        echo -e "${YELLOW}Configurando IAM User (credenciales permanentes)...${NC}"
        echo ""
        echo "Necesitarás:"
        echo "  - AWS Access Key ID"
        echo "  - AWS Secret Access Key"
        echo ""
        
        read -p "AWS Access Key ID: " ACCESS_KEY
        read -p "AWS Secret Access Key: " SECRET_KEY
        read -p "Default region [us-east-1]: " REGION
        REGION=${REGION:-us-east-1}
        
        # Crear directorio .aws si no existe
        mkdir -p ~/.aws
        
        # Escribir a ~/.aws/credentials
        cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = $ACCESS_KEY
aws_secret_access_key = $SECRET_KEY
EOF
        
        # Escribir a ~/.aws/config
        cat > ~/.aws/config << EOF
[default]
region = $REGION
output = json
EOF
        
        echo -e "${GREEN}✓${NC} Credenciales configuradas"
        ;;
        
    3)
        echo ""
        echo "Perfecto. Asegúrate de tener estas variables exportadas:"
        echo ""
        echo "  export AWS_ACCESS_KEY_ID=..."
        echo "  export AWS_SECRET_ACCESS_KEY=..."
        echo "  export AWS_SESSION_TOKEN=...  (si usas credenciales temporales)"
        echo ""
        echo "Puedes verificar con:"
        echo "  echo \$AWS_ACCESS_KEY_ID"
        ;;
        
    *)
        echo "Opción inválida"
        exit 1
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Verificando credenciales..."
echo ""

if aws sts get-caller-identity &> /dev/null; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
    
    echo -e "${GREEN}✅ ¡Credenciales válidas!${NC}"
    echo ""
    echo "  Account ID: $ACCOUNT_ID"
    echo "  User/Role:  $USER_ARN"
    echo ""
    echo "Ya puedes ejecutar:"
    echo "  ${YELLOW}bash scripts/setup.sh${NC}"
else
    echo -e "${RED}✗ Las credenciales no funcionan${NC}"
    echo ""
    echo "Verifica que copiaste todo correctamente."
    echo "En AWS Academy, las credenciales expiran después de unas horas."
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✓ Configuración completa${NC}"
echo ""
