# Variable para activar entorno virtual si existe
VENV_ACTIVATE := $(shell if [ -f .venv/bin/activate ]; then echo ". .venv/bin/activate &&"; fi)

# Obtener el Account ID de AWS
AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "NO_AWS_CONFIGURED")
AWS_REGION := us-east-1

# Nombres de buckets usando Account ID para unicidad
RAW_BUCKET := dbt-adventureworks-raw-$(AWS_ACCOUNT_ID)
SILVER_BUCKET := dbt-adventureworks-silver-$(AWS_ACCOUNT_ID)

# Database y catalog de Athena
ATHENA_DATABASE := adventureworks
ATHENA_WORKGROUP := primary

help: ## Mostrar esta ayuda
	@echo "============================================================"
	@echo "dbt-dimensional-modelling en AWS Athena (con UV ⚡)"
	@echo "============================================================"
	@echo ""
	@echo "Comandos disponibles:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "AWS Account ID detectado: $(AWS_ACCOUNT_ID)"
	@echo "Raw Bucket: $(RAW_BUCKET)"
	@echo "Silver Bucket: $(SILVER_BUCKET)"
	@echo ""
	@echo "💡 Tip: Si Account ID es 'NO_AWS_CONFIGURED', ejecuta: make configure-aws"
	@echo "⚡ Tip: Este proyecto usa UV (10-100x más rápido que pip)"
	@echo "============================================================"

configure-aws: ## Configurar credenciales AWS (especialmente para AWS Academy)
	@bash scripts/configure_aws_credentials.sh

install: ## Instalar dependencias con UV (ultrarrápido)
	@echo "================================================"
	@echo "⚡ Instalación con UV"
	@echo "================================================"
	@# 1. Verificar/Instalar UV
	@if ! command -v uv &> /dev/null; then \
		echo "❌ UV no encontrado. Instalando..."; \
		curl -LsSf https://astral.sh/uv/install.sh | sh; \
		export PATH="$$HOME/.cargo/bin:$$PATH"; \
	else \
		echo "✅ UV encontrado: $$(uv --version)"; \
	fi
	@# 2. Crear entorno virtual con UV si no existe
	@if [ ! -d .venv ]; then \
		echo "📦 Creando entorno virtual con UV..."; \
		uv venv; \
	else \
		echo "✅ Entorno virtual ya existe (.venv/)"; \
	fi
	@# 3. Instalar dependencias con UV
	@echo "📥 Instalando dependencias Python con UV..."; \
	uv pip install -r requirements.txt
	@# 4. Aplicar parche a dbt-athena adapter
	@echo "🔧 Aplicando parche a dbt-athena adapter..."; \
	python3 scripts/patch_athena_adapter.py || echo "⚠️  Advertencia: No se pudo aplicar el parche (puede ya estar aplicado)"
	@# 5. Instalar paquetes dbt
	@echo "📥 Instalando paquetes dbt..."; \
	bash -c "$(VENV_ACTIVATE) cd adventureworks && dbt deps"
	@echo "================================================"
	@echo "✅ Instalación completada con UV ⚡"
	@echo "✅ Parche de dbt-athena aplicado"
	@echo "================================================"
	@echo ""
	@echo "💡 Para activar el entorno virtual:"
	@echo "   source .venv/bin/activate"
	@echo ""

check-aws: ## Verificar configuración de AWS
	@echo "Verificando credenciales de AWS..."
	@aws sts get-caller-identity || (echo "ERROR: AWS no está configurado. Ejecuta 'make configure-aws' o 'aws configure'" && exit 1)
	@echo "✓ AWS Account ID: $(AWS_ACCOUNT_ID)"
	@echo "✓ Región: $(AWS_REGION)"

create-buckets: check-aws ## Crear buckets S3 para raw y silver
	@echo "Creando bucket RAW: $(RAW_BUCKET)..."
	@aws s3 mb s3://$(RAW_BUCKET) --region $(AWS_REGION) 2>/dev/null || echo "Bucket $(RAW_BUCKET) ya existe"
	@echo "Creando bucket SILVER: $(SILVER_BUCKET)..."
	@aws s3 mb s3://$(SILVER_BUCKET) --region $(AWS_REGION) 2>/dev/null || echo "Bucket $(SILVER_BUCKET) ya existe"
	@echo "✓ Buckets creados/verificados"

upload-seeds: check-aws create-buckets ## Subir archivos CSV de seeds a S3 raw (cada CSV en su carpeta)
	@echo "Subiendo seeds a S3 capa RAW..."
	@echo "⚠️  Nota: Athena requiere que cada tabla esté en su propia carpeta"
	@echo ""
	@bash -c ' \
		for folder in date person production sales; do \
			echo "📂 Procesando carpeta: $$folder"; \
			if [ -d "adventureworks/seeds/$$folder" ]; then \
				for file in adventureworks/seeds/$$folder/*.csv; do \
					if [ -f "$$file" ]; then \
						filename=$$(basename "$$file" .csv); \
						echo "  📄 Subiendo $$filename → s3://$(RAW_BUCKET)/seeds/$$folder/$$filename/"; \
						aws s3 cp "$$file" "s3://$(RAW_BUCKET)/seeds/$$folder/$$filename/$$filename.csv"; \
					fi; \
				done; \
			else \
				echo "⚠️  Carpeta no encontrada: adventureworks/seeds/$$folder"; \
			fi; \
		done \
	'
	@echo ""
	@echo "✓ Seeds subidos exitosamente"
	@echo "  Estructura en S3:"
	@echo "    s3://$(RAW_BUCKET)/seeds/date/date/date.csv"
	@echo "    s3://$(RAW_BUCKET)/seeds/person/address/address.csv"
	@echo "    s3://$(RAW_BUCKET)/seeds/person/person/person.csv"
	@echo "    ..."

create-athena-database: check-aws ## Crear database en Athena
	@echo "Creando database $(ATHENA_DATABASE) en Athena..."
	@aws athena start-query-execution \
		--query-string "CREATE DATABASE IF NOT EXISTS $(ATHENA_DATABASE)" \
		--result-configuration "OutputLocation=s3://$(SILVER_BUCKET)/athena-results/" \
		--region $(AWS_REGION)
	@echo "✓ Database $(ATHENA_DATABASE) creado/verificado"

create-raw-tables: check-aws upload-seeds create-athena-database ## Crear tablas externas en Athena apuntando a los seeds
	@echo "Creando tablas raw en Athena desde seeds..."
	@bash -c "$(VENV_ACTIVATE) python scripts/create_athena_tables.py"
	@echo "✓ Tablas raw creadas en Athena"

setup-aws: create-buckets upload-seeds create-athena-database create-raw-tables ## Setup completo de AWS (buckets + seeds + database + tablas)
	@echo ""
	@echo "=========================================="
	@echo "✓ Setup de AWS completado exitosamente!"
	@echo "=========================================="
	@echo "Buckets S3:"
	@echo "  - Raw:    s3://$(RAW_BUCKET)"
	@echo "  - Silver: s3://$(SILVER_BUCKET)"
	@echo ""
	@echo "Athena Database: $(ATHENA_DATABASE)"
	@echo ""
	@echo "Próximo paso: Configurar dbt profile"
	@echo "  1. Edita adventureworks/profiles.yml"
	@echo "  2. Actualiza s3_staging_dir con tu bucket"
	@echo "  3. Ejecuta: make dbt-run"
	@echo ""

dbt-debug: ## Verificar conexión de dbt con Athena
	@bash -c "$(VENV_ACTIVATE) cd adventureworks && dbt debug --target athena"

dbt-run: ## Ejecutar modelos dbt (crear capa silver)
	@bash -c "$(VENV_ACTIVATE) cd adventureworks && dbt run --target athena"

dbt-test: ## Ejecutar tests de dbt
	@bash -c "$(VENV_ACTIVATE) cd adventureworks && dbt test --target athena"

dbt-docs-generate: ## Generar documentación de dbt
	@bash -c "$(VENV_ACTIVATE) cd adventureworks && dbt docs generate --target athena"

dbt-docs-serve: ## Servir documentación de dbt
	@bash -c "$(VENV_ACTIVATE) cd adventureworks && dbt docs serve --target athena"

verify: check-aws ## Verificar que todo está desplegado correctamente
	@echo "Verificando deployment..."
	@bash -c "$(VENV_ACTIVATE) python scripts/verify_deployment.py"

clean-buckets: check-aws ## Limpiar y eliminar buckets (¡CUIDADO!)
	@echo "⚠️  ADVERTENCIA: Esto eliminará todos los datos en los buckets"
	@read -p "¿Estás seguro? [y/N]: " confirm && [ "$$confirm" = "y" ]
	@echo "Vaciando buckets..."
	@aws s3 rm s3://$(RAW_BUCKET) --recursive || true
	@aws s3 rm s3://$(SILVER_BUCKET) --recursive || true
	@echo "Eliminando buckets..."
	@aws s3 rb s3://$(RAW_BUCKET) || true
	@aws s3 rb s3://$(SILVER_BUCKET) || true
	@echo "✓ Buckets eliminados"

list-s3: check-aws ## Listar contenido de los buckets
	@echo "Contenido de RAW bucket:"
	@aws s3 ls s3://$(RAW_BUCKET)/ --recursive --human-readable || echo "Bucket vacío o no existe"
	@echo ""
	@echo "Contenido de SILVER bucket:"
	@aws s3 ls s3://$(SILVER_BUCKET)/ --recursive --human-readable || echo "Bucket vacío o no existe"

show-config: ## Mostrar configuración actual
	@echo "Configuración actual:"
	@echo "  AWS Account ID: $(AWS_ACCOUNT_ID)"
	@echo "  AWS Region: $(AWS_REGION)"
	@echo "  Raw Bucket: $(RAW_BUCKET)"
	@echo "  Silver Bucket: $(SILVER_BUCKET)"
	@echo "  Athena Database: $(ATHENA_DATABASE)"
	@echo "  Athena Workgroup: $(ATHENA_WORKGROUP)"

clean-local: ## Limpiar archivos locales (venv, target, logs)
	@echo "Limpiando archivos locales..."
	@rm -rf .venv
	@rm -rf adventureworks/target
	@rm -rf adventureworks/dbt_packages
	@rm -rf adventureworks/logs
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "✓ Archivos locales limpiados"

clean-aws: check-aws ## Limpiar recursos AWS (buckets y database)
	@echo "⚠️  Esto eliminará TODOS los recursos AWS del proyecto"
	@echo "   - Buckets S3: $(RAW_BUCKET) y $(SILVER_BUCKET)"
	@echo "   - Database Athena: $(ATHENA_DATABASE)"
	@echo ""
	@read -p "¿Continuar? (escribe 'yes' para confirmar): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		echo "Eliminando contenido de buckets..."; \
		aws s3 rm s3://$(RAW_BUCKET)/ --recursive 2>/dev/null || true; \
		aws s3 rm s3://$(SILVER_BUCKET)/ --recursive 2>/dev/null || true; \
		echo "Eliminando buckets..."; \
		aws s3 rb s3://$(RAW_BUCKET) 2>/dev/null || true; \
		aws s3 rb s3://$(SILVER_BUCKET) 2>/dev/null || true; \
		echo "Eliminando database Athena..."; \
		aws athena start-query-execution \
			--region $(AWS_REGION) \
			--query-string "DROP DATABASE IF EXISTS $(ATHENA_DATABASE) CASCADE" \
			--result-configuration "OutputLocation=s3://aws-athena-query-results-$(AWS_ACCOUNT_ID)-$(AWS_REGION)/" \
			--work-group $(ATHENA_WORKGROUP) 2>/dev/null || true; \
		echo "✓ Recursos AWS eliminados"; \
	else \
		echo "Operación cancelada"; \
	fi

clean-all: clean-local clean-aws ## Limpiar TODO (local + AWS)
	@echo "✓ Limpieza completa realizada"

list-athena-tables: check-aws ## Listar tablas en Athena
	@echo "Tablas en database $(ATHENA_DATABASE):"
	@aws athena start-query-execution \
		--region $(AWS_REGION) \
		--query-string "SHOW TABLES IN $(ATHENA_DATABASE)" \
		--result-configuration "OutputLocation=s3://$(SILVER_BUCKET)/athena-temp/" \
		--work-group $(ATHENA_WORKGROUP) \
		--query 'QueryExecutionId' \
		--output text | xargs -I {} sh -c 'sleep 3 && aws athena get-query-results --region $(AWS_REGION) --query-execution-id {} --query "ResultSet.Rows[*].Data[0].VarCharValue" --output text'

student-report: ## Generar reporte de entrega (copia y pega la salida)
	@echo "Generando reporte de entrega..."
	@bash -c "$(VENV_ACTIVATE) python scripts/student_report.py"

.PHONY: help configure-aws install check-aws create-buckets upload-seeds create-athena-database create-athena-tables setup-aws dbt-debug dbt-run dbt-test dbt-docs-generate dbt-docs-serve verify list-s3 show-config clean-local clean-aws clean-all list-athena-tables student-report
