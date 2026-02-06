#!/bin/bash
# Script de setup inicial para estudiantes con UV
# UV es un gestor de paquetes Python ultrarrápido (10-100x más rápido que pip)

set -e  # Exit on error

echo "================================================"
echo "🚀 Setup Inicial - dbt + AWS Athena (con UV ⚡)"
echo "================================================"
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para manejar errores
error_exit() {
    echo -e "${RED}✗${NC} Error: $1"
    exit 1
}

# 1. Verificar Python
echo "1️⃣  Verificando Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✓${NC} Python instalado: $PYTHON_VERSION"
else
    error_exit "Python 3 no encontrado. Por favor instala Python 3.8+"
fi

# 2. Verificar/Instalar UV
echo ""
echo "2️⃣  Verificando UV..."
if ! command -v uv &> /dev/null; then
    echo -e "${YELLOW}⚠${NC}  UV no encontrado. Instalando..."
    echo -e "${BLUE}UV es un gestor de paquetes Python 10-100x más rápido que pip${NC}"
    echo ""
    
    # Instalar UV
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    # Agregar UV al PATH para esta sesión
    export PATH="$HOME/.cargo/bin:$PATH"
    
    # Verificar instalación
    if command -v uv &> /dev/null; then
        echo -e "${GREEN}✓${NC} UV instalado correctamente"
        echo -e "${BLUE}ℹ${NC}  UV se agregó a tu PATH. Cierra y abre la terminal si no funciona después."
    else
        error_exit "No se pudo instalar UV. Intenta manualmente: curl -LsSf https://astral.sh/uv/install.sh | sh"
    fi
else
    UV_VERSION=$(uv --version 2>&1)
    echo -e "${GREEN}✓${NC} UV ya está instalado: $UV_VERSION"
fi
echo ""

# 3. Crear entorno virtual con UV
echo "3️⃣  Configurando entorno virtual con UV..."
if [ ! -d ".venv" ]; then
    echo "Creando entorno virtual..."
    uv venv
    echo -e "${GREEN}✓${NC} Entorno virtual creado (.venv/)"
else
    echo -e "${GREEN}✓${NC} Entorno virtual ya existe"
fi

# Activar entorno virtual
source .venv/bin/activate
echo -e "${GREEN}✓${NC} Entorno virtual activado"
echo ""

# 4. Instalar dependencias con UV (ultrarrápido)
echo "4️⃣  Instalando dependencias Python con UV..."
echo -e "${BLUE}ℹ${NC}  Esto será mucho más rápido que pip..."
if [ -f "requirements.txt" ]; then
    uv pip install -r requirements.txt
    echo -e "${GREEN}✓${NC} Dependencias instaladas con UV ⚡"
else
    error_exit "No se encontró requirements.txt"
fi
echo ""

# 5. Instalar dependencias dbt
echo "5️⃣  Instalando paquetes dbt..."
if [ -d "adventureworks" ]; then
    cd adventureworks
    if dbt deps --quiet 2>&1; then
        echo -e "${GREEN}✓${NC} Paquetes dbt instalados"
    else
        echo -e "${YELLOW}⚠${NC}  Advertencia al instalar paquetes dbt"
        echo "   Puedes intentar manualmente: cd adventureworks && dbt deps"
    fi
    cd ..
else
    error_exit "No se encuentra el directorio adventureworks"
fi
echo ""

# 6. Verificar AWS CLI
echo "6️⃣  Verificando AWS CLI..."
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1)
    echo -e "${GREEN}✓${NC} AWS CLI instalado: $AWS_VERSION"
else
    error_exit "AWS CLI no encontrado. Instalar desde: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
fi

# 7. Verificar credenciales AWS
echo ""
echo "7️⃣  Verificando credenciales AWS..."
ERROR_MSG=$(aws sts get-caller-identity --query Account --output text 2>&1)
ERROR_CODE=$?

if [ $ERROR_CODE -eq 0 ]; then
    ACCOUNT_ID=$ERROR_MSG
    echo -e "${GREEN}✓${NC} Credenciales AWS configuradas"
    echo "   Account ID: $ACCOUNT_ID"
else
    echo -e "${RED}✗${NC} Credenciales AWS no configuradas o inválidas"
    echo ""
    
    # Detectar tipo de error
    if echo "$ERROR_MSG" | grep -q "InvalidClientTokenId"; then
        echo "🔴 Error: Credenciales inválidas o expiradas"
        echo ""
        echo "Tus credenciales AWS existen pero no son válidas."
        echo ""
        echo "Solución:"
        echo "  1. Ve a AWS Console/Academy y obtén nuevas credenciales"
        echo "  2. Si usas AWS Academy, copia las credenciales temporales"
        echo "  3. Edita: ${YELLOW}~/.aws/credentials${NC}"
        echo ""
        echo "El archivo debe tener:"
        echo "  [default]"
        echo "  aws_access_key_id = TU_ACCESS_KEY"
        echo "  aws_secret_access_key = TU_SECRET_KEY"
        echo "  aws_session_token = TU_SESSION_TOKEN  ${YELLOW}<-- IMPORTANTE!${NC}"
        echo ""
        echo "También puedes exportar las variables:"
        echo "  ${YELLOW}export AWS_ACCESS_KEY_ID=...${NC}"
        echo "  ${YELLOW}export AWS_SECRET_ACCESS_KEY=...${NC}"
        echo "  ${YELLOW}export AWS_SESSION_TOKEN=...${NC}"
    elif echo "$ERROR_MSG" | grep -q "could not be found"; then
        echo "🔴 Error: No hay credenciales configuradas"
        echo ""
        echo "Si usas AWS Academy o credenciales temporales:"
        echo "  1. Ve a AWS Academy/Console"
        echo "  2. Copia las credenciales (Access Key, Secret Key, Session Token)"
        echo "  3. Edita: ${YELLOW}~/.aws/credentials${NC}"
        echo ""
        echo "Si usas credenciales permanentes:"
        echo "  Ejecuta: ${YELLOW}aws configure${NC}"
    else
        echo "🔴 Error desconocido:"
        echo "$ERROR_MSG"
    fi
    echo ""
    echo "Después de configurar, ejecuta este script de nuevo."
    exit 1
fi

# 8. Crear/actualizar archivo .env
echo ""
echo "8️⃣  Configurando variables de entorno..."
if [ ! -f .env ]; then
    cat > .env << EOF
# Configuración AWS para dbt-dimensional-modelling
export AWS_ACCOUNT_ID=$ACCOUNT_ID
export AWS_REGION=us-east-1
export RAW_BUCKET=dbt-adventureworks-raw-$ACCOUNT_ID
export SILVER_BUCKET=dbt-adventureworks-silver-$ACCOUNT_ID

# Para cargar estas variables, ejecuta:
# source .env

# Activar entorno virtual UV
source .venv/bin/activate
EOF
    echo -e "${GREEN}✓${NC} Archivo .env creado"
else
    echo -e "${YELLOW}⚠${NC}  Archivo .env ya existe (no se modificó)"
fi

# 9. Actualizar profiles.yml con Account ID
echo ""
echo "9️⃣  Actualizando configuración dbt..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/YOUR_ACCOUNT_ID/$ACCOUNT_ID/g" adventureworks/profiles.yml
else
    # Linux
    sed -i "s/YOUR_ACCOUNT_ID/$ACCOUNT_ID/g" adventureworks/profiles.yml
fi
echo -e "${GREEN}✓${NC} profiles.yml actualizado con tu Account ID"

# Resumen final
echo ""
echo "================================================"
echo -e "${GREEN}✅ Setup inicial completado con UV ⚡${NC}"
echo "================================================"
echo ""
echo "📝 Próximos pasos:"
echo ""
echo "1. Cargar variables de entorno y activar venv:"
echo "   ${YELLOW}source .env${NC}"
echo ""
echo "2. Crear infraestructura en AWS:"
echo "   ${YELLOW}make setup-aws${NC}"
echo ""
echo "3. Verificar conexión dbt:"
echo "   ${YELLOW}make dbt-debug${NC}"
echo ""
echo "4. Ejecutar modelos:"
echo "   ${YELLOW}make dbt-run${NC}"
echo ""
echo "5. Ver documentación:"
echo "   ${YELLOW}make dbt-docs-serve${NC}"
echo ""
echo "Para ver todos los comandos: ${YELLOW}make help${NC}"
echo ""
echo "📚 Lee README_AWS.md para más información"
echo ""
echo -e "${BLUE}💡 UV instaló todo 10-100x más rápido que pip!${NC}"
echo "================================================"
