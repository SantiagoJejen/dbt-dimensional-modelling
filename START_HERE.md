# 🚀 Empieza Aquí - Guía Rápida + Checklist

**Todo lo que necesitas para comenzar en 10 minutos**

> ⚠️ **IMPORTANTE**: Este proyecto usa un parche para dbt-athena 1.4.2. Ver `ATHENA_ADAPTER_PATCH.md` para detalles.

> 🔄 **¿Quieres empezar desde cero?** Lee: [RESET_AND_START.md](RESET_AND_START.md)

---

## 📋 Pre-requisitos (2 minutos)

Verifica que tengas esto antes de empezar:

- [ ] Cuenta de AWS activa (AWS Academy o IAM User)
- [ ] AWS CLI instalado: `aws --version`
- [ ] Python 3.8+: `python3 --version`
- [ ] Git instalado: `git --version`

---

## 📥 Paso 0: Clonar el Repositorio

```bash
# Clonar el repositorio
git clone https://github.com/SantiagoJejen/dbt-dimensional-modelling.git

# Entrar al directorio del proyecto
cd dbt-dimensional-modelling
```

---

## ⚡ Setup Rápido (Paso a Paso)

---

## ⚡ Setup Rápido (Paso a Paso)

### 1️⃣ Configurar AWS CLI
```bash
make configure-aws
```
✅ Ingresa tus credenciales (Access Key, Secret Key, Session Token si aplica)

### 2️⃣ Crear Bucket S3 para Resultados de Athena

⚠️ **IMPORTANTE**: Athena necesita un bucket S3 para guardar los resultados de las queries.

```bash
# Crea el bucket (reemplaza ACCOUNT_ID con tu Account ID de AWS)
# O usa este comando para obtener tu Account ID automáticamente:
aws s3 mb s3://aws-athena-query-results-$(aws sts get-caller-identity --query Account --output text)-us-east-1
```

📌 **Configurar Athena Console**:
1. Ve a: https://console.aws.amazon.com/athena/
2. Click en "Settings" (Configuración)
3. En "Query result location" ingresa: `s3://aws-athena-query-results-ACCOUNT_ID-us-east-1/`
4. Click "Save"

### 3️⃣ Instalar Dependencias con UV

⚠️ **NOTA IMPORTANTE**: El primer `make install` NO activa el ambiente automáticamente.

```bash
# Primer comando: Instala UV y crea el ambiente
make install

# Activar el ambiente virtual manualmente
source .venv/bin/activate

# Segundo comando: Reinstala en el ambiente activado + aplica parche
make install
```

✅ Esto instala UV + crea `.venv/` + instala deps + **aplica parche a dbt-athena**

### 4️⃣ Exportar Account ID (IMPORTANTE)

Antes de ejecutar dbt, necesitas exportar tu Account ID como variable de entorno:

```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Verificar que se exportó correctamente:
echo $AWS_ACCOUNT_ID
```

### 5️⃣ Crear Infraestructura AWS
```bash
make setup-aws
```
✅ Crea buckets S3 + sube seeds + crea database + tablas en Athena

---

## 🎯 Ejecutar Modelos (Con Account ID Configurado)

⚠️ **Asegúrate de haber exportado AWS_ACCOUNT_ID antes de continuar**

```bash
# Verificar que la variable esté configurada
echo $AWS_ACCOUNT_ID

# Si no muestra nada, ejecuta:
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Ahora sí, ejecutar transformaciones dbt
make dbt-run

# Ver documentación interactiva
make dbt-docs-serve
# Abre: http://localhost:8080
```

---

## 📊 Generar Reporte de Entrega

Cuando termines el proyecto, genera tu reporte:

```bash
make student-report
```

✅ Esto te mostrará tu puntuación y resultados de tests  
✅ **Copia TODO el texto** y pégalo en la plataforma de entrega  
✅ Tarda ~60 segundos (ejecuta los 42 tests de dbt)

---

## ✅ Checklist Completo

Marca cada paso mientras avanzas:

### � Preparación
- [ ] **0.** Cloné el repositorio: `git clone https://github.com/SantiagoJejen/dbt-dimensional-modelling.git`
- [ ] **0.1** Entré al directorio: `cd dbt-dimensional-modelling`

### �🔧 Setup (Primera Vez)
- [ ] **1.** Ejecuté `make configure-aws` ✓
- [ ] **2.** Creé bucket S3 para Athena: `aws s3 mb s3://aws-athena-query-results-ACCOUNT_ID-us-east-1`
- [ ] **3.** Configuré Athena Console con el bucket de resultados
- [ ] **4.** Ejecuté `make install` (primera vez)
- [ ] **5.** Activé el ambiente: `source .venv/bin/activate`
- [ ] **6.** Ejecuté `make install` (segunda vez - aplica parche)
- [ ] **7.** Exporté Account ID: `export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)`
- [ ] **8.** Ejecuté `make setup-aws` ✓
- [ ] **9.** Ejecuté `make dbt-debug` (debe decir "OK connection ok")

### 🎨 Transformaciones
- [ ] **10.** Ejecuté `make dbt-run` (crea dimensiones y hechos) - Esperar 8 modelos OK
- [ ] **11.** Ejecuté `make dbt-test` (valida datos) - 41/42 tests OK
- [ ] **12.** Ejecuté `make dbt-docs-serve` (explora documentación)

### 📊 Consultar Datos
- [ ] **13.** Abrí [AWS Athena Console](https://console.aws.amazon.com/athena/)
- [ ] **14.** Vi la database `adventureworks` y schema `marts`
- [ ] **15.** Ejecuté queries de ejemplo (ver abajo)

### � Entrega
- [ ] **16.** Ejecuté `make student-report` y copié la salida completa
- [ ] **17.** Pegué el reporte en la plataforma de entrega
- [ ] **18.** Incluí mi nombre completo al enviarlo

---

## 🐛 Problemas Conocidos y Soluciones

### ❌ Error: "DataCatalog adventureworks was not found"
✅ **Solución**: El proyecto incluye un parche automático en `make install`. Si persiste, ver `ATHENA_ADAPTER_PATCH.md`.

### ❌ Error: "Cannot cast '' to BIGINT"
✅ **Solución**: Los modelos `dim_customer.sql` y `dim_product.sql` ya incluyen `TRY_CAST()` para manejar valores vacíos.

### ❌ Error: mmh3 compilation failed en ARM
✅ **Solución**: Usa dbt-athena 1.4.2 (ya configurado en requirements.txt)

### ❌ Error: "AWS_ACCOUNT_ID no encontrado" en dbt run
✅ **Solución**: 
```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo $AWS_ACCOUNT_ID  # Verificar que se exportó
```

### ❌ Error: "No query results location" en Athena
✅ **Solución**: Configura el bucket de resultados en Athena Console:
1. Ve a Athena Console → Settings
2. Query result location: `s3://aws-athena-query-results-ACCOUNT_ID-us-east-1/`

### ❌ El ambiente virtual no se activa automáticamente
✅ **Solución**: Después del primer `make install`, ejecuta manualmente:
```bash
source .venv/bin/activate
make install  # Segunda vez para aplicar el parche
```

---

## 📊 Queries de Ejemplo en Athena

```sql
-- 1. Ver productos
SELECT * FROM adventureworks.marts.dim_product LIMIT 10;

-- 2. Ver clientes
SELECT * FROM adventureworks.marts.dim_customer LIMIT 10;

-- 3. Análisis de ventas por categoría
SELECT 
    product_category_name,
    COUNT(*) as total_orders,
    SUM(revenue) as total_revenue
FROM adventureworks.marts.obt_sales
GROUP BY product_category_name
ORDER BY total_revenue DESC;

-- 4. Ventas por país
SELECT 
    ship_to_country,
    COUNT(DISTINCT sales_order_id) as orders,
    SUM(revenue) as revenue
FROM adventureworks.marts.obt_sales
GROUP BY ship_to_country
ORDER BY revenue DESC
LIMIT 10;
```

---

## 🛠️ Comandos Make Esenciales

| Comando | Qué hace | Cuándo usarlo |
|---------|----------|---------------|
| `make help` | Muestra todos los comandos | Cuando no recuerdes algo |
| `make configure-aws` | Configura credenciales | Primera vez o si expiran |
| `make install` | Instala deps con UV | Primera vez (ejecutar 2 veces) |
| `make setup-aws` | Crea infraestructura | Primera vez en AWS |
| `make dbt-run` | Ejecuta modelos | Después de exportar AWS_ACCOUNT_ID |
| `make dbt-test` | Ejecuta tests | Después de dbt-run |
| `make student-report` | Genera reporte de entrega | Al finalizar el proyecto |
| `make dbt-docs-serve` | Docs interactivas | Para explorar |
| `make show-config` | Ver configuración | Para debug |
| `make list-s3` | Ver buckets | Para debug |
| `make clean-all` | Limpia todo (local+AWS) | Al terminar proyecto |

---

## 🐛 Problemas Comunes

### ❌ Error: "AWS no configurado"
```bash
make configure-aws
# Ingresa tus credenciales correctamente
```

### ❌ Error: "dbt: not found" o "command not found"
```bash
make install
# Esto recrea el entorno virtual y reinstala todo
```

### ❌ Error: "InvalidClientTokenId" (credenciales expiradas)
```bash
make configure-aws
# Vuelve a ingresar tus credenciales (AWS Academy expira cada 3-4 horas)
```

### ❌ Error: "Bucket already exists"
```bash
# Es normal si ya ejecutaste setup-aws antes. Ignóralo.
```

### ❌ Query lenta en Athena
```sql
-- Siempre usa LIMIT en queries de exploración:
SELECT * FROM tabla LIMIT 10;
```

---

## 📚 Documentación Adicional

**Lee estos si necesitas más detalles:**

- 📖 **README_AWS.md** - Tutorial completo paso a paso
- ⚡ **UV_GUIDE.md** - Todo sobre UV (10-100x más rápido que pip)
- 🔧 **MAKEFILE_FIX.md** - Cómo funciona el Makefile
- 🏗️ **ARCHITECTURE.md** - Arquitectura del proyecto
- 🔐 **AWS_CREDENTIALS_GUIDE.md** - Guía de credenciales AWS

---

## 🎓 Flujo de Trabajo Completo (Resumen)

```bash
# === SETUP INICIAL (Solo primera vez) ===
git clone https://github.com/SantiagoJejen/dbt-dimensional-modelling.git
cd dbt-dimensional-modelling

make configure-aws
aws s3 mb s3://aws-athena-query-results-$(aws sts get-caller-identity --query Account --output text)-us-east-1

make install
source .venv/bin/activate
make install

export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
make setup-aws

# === EJECUTAR MODELOS ===
make dbt-run
make dbt-test

# === GENERAR ENTREGA ===
make student-report
# Copiar y pegar la salida completa en la plataforma

# === VER RESULTADOS ===
make dbt-docs-serve  # http://localhost:8080
# O ir a AWS Athena Console y ejecutar queries
```

---

## 🎓 Flujo de Trabajo Diario

Si ya hiciste el setup inicial y solo quieres trabajar en el proyecto:

```bash
# 1. Abrir terminal en el proyecto
cd dbt-dimensional-modelling

# 2. Activar ambiente (si no está activado)
source .venv/bin/activate

# 3. Exportar Account ID (si cambió la sesión)
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# 4. Si cambian credenciales AWS (AWS Academy expira cada 3-4 horas)
make configure-aws

# 5. Ejecutar modelos (si cambiaste SQL)
make dbt-run

# 6. Ver resultados
make dbt-docs-serve
# o consultar en Athena Console
```

---

## 💡 Tips 

### ⚡ UV es 10-100x más rápido que pip
- Instalación: `make install` tarda segundos en vez de minutos
- UV se instala automáticamente, no necesitas hacer nada

### 🎯 El Makefile hace todo por ti
- No necesitas activar entornos virtuales manualmente
- No necesitas recordar comandos largos
- Todo está automatizado

### 💰 Costos AWS
- Este proyecto cuesta **menos de $1/mes**
- Athena cobra por GB escaneados
- Usa `LIMIT` en queries de exploración
- Ejecuta `make clean-buckets` al terminar

### 🔄 Credenciales AWS Academy
- Expiran cada 3-4 horas
- Necesitarás ejecutar `make configure-aws` en cada sesión de lab
- Copia las **3 líneas** (incluye `aws_session_token`)

---

## 🎯 Objetivos de Aprendizaje

Al completar este proyecto, sabrás:

- ✅ Qué es un modelo dimensional (Kimball)
- ✅ Diferencia entre dimensiones y hechos
- ✅ Usar dbt para transformar datos
- ✅ Trabajar con AWS S3, Athena y Glue
- ✅ Escribir queries SQL en Athena
- ✅ Arquitectura de capas (raw → silver)
- ✅ Automatizar con Makefile
- ✅ Usar UV para gestión de paquetes Python

---

## 🎉 ¡Listo!

Si completaste todos los items del checklist:

- [ ] **Puedo ejecutar `make dbt-run` sin errores**
- [ ] **Puedo consultar datos en Athena Console**
- [ ] **Entiendo el flujo completo del proyecto**
- [ ] **Sé usar todos los comandos make principales**

**¡Felicitaciones!** 🚀 Ahora puedes:
1. Experimentar con tus propios datasets
2. Modificar los modelos SQL
3. Agregar nuevas dimensiones
4. Crear análisis personalizados
5. Integrar con herramientas de BI

---

## 🆘 Ayuda

```bash
# Ver todos los comandos:
make help

# Diagnosticar problemas:
make verify

# Ver configuración:
make show-config

# Si todo falla, reinstalar:
make install
```

**¿Más dudas?** Revisa README_AWS.md (tutorial completo) o pregunta al instructor.

---

**Hecho con ❤️ para estudiantes de Big Data**
