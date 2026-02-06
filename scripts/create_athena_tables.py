#!/usr/bin/env python3
"""
Script para crear tablas externas en Athena desde los CSVs en S3.
Este script lee los CSVs de seeds y crea tablas en Athena.
"""

import boto3
import csv
import os
import time
from pathlib import Path

# Configuración
AWS_REGION = os.environ.get('AWS_REGION', 'us-east-1')
ATHENA_DATABASE = 'adventureworks'

# Obtener Account ID
sts = boto3.client('sts', region_name=AWS_REGION)
account_id = sts.get_caller_identity()['Account']

RAW_BUCKET = f"dbt-adventureworks-raw-{account_id}"
SILVER_BUCKET = f"dbt-adventureworks-silver-{account_id}"
ATHENA_OUTPUT = f"s3://{SILVER_BUCKET}/athena-results/"

athena = boto3.client('athena', region_name=AWS_REGION)

# Mapeo de tipos de datos básico
def infer_type_from_value(value):
    """Inferir tipo de dato SQL desde un valor de ejemplo"""
    if not value or value.strip() == '':
        return 'string'
    
    value = value.strip()
    
    # Intentar parsear como número
    try:
        if '.' in value:
            float(value)
            return 'double'
        else:
            int(value)
            return 'bigint'
    except ValueError:
        pass
    
    # Fechas comunes (simplificado)
    if len(value) == 10 and value.count('-') == 2:
        return 'date'
    
    if len(value) == 19 and 'T' in value or ' ' in value:
        return 'timestamp'
    
    # Default
    return 'string'


def get_csv_schema(csv_path):
    """Leer un CSV y obtener el esquema inferido"""
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        
        # Obtener headers
        headers = reader.fieldnames
        
        # Leer primera fila para inferir tipos
        first_row = next(reader, None)
        
        if not first_row:
            # CSV vacío, usar string para todo
            return [(h, 'string') for h in headers]
        
        schema = []
        for header in headers:
            value = first_row.get(header, '')
            col_type = infer_type_from_value(value)
            # Limpiar nombres de columnas
            clean_header = header.lower().replace(' ', '_').replace('-', '_')
            schema.append((clean_header, col_type))
        
        return schema


def execute_athena_query(query_string):
    """Ejecutar una query en Athena y esperar el resultado"""
    print(f"Ejecutando query: {query_string[:100]}...")
    
    response = athena.start_query_execution(
        QueryString=query_string,
        QueryExecutionContext={'Database': ATHENA_DATABASE},
        ResultConfiguration={'OutputLocation': ATHENA_OUTPUT}
    )
    
    query_execution_id = response['QueryExecutionId']
    
    # Esperar a que termine
    max_wait = 30
    waited = 0
    while waited < max_wait:
        response = athena.get_query_execution(QueryExecutionId=query_execution_id)
        status = response['QueryExecution']['Status']['State']
        
        if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
            break
        
        time.sleep(1)
        waited += 1
    
    if status == 'SUCCEEDED':
        print(f"  ✓ Query ejecutada exitosamente")
        return True
    else:
        reason = response['QueryExecution']['Status'].get('StateChangeReason', 'Unknown error')
        print(f"  ✗ Query falló: {reason}")
        return False


def create_table_from_csv(csv_path, folder_name, table_name):
    """Crear tabla externa en Athena desde un CSV"""
    print(f"\nCreando tabla: {table_name}")
    
    # Obtener esquema
    schema = get_csv_schema(csv_path)
    
    # Construir columnas para CREATE TABLE
    columns = ',\n    '.join([f"`{col}` {dtype}" for col, dtype in schema])
    
    # Location en S3 - cada tabla en su propia carpeta
    # Athena requiere que cada tabla apunte a una carpeta con archivos de la misma estructura
    s3_location = f"s3://{RAW_BUCKET}/seeds/{folder_name}/{table_name}/"
    
    # DROP TABLE IF EXISTS
    drop_query = f"DROP TABLE IF EXISTS {ATHENA_DATABASE}.{table_name}"
    execute_athena_query(drop_query)
    
    # CREATE EXTERNAL TABLE
    create_query = f"""
    CREATE EXTERNAL TABLE {ATHENA_DATABASE}.{table_name} (
        {columns}
    )
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    STORED AS TEXTFILE
    LOCATION '{s3_location}'
    TBLPROPERTIES (
        'skip.header.line.count'='1'
    )
    """
    
    success = execute_athena_query(create_query)
    
    if success:
        print(f"  ✓ Tabla {table_name} creada en {s3_location}")
    
    return success


def main():
    print("=" * 60)
    print("Creando tablas RAW en Athena desde seeds")
    print("=" * 60)
    print(f"Account ID: {account_id}")
    print(f"Region: {AWS_REGION}")
    print(f"Database: {ATHENA_DATABASE}")
    print(f"Raw Bucket: {RAW_BUCKET}")
    print("=" * 60)
    
    # Base path para seeds
    seeds_path = Path(__file__).parent.parent / 'adventureworks' / 'seeds'
    
    if not seeds_path.exists():
        print(f"ERROR: No se encuentra el directorio de seeds: {seeds_path}")
        return 1
    
    # Iterar sobre las carpetas de seeds
    folders = ['date', 'person', 'production', 'sales']
    
    created_tables = []
    failed_tables = []
    
    for folder in folders:
        folder_path = seeds_path / folder
        
        if not folder_path.exists():
            print(f"⚠️  Carpeta no encontrada: {folder}")
            continue
        
        # Buscar CSVs en la carpeta
        csv_files = list(folder_path.glob('*.csv'))
        
        for csv_file in csv_files:
            table_name = csv_file.stem  # nombre sin extensión
            
            try:
                success = create_table_from_csv(csv_file, folder, table_name)
                if success:
                    created_tables.append(table_name)
                else:
                    failed_tables.append(table_name)
            except Exception as e:
                print(f"  ✗ Error creando tabla {table_name}: {e}")
                failed_tables.append(table_name)
    
    # Resumen
    print("\n" + "=" * 60)
    print("RESUMEN")
    print("=" * 60)
    print(f"✓ Tablas creadas exitosamente: {len(created_tables)}")
    for table in created_tables:
        print(f"  - {table}")
    
    if failed_tables:
        print(f"\n✗ Tablas con errores: {len(failed_tables)}")
        for table in failed_tables:
            print(f"  - {table}")
    
    print("\n✓ Proceso completado")
    print(f"Puedes consultar las tablas en Athena usando: SELECT * FROM {ATHENA_DATABASE}.<tabla> LIMIT 10")
    
    return 0 if not failed_tables else 1


if __name__ == '__main__':
    exit(main())
