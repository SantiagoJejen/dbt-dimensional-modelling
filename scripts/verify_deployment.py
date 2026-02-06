#!/usr/bin/env python3
"""
Script de verificación post-deployment para estudiantes.
Verifica que todas las tablas se hayan creado correctamente en Athena.
"""

import boto3
import sys
import os
from datetime import datetime

# Configuración
AWS_REGION = os.environ.get('AWS_REGION', 'us-east-1')
ATHENA_DATABASE = 'adventureworks'

# Obtener Account ID
sts = boto3.client('sts', region_name=AWS_REGION)
account_id = sts.get_caller_identity()['Account']

SILVER_BUCKET = f"dbt-adventureworks-silver-{account_id}"
ATHENA_OUTPUT = f"s3://{SILVER_BUCKET}/athena-results/"

# Colores para terminal
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
RESET = '\033[0m'

def print_header(text):
    print("\n" + "=" * 60)
    print(f"{BLUE}{text}{RESET}")
    print("=" * 60)

def print_success(text):
    print(f"{GREEN}✓{RESET} {text}")

def print_error(text):
    print(f"{RED}✗{RESET} {text}")

def print_warning(text):
    print(f"{YELLOW}⚠{RESET} {text}")

def get_glue_client():
    return boto3.client('glue', region_name=AWS_REGION)

def get_tables_in_schema(glue_client, schema_name='marts'):
    """Obtener lista de tablas en un schema específico"""
    try:
        response = glue_client.get_tables(DatabaseName=ATHENA_DATABASE)
        tables = response.get('TableList', [])
        
        # Filtrar por schema si está especificado
        if schema_name:
            tables = [t for t in tables if t.get('StorageDescriptor', {}).get('Location', '').endswith(f'/{schema_name}/') or schema_name in t.get('Name', '')]
        
        return [t['Name'] for t in tables]
    except Exception as e:
        print_error(f"Error obteniendo tablas: {e}")
        return []

def count_records(athena_client, table_name):
    """Contar registros en una tabla"""
    try:
        query = f"SELECT COUNT(*) as count FROM {ATHENA_DATABASE}.marts.{table_name}"
        
        response = athena_client.start_query_execution(
            QueryString=query,
            QueryExecutionContext={'Database': ATHENA_DATABASE},
            ResultConfiguration={'OutputLocation': ATHENA_OUTPUT}
        )
        
        query_execution_id = response['QueryExecutionId']
        
        # Esperar resultado
        import time
        max_wait = 30
        waited = 0
        while waited < max_wait:
            status_response = athena_client.get_query_execution(QueryExecutionId=query_execution_id)
            status = status_response['QueryExecution']['Status']['State']
            
            if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
                break
            
            time.sleep(1)
            waited += 1
        
        if status == 'SUCCEEDED':
            results = athena_client.get_query_results(QueryExecutionId=query_execution_id)
            count = results['ResultSet']['Rows'][1]['Data'][0]['VarCharValue']
            return int(count)
        else:
            return -1
            
    except Exception as e:
        return -1

def main():
    print_header("🔍 Verificación de Deployment - dbt Dimensional Modelling")
    
    print(f"\n{BLUE}Configuración:{RESET}")
    print(f"  Account ID: {account_id}")
    print(f"  Región: {AWS_REGION}")
    print(f"  Database: {ATHENA_DATABASE}")
    print(f"  Silver Bucket: {SILVER_BUCKET}")
    
    # Clientes AWS
    glue = get_glue_client()
    athena = boto3.client('athena', region_name=AWS_REGION)
    s3 = boto3.client('s3', region_name=AWS_REGION)
    
    # 1. Verificar que exista la database
    print_header("1. Verificando Database")
    try:
        glue.get_database(Name=ATHENA_DATABASE)
        print_success(f"Database '{ATHENA_DATABASE}' existe")
    except glue.exceptions.EntityNotFoundException:
        print_error(f"Database '{ATHENA_DATABASE}' NO existe")
        print(f"   Ejecuta: make create-athena-database")
        return 1
    
    # 2. Verificar buckets S3
    print_header("2. Verificando Buckets S3")
    
    raw_bucket = f"dbt-adventureworks-raw-{account_id}"
    
    for bucket_name in [raw_bucket, SILVER_BUCKET]:
        try:
            s3.head_bucket(Bucket=bucket_name)
            print_success(f"Bucket '{bucket_name}' existe")
        except:
            print_error(f"Bucket '{bucket_name}' NO existe")
            print(f"   Ejecuta: make create-buckets")
    
    # 3. Verificar tablas RAW
    print_header("3. Verificando Tablas RAW (capa bronze)")
    
    expected_raw_tables = [
        'address', 'countryregion', 'person', 'stateprovince',  # person
        'product', 'productcategory', 'productsubcategory',  # production
        'creditcard', 'customer', 'salesorderdetail', 'salesorderheader',  # sales
        'salesorderheadersalesreason', 'salesreason', 'store',
        'date'  # date
    ]
    
    raw_tables = get_tables_in_schema(glue, schema_name=None)
    
    missing_raw = []
    for table in expected_raw_tables:
        if table in raw_tables:
            print_success(f"Tabla raw '{table}' existe")
        else:
            print_error(f"Tabla raw '{table}' NO existe")
            missing_raw.append(table)
    
    if missing_raw:
        print(f"\n{YELLOW}Faltan {len(missing_raw)} tablas raw{RESET}")
        print("   Ejecuta: make create-raw-tables")
    
    # 4. Verificar tablas del modelo dimensional (MARTS)
    print_header("4. Verificando Modelo Dimensional (capa silver)")
    
    expected_marts = {
        'dim_address': 'Dimensión de direcciones',
        'dim_credit_card': 'Dimensión de tarjetas de crédito',
        'dim_customer': 'Dimensión de clientes',
        'dim_date': 'Dimensión de fechas',
        'dim_order_status': 'Dimensión de estados de orden',
        'dim_product': 'Dimensión de productos',
        'fct_sales': 'Tabla de hechos de ventas',
        'obt_sales': 'One Big Table de ventas'
    }
    
    marts_tables = [t for t in raw_tables if any(t.startswith(prefix) for prefix in ['dim_', 'fct_', 'obt_'])]
    
    missing_marts = []
    results = []
    
    for table, description in expected_marts.items():
        if table in marts_tables or f"marts.{table}" in marts_tables:
            print_success(f"✓ {table}: {description}")
            
            # Contar registros
            count = count_records(athena, table)
            if count >= 0:
                results.append((table, count))
                print(f"    Registros: {count:,}")
            else:
                print_warning(f"    No se pudo contar registros")
        else:
            print_error(f"✗ {table}: NO existe")
            missing_marts.append(table)
    
    # Resumen
    print_header("📊 RESUMEN")
    
    if not missing_raw and not missing_marts:
        print_success("¡Todas las tablas están creadas correctamente!")
        
        if results:
            print(f"\n{BLUE}Conteo de registros:{RESET}")
            for table, count in sorted(results, key=lambda x: x[1], reverse=True):
                print(f"  {table:20} {count:>10,} registros")
        
        print(f"\n{GREEN}✅ Deployment exitoso!{RESET}")
        print(f"\n{BLUE}Próximos pasos:{RESET}")
        print("  1. Ver documentación: make dbt-docs-serve")
        print("  2. Consultar en Athena Console: https://console.aws.amazon.com/athena/")
        print("  3. Explorar los datos:")
        print(f"     SELECT * FROM {ATHENA_DATABASE}.marts.obt_sales LIMIT 10;")
        
        return 0
    else:
        print_error(f"Faltan {len(missing_marts)} tablas del modelo dimensional")
        print(f"\n{YELLOW}Acciones recomendadas:{RESET}")
        
        if missing_raw:
            print("  1. Crear tablas raw: make create-raw-tables")
        if missing_marts:
            print("  2. Ejecutar modelos dbt: make dbt-run")
        
        return 1

if __name__ == '__main__':
    try:
        exit_code = main()
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print(f"\n{YELLOW}Cancelado por usuario{RESET}")
        sys.exit(1)
    except Exception as e:
        print_error(f"Error inesperado: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
