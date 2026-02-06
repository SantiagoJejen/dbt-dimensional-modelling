# 🚀 Empieza Aquí - Guía Rápida + Checklist

**Todo lo que necesitas para comenzar en 5 minutos**

> ⚠️ **IMPORTANTE**: Este proyecto usa un parche para dbt-athena 1.4.2. Ver `ATHENA_ADAPTER_PATCH.md` para detalles.

> 🔄 **¿Quieres empezar desde cero?** Lee: [RESET_AND_START.md](RESET_AND_START.md)

---

## 📋 Pre-requisitos (2 minutos)

Verifica que tengas esto antes de empezar:

- [ ] Cuenta de AWS activa (AWS Academy o IAM User)
- [ ] AWS CLI instalado: `aws --version`
- [ ] Python 3.8+: `python3 --version`
- [ ] Git para clonar el repo

---

## ⚡ Setup Rápido (3 comandos)

### 1️⃣ Configurar AWS
```bash
make configure-aws
```
✅ Ingresa tus credenciales (Access Key, Secret Key, Session Token si aplica)

### 2️⃣ Instalar Todo con UV ⚡
```bash
make install
```
✅ Instala UV automáticamente + crea `.venv/` + instala deps + configura dbt + **aplica parche a dbt-athena**

### 3️⃣ Crear Infraestructura AWS
```bash
make setup-aws
```
✅ Crea buckets S3 + sube seeds + crea database + tablas en Athena

---

## 🎯 Ejecutar Modelos (2 comandos)

```bash
# Ejecutar transformaciones dbt
make dbt-run

# Ver documentación interactiva
make dbt-docs-serve
# Abre: http://localhost:8080
```

---

## ✅ Checklist Completo

Marca cada paso mientras avanzas:

### 🔧 Setup (Primera Vez)
- [x] **1.** Ejecuté `make configure-aws` ✓
- [x] **2.** Ejecuté `make install` ✓  
- [x] **3.** Ejecuté `make setup-aws` ✓
- [x] **4.** Ejecuté `make dbt-debug` (debe decir "OK connection ok")

### 🎨 Transformaciones
- [x] **5.** Ejecuté `make dbt-run` (crea dimensiones y hechos) ✓ 8 modelos OK
- [ ] **6.** Ejecuté `make dbt-test` (valida datos)
- [ ] **7.** Ejecuté `make verify` (verifica deployment)
- [ ] **8.** Ejecuté `make dbt-docs-serve` (explora documentación)

### 📊 Consultar Datos
- [ ] **9.** Abrí [AWS Athena Console](https://console.aws.amazon.com/athena/)
- [ ] **10.** Vi la database `adventureworks` y schema `marts`
- [ ] **11.** Ejecuté queries de ejemplo (ver abajo)

### 🔍 Verificación
- [ ] **12.** Ejecuté `make list-s3` (ver buckets)
- [ ] **13.** Ejecuté `make show-config` (ver configuración)
- [ ] **14.** Todo funciona sin errores ✨

---

## 🐛 Problemas Conocidos y Soluciones

### ❌ Error: "DataCatalog adventureworks was not found"
✅ **Solución**: El proyecto incluye un parche automático en `make install`. Si persiste, ver `ATHENA_ADAPTER_PATCH.md`.

### ❌ Error: "Cannot cast '' to BIGINT"
✅ **Solución**: Los modelos `dim_customer.sql` y `dim_product.sql` ya incluyen `TRY_CAST()` para manejar valores vacíos.

### ❌ Error: mmh3 compilation failed en ARM
✅ **Solución**: Usa dbt-athena 1.4.2 (ya configurado en requirements.txt)

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
| `make install` | Instala deps con UV | Primera vez o actualización |
| `make setup-aws` | Crea infraestructura | Primera vez en AWS |
| `make dbt-run` | Ejecuta modelos | Cada cambio en SQL |
| `make dbt-test` | Ejecuta tests | Después de dbt-run |
| `make dbt-docs-serve` | Docs interactivas | Para explorar |
| `make verify` | Diagnóstico completo | Si algo falla |
| `make show-config` | Ver configuración | Para debug |
| `make list-s3` | Ver buckets | Para debug |
| `make clean-buckets` | Limpia todo | Al terminar |

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

## 🎓 Flujo de Trabajo Diario

Una vez que hiciste el setup inicial, este es tu flujo diario:

```bash
# 1. Abrir terminal en el proyecto
cd dbt-dimensional-modelling

# 2. Ejecutar modelos (si cambiaste SQL)
make dbt-run

# 3. Ver resultados
make dbt-docs-serve
# o consultar en Athena Console

# 4. Si cambian credenciales AWS (AWS Academy)
make configure-aws
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
