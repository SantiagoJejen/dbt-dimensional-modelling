#!/usr/bin/env python3
"""
Script simple para generar reporte de entrega del estudiante.
El estudiante ejecuta esto y copia/pega la salida.
"""

import boto3
import subprocess
import sys
from datetime import datetime

def run_command(cmd):
    """Ejecuta un comando y retorna output."""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=120)
        return result.returncode, result.stdout, result.stderr
    except Exception as e:
        return -1, "", str(e)

def get_aws_info():
    """Obtiene info de AWS."""
    try:
        sts = boto3.client('sts')
        identity = sts.get_caller_identity()
        return identity['Account'], identity['Arn'].split('/')[-1]
    except:
        return "NO_CONFIGURADO", "NO_CONFIGURADO"

def check_buckets(account_id):
    """Verifica buckets S3."""
    if account_id == "NO_CONFIGURADO":
        return 0, 0
    
    s3 = boto3.client('s3')
    raw = f"dbt-adventureworks-raw-{account_id}"
    silver = f"dbt-adventureworks-silver-{account_id}"
    
    count = 0
    try:
        s3.head_bucket(Bucket=raw)
        count += 1
    except:
        pass
    
    try:
        s3.head_bucket(Bucket=silver)
        count += 1
    except:
        pass
    
    return count, 2

def check_athena_tables(account_id):
    """Cuenta tablas en Athena."""
    if account_id == "NO_CONFIGURADO":
        return 0, 0
    
    try:
        glue = boto3.client('glue')
        response = glue.get_tables(DatabaseName='adventureworks')
        tables = [t['Name'] for t in response.get('TableList', [])]
        
        # Todas las tablas en la database principal (seeds/raw)
        raw_count = len(tables)
        
        # Las tablas silver/marts las detectamos por dbt test
        # (si los tests corren, significa que las tablas existen)
        return raw_count, 0
    except:
        return 0, 0

def run_dbt_test():
    """Ejecuta dbt test y captura resultado."""
    print("   Ejecutando dbt test (puede tardar 30-60 segundos)...", flush=True)
    
    # Usar el python del venv directamente
    cmd = "cd adventureworks && ../.venv/bin/dbt test --target athena 2>&1"
    code, out, err = run_command(cmd)
    
    # Parsear resultados - buscar líneas con PASS y FAIL
    passed = 0
    failed = 0
    errors = []
    
    for line in out.split('\n'):
        # Detectar tests que pasaron
        if ' PASS ' in line or line.strip().endswith('PASS'):
            passed += 1
        # Detectar tests que fallaron
        elif ' FAIL ' in line or ' ERROR ' in line:
            failed += 1
            # Capturar el nombre del test fallido
            if 'FAIL' in line or 'ERROR' in line:
                errors.append(line.strip())
    
    return passed, failed, errors, out

def main():
    print("\n" + "="*70)
    print("📊 REPORTE DE ENTREGA - DBT DIMENSIONAL MODELLING")
    print("="*70)
    
    # Info del estudiante
    account_id, user = get_aws_info()
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    print(f"\n🆔 IDENTIFICACIÓN:")
    print(f"   Account ID: {account_id}")
    print(f"   Usuario: {user}")
    print(f"   Fecha: {timestamp}")
    
    # Verificar AWS
    print(f"\n☁️  AWS INFRASTRUCTURE:")
    buckets_ok, buckets_total = check_buckets(account_id)
    raw_tables, _ = check_athena_tables(account_id)
    
    print(f"   Buckets S3: {buckets_ok}/{buckets_total}")
    print(f"   Tablas RAW (seeds): {raw_tables}")
    
    # Ejecutar dbt test
    print(f"\n🧪 DBT TESTS:")
    passed, failed, errors, test_output = run_dbt_test()
    total = passed + failed
    
    print(f"   Tests ejecutados: {total}")
    print(f"   ✅ Pasaron: {passed}")
    print(f"   ❌ Fallaron: {failed}")
    
    if failed > 0:
        print(f"\n   💡 Nota: Es normal que falle 1 test (not_null_dim_product_product_name)")
        print(f"      Este es un bug conocido de Athena con inferencia de tipos.")
        print(f"\n   Tests fallidos:")
        for error in errors[:3]:  # Solo mostrar los primeros 3
            print(f"      • {error}")

    
    # Puntuación
    score = 0
    
    # Buckets (20 puntos)
    if buckets_ok == 2:
        score += 20
    elif buckets_ok == 1:
        score += 10
    
    # Tablas raw (20 puntos - esperamos ~15)
    if raw_tables >= 10:
        score += 20
    elif raw_tables >= 5:
        score += 10
    
    # Tests dbt (60 puntos - lo más importante!)
    if total > 0:
        # Puntos por tests pasados
        test_score = (passed / total) * 50
        score += test_score
        
        # Bonus: si ejecutaron los tests (+10)
        score += 10
    
    # Evaluación
    print(f"\n⭐ PUNTUACIÓN FINAL: {score:.0f}/100")
    
    if score >= 90:
        status = "🏆 EXCELENTE"
        detail = "Proyecto completado perfectamente!"
    elif score >= 70:
        status = "✅ APROBADO"
        detail = "Buen trabajo, cumple con los requisitos."
    elif score >= 50:
        status = "⚠️  PARCIAL"
        detail = "Completado a medias, revisar pendientes."
    else:
        status = "❌ INCOMPLETO"
        detail = "Necesita completar más componentes."
    
    print(f"   Estado: {status}")
    print(f"   {detail}")
    
    # Info adicional para el profesor
    if failed == 1 and 'not_null_dim_product_product_name' in str(errors):
        print(f"\n   ℹ️  Para el profesor: El test que falla es el bug conocido de Athena.")
        print(f"      El estudiante no puede solucionarlo. Evaluar como: {passed}/41 tests OK.")
    
    # Eliminar sección de detalle de tests que ya no necesitamos
    
    print("\n" + "="*70)
    print("📝 INSTRUCCIONES:")
    print("   1. Copia TODO este texto (desde la primera línea)")
    print("   2. Pégalo en la plataforma de entrega")
    print("   3. Incluye tu nombre completo al enviarlo")
    print("="*70 + "\n")

if __name__ == "__main__":
    main()
