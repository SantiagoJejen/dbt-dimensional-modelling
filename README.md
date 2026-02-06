<img src="docs/img/logo.png" align="right" />

# dbt dimensional modelling tutorial

Welcome to the tutorial on building a Kimball dimensional model with dbt. 

This tutorial is also featured on the [dbt developer blog](https://docs.getdbt.com/blog/kimball-dimensional-model).

---

## 🚀 **NUEVO: Versión AWS Athena (Completa y Lista)**

**Para estudiantes:** Si quieres usar este proyecto con **AWS Athena** (serverless):

### 🎯 Inicio Rápido (5 minutos)
👉 **[START_HERE.md](START_HERE.md)** - Guía rápida + Checklist completo

### 🔄 ¿Empezar desde Cero?
👉 **[RESET_AND_START.md](RESET_AND_START.md)** - Guía completa para resetear todo

### 📚 Documentación Completa
👉 **[README_AWS.md](README_AWS.md)** - Tutorial detallado paso a paso

### ⚡ Scripts de Automatización
```bash
# Iniciar desde cero (interactivo)
./start_fresh.sh

# Limpiar AWS rápidamente
./clean_aws_quick.sh

# O usa comandos Make
make help                # Ver todos los comandos
make clean-all          # Limpiar todo (local + AWS)
make configure-aws      # Configurar credenciales
make install            # Instalar dependencias
make setup-aws          # Crear infraestructura
make dbt-run            # Ejecutar modelos
```

**Características:**
- ⚡ Setup automático con UV (10-100x más rápido que pip)
- 🛠️ 25+ comandos Make para todo el flujo
- ☁️ Integración completa con AWS S3 + Athena + Glue
- � Parche automático para dbt-athena adapter
- � 8 modelos dbt (5 dims + 1 fact + 1 obt)
- ✅ 41/42 tests de calidad pasando
- 📚 Perfecto para AWS Academy

---

## Table of Contents (Tutorial Original DuckDB/Postgres) 

- [Part 0: Understand dimensional modelling concepts](#dimensional-modelling)
- [Part 1: Set up a mock dbt project and database](docs/part01-setup-dbt-project.md)
- [Part 2: Identify the business process to model](docs/part02-identify-business-process.md)
- [Part 3: Identify the fact and dimension tables](docs/part03-identify-fact-dimension.md)
- [Part 4: Create the dimension tables](docs/part04-create-dimension.md)
- [Part 5: Create the fact table](docs/part05-create-fact.md)
- [Part 6: Document the dimensional model relationships](docs/part06-document-model.md)
- [Part 7: Consume the dimensional model](docs/part07-consume-model.md)

## Introduction

Dimensional modelling is one of many data modelling techniques that are used by data practitioners to organize and present data for analytics. Other data modelling techniques include Data Vault (DV), Third Normal Form (3NF), and One Big Table (OBT) to name a few.

![](docs/img/data-modelling.png)
*Data modelling techniques on a normalization vs denormalization scale*

While the relevancy of dimensional modelling [has been debated by data practitioners](https://discourse.getdbt.com/t/is-kimball-dimensional-modeling-still-relevant-in-a-modern-data-warehouse/225/6), it is still one of the most widely adopted data modelling technique for analytics. 

Despite its popularity, resources on how to create dimensional models using dbt remain scarce and lack detail. This tutorial aims to solve this by providing the definitive guide to dimensional modelling with dbt. 

## Dimensional modelling

Dimensional modelling is a technique introduced by Ralph Kimball in 1996 with his book, [The Data Warehouse Toolkit](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/books/data-warehouse-dw-toolkit/). 

The goal of dimensional modelling is to take raw data and transform it into Fact and Dimension tables that represent the business. 

![](docs/img/3nf-to-dimensional-model.png)

*Raw 3NF data to dimensional model*

The benefits of dimensional modelling are: 

- **Simpler data model for analytics**: Users of dimensional models do not need to perform complex joins when consuming a dimensional model for analytics. Performing joins between fact and dimension tables are made simple through the use of surrogate keys.
- [**Don’t repeat yourself**](https://docs.getdbt.com/terms/dry): Dimensions can be easily re-used with other fact tables to avoid duplication of effort and code logic. Reusable dimensions are referred to as conformed dimensions.
- **Faster data retrieval**: Analytical queries executed against a dimensional model are significantly faster than a 3NF model since data transformations like joins and aggregations have been already applied.
- **Close alignment with actual business processes**: Business processes and metrics are modelled and calculated as part of dimensional modelling. This helps ensure that the modelled data is easily usable.

Now that we understand the broad concepts and benefits of dimensional modelling, let’s get hands-on and create our first dimensional model using dbt. 

[Next &raquo;](docs/part01-setup-dbt-project.md)
