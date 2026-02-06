# 🚀 dbt Dimensional Modelling en AWS Athena

Tutorial paso a paso para estudiantes: Cómo crear un modelo dimensional en AWS usando dbt, S3 y Athena.

## 📋 ¿Qué vamos a construir?

Este proyecto muestra cómo transformar datos raw (seeds CSV) en un modelo dimensional usando:

- **AWS S3**: Almacenamiento de datos (capa raw y silver)
- **AWS Athena**: Motor de queries SQL sobre S3
- **dbt (data build tool)**: Transformación de datos y creación del modelo dimensional

### Arquitectura de Capas

```
┌─────────────────────────────────────────────────────────┐
│  Seeds (CSV) → S3 Raw → Athena Tables (Raw)            │
│                    ↓                                     │
│         dbt Transformations (Athena)                    │
│                    ↓                                     │
│        S3 Silver → Dimensional Model (Marts)            │
│         ├── Dimensions (dim_*)                          │
│         ├── Facts (fct_*)                               │
│         └── One Big Table (obt_*)                       │
└─────────────────────────────────────────────────────────┘
```

## 🎯 Requisitos Previos

### 1. Cuenta de AWS
- Tener una cuenta de AWS activa
- Acceso a: S3, Athena, y permisos de IAM básicos

### 2. AWS CLI Configurado

#### Opción A: Credenciales Permanentes (IAM User)
```bash
# Verificar si está instalado
aws --version

# Si no está instalado, descarga desde:
# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

# Configurar credenciales
aws configure
# Ingresa:
#   AWS Access Key ID: [tu-access-key]
#   AWS Secret Access Key: [tu-secret-key]
#   Default region: us-east-1
#   Default output format: json
```

### 3. UV (Gestor de Paquetes Python) - RECOMENDADO ⚡

Este proyecto usa **UV** en lugar de pip. UV es 10-100x más rápido:

```bash
# UV se instala automáticamente con el setup script
# O instala manualmente:
curl -LsSf https://astral.sh/uv/install.sh | sh

# Agregar a PATH (reinicia terminal después)
export PATH="$HOME/.cargo/bin:$PATH"
```

**Ventajas de UV:**
- ⚡ 10-100x más rápido que pip
- 🦀 Escrito en Rust (ultra optimizado)
- 🔄 100% compatible con pip/requirements.txt
- 🚀 Ideal para Raspberry Pi y sistemas con recursos limitados
- ✅ Funciona perfectamente con dbt

📘 **Ver guía completa**: [docs/UV_GUIDE.md](docs/UV_GUIDE.md)

#### Opción B: AWS Academy (Credenciales Temporales) ⭐ RECOMENDADO PARA ESTUDIANTES
Si usas AWS Academy, las credenciales incluyen un **Session Token** que es temporal:

```bash
# Método 1: Script interactivo (más fácil)
bash scripts/configure_aws_credentials.sh

# Método 2: Manual
# 1. Ve a AWS Academy → AWS Details
# 2. Copia las credenciales (3 líneas)
# 3. Edita: ~/.aws/credentials
# 4. Pega las 3 líneas:

[default]
aws_access_key_id = ASIA...
aws_secret_access_key = ...
aws_session_token = ...   ← ¡IMPORTANTE! No olvides esta línea

# 5. Verifica que funciona:
aws sts get-caller-identity
```

**⚠️ Importante:** Las credenciales de AWS Academy expiran después de unas horas. Necesitarás actualizarlas cuando empiece una nueva sesión de lab.

### 3. Python 3.8+
```bash
python --version
# o
python3 --version
```

### 4. Make (opcional pero recomendado)
En Linux/Mac viene preinstalado. En Windows puedes usar WSL o Git Bash.

## 🛠️ Instalación

### Paso 1: Clonar el Repositorio
```bash
git clone <tu-repo>
cd dbt-dimensional-modelling
```

### Paso 2: Verificar AWS
```bash
# Opción 1: Usar el script
bash scripts/check_aws_config.sh

# Opción 2: Verificar manualmente
aws sts get-caller-identity
```

Deberías ver tu Account ID y ARN del usuario.

### Paso 3: Instalar Dependencias de Python
```bash
make install
# o manualmente:
pip install -r requirements.txt
cd adventureworks && dbt deps
```

## 🚀 Setup de AWS (Primer Uso)

Este comando hace todo el setup automáticamente:

```bash
make setup-aws
```

**¿Qué hace este comando?**
1. ✅ Crea 2 buckets en S3 (raw y silver) usando tu Account ID
2. ✅ Sube todos los CSVs de seeds a S3 raw
3. ✅ Crea la database en Athena
4. ✅ Crea tablas externas en Athena apuntando a los CSVs

Los buckets se crean con nombres únicos basados en tu Account ID:
- `dbt-adventureworks-raw-123456789012`
- `dbt-adventureworks-silver-123456789012`

### Ver el Progreso
```bash
# Ver contenido de los buckets
make list-s3

# Ver configuración actual
make show-config
```

## 📝 Configurar dbt para Athena

### Paso 1: Obtener tu Account ID
```bash
aws sts get-caller-identity --query Account --output text
```

### Paso 2: Exportar como Variable de Entorno
```bash
# Linux/Mac
export AWS_ACCOUNT_ID=123456789012

# Windows (PowerShell)
$env:AWS_ACCOUNT_ID="123456789012"

# Windows (CMD)
set AWS_ACCOUNT_ID=123456789012
```

**IMPORTANTE**: O puedes editar `adventureworks/profiles.yml` y reemplazar `{{ env_var('AWS_ACCOUNT_ID', 'YOUR_ACCOUNT_ID') }}` con tu Account ID directamente.

### Paso 3: Verificar Conexión
```bash
make dbt-debug
```

Deberías ver: ✅ `Connection test: [OK connection ok]`

## 🎨 Ejecutar las Transformaciones dbt

### Crear el Modelo Dimensional (Capa Silver)
```bash
make dbt-run
```

Esto ejecutará todos los modelos dbt y creará:
- **Dimensiones**: `dim_customer`, `dim_product`, `dim_address`, etc.
- **Hechos**: `fct_sales`
- **OBT**: `obt_sales` (One Big Table para análisis)

### Ver el Lineage y Documentación
```bash
make dbt-docs-generate
make dbt-docs-serve
```

Abre tu navegador en `http://localhost:8080` para ver:
- 📊 DAG del proyecto
- 📖 Documentación de tablas y columnas
- 🔗 Lineage de datos

## 🔍 Consultar los Datos

### Opción 1: AWS Console
1. Ve a: https://console.aws.amazon.com/athena/
2. Selecciona la database `adventureworks`
3. Queries de ejemplo:

```sql
-- Ver dimensión de productos
SELECT * FROM marts.dim_product LIMIT 10;

-- Ver hechos de ventas
SELECT * FROM marts.fct_sales LIMIT 10;

-- Análisis de ventas por categoría
SELECT 
    product_category_name,
    COUNT(*) as total_orders,
    SUM(revenue) as total_revenue
FROM marts.obt_sales
GROUP BY product_category_name
ORDER BY total_revenue DESC;
```

### Opción 2: AWS CLI
```bash
aws athena start-query-execution \
    --query-string "SELECT * FROM adventureworks.marts.dim_product LIMIT 10" \
    --result-configuration "OutputLocation=s3://dbt-adventureworks-silver-$AWS_ACCOUNT_ID/query-results/" \
    --region us-east-1
```

## 📂 Estructura del Proyecto

```
dbt-dimensional-modelling/
├── Makefile                      # Comandos automatizados
├── requirements.txt              # Dependencias Python
├── scripts/
│   ├── check_aws_config.sh      # Verificar AWS
│   └── create_athena_tables.py  # Crear tablas raw
├── adventureworks/
│   ├── dbt_project.yml          # Config de dbt
│   ├── profiles.yml             # Conexión Athena
│   ├── models/
│   │   ├── sources.yml          # Definición de sources (raw)
│   │   └── marts/               # Modelos dimensionales
│   │       ├── dim_*.sql        # Dimensiones
│   │       ├── fct_*.sql        # Hechos
│   │       └── obt_*.sql        # One Big Table
│   └── seeds/                   # CSVs originales
│       ├── date/
│       ├── person/
│       ├── production/
│       └── sales/
└── docs/                        # Documentación adicional
```

## 🎓 Comandos Útiles para Estudiantes

### Comandos Make Disponibles
```bash
make help              # Ver todos los comandos disponibles
make check-aws         # Verificar configuración AWS
make setup-aws         # Setup completo de AWS
make upload-seeds      # Re-subir seeds a S3
make dbt-run           # Ejecutar modelos dbt
make dbt-test          # Ejecutar tests
make dbt-docs-serve    # Ver documentación
make list-s3           # Ver contenido de buckets
make show-config       # Mostrar configuración
```

### Comandos dbt Directos
```bash
cd adventureworks

# Ejecutar un modelo específico
dbt run --select dim_product --target athena

# Ejecutar todos los modelos de una carpeta
dbt run --select marts --target athena

# Ver qué se va a ejecutar (dry-run)
dbt run --select marts --target athena --dry-run

# Ejecutar tests
dbt test --target athena

# Compilar sin ejecutar
dbt compile --target athena
```

## 🧹 Limpieza (Opcional)

**⚠️ CUIDADO: Esto eliminará todos los datos en S3**

```bash
make clean-buckets
```

## 🐛 Troubleshooting

### Error: "AWS no está configurado" o "InvalidClientTokenId"

**Causa:** Credenciales AWS no configuradas, inválidas o expiradas.

**Solución:**

```bash
# Opción 1: Script interactivo (recomendado)
make configure-aws
# o
bash scripts/configure_aws_credentials.sh

# Opción 2: Manual para AWS Academy
# 1. Ve a AWS Academy → AWS Details
# 2. Copia las credenciales (3 líneas)
# 3. Edita: nano ~/.aws/credentials
# 4. Pega:
[default]
aws_access_key_id = ASIA...
aws_secret_access_key = ...
aws_session_token = ...   ← ¡NO OLVIDES ESTA LÍNEA!

# Opción 3: IAM User permanente
aws configure
# Ingresa access key y secret key (sin session token)

# Verificar que funciona:
aws sts get-caller-identity
```

**⚠️ Importante para AWS Academy:**
- Las credenciales expiran después de unas horas
- Necesitarás renovarlas cuando inicies un nuevo lab
- Usa `make configure-aws` cada vez que cambien

### Error: "Bucket already exists"
Normal si ya ejecutaste `make setup-aws` antes. Puedes ignorarlo.

### Error: "Access Denied" en Athena
Verifica que tu usuario IAM tenga permisos para:
- S3: `s3:*`
- Athena: `athena:*`
- Glue: `glue:*` (Athena usa Glue Data Catalog)

### Error: dbt connection failed
1. Verifica credenciales: `aws sts get-caller-identity`
2. Verifica que `AWS_ACCOUNT_ID` esté exportado: `echo $AWS_ACCOUNT_ID`
3. Verifica que los buckets existan: `make list-s3`
4. Ejecuta: `make dbt-debug`

### Credenciales no persisten entre sesiones
Si usas AWS Academy, las credenciales son temporales. Agrega esto a tu `~/.bashrc` o `~/.zshrc`:

```bash
# Cargar credenciales AWS automáticamente
if [ -f ~/.aws/credentials ]; then
    export AWS_PROFILE=default
fi
```

## 📚 Recursos Adicionales

- [dbt Documentation](https://docs.getdbt.com/)
- [AWS Athena User Guide](https://docs.aws.amazon.com/athena/)
- [dbt-athena Adapter](https://github.com/dbt-athena/dbt-athena)
- [Dimensional Modeling Guide](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/)

## 🤝 Contribuciones

¡Mejoras y sugerencias son bienvenidas! Abre un Issue o Pull Request.

## 📄 Licencia

Ver archivo `LICENSE` en el repositorio.

---

**Hecho con ❤️ para estudiantes de Big Data**
