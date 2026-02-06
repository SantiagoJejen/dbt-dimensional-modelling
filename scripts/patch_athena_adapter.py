#!/usr/bin/env python3
"""
Script para aplicar parche a dbt-athena adapter 1.4.2
Resuelve el bug: DataCatalog {schema_name} was not found
"""
import os
import sys
from pathlib import Path

def find_impl_file():
    """Encuentra el archivo impl.py del adapter de athena"""
    # Buscar desde el directorio del proyecto (parent del script)
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    venv_path = project_root / '.venv'
    
    if not venv_path.exists():
        print(f"❌ No se encontró .venv/ en {project_root}. Ejecuta 'make install' primero.")
        return None
    
    # Buscar impl.py en site-packages
    site_packages = list(venv_path.glob('**/site-packages/dbt/adapters/athena/impl.py'))
    
    if not site_packages:
        print("❌ No se encontró dbt/adapters/athena/impl.py")
        return None
    
    return site_packages[0]

def check_if_patched(impl_file):
    """Verifica si el archivo ya está parcheado"""
    content = impl_file.read_text()
    return "Skip data catalog check" in content or "# This is a workaround for dbt-athena" in content

def apply_patch(impl_file):
    """Aplica el parche al archivo impl.py"""
    content = impl_file.read_text()
    
    # Buscar la sección a parchear
    original_code = """    def list_relations_without_caching(
        self,
        schema_relation: AthenaRelation,
    ) -> List[BaseRelation]:
        catalog_id = None
        if schema_relation.database is not None and schema_relation.database.lower() != "awsdatacatalog":
            data_catalog = self._get_data_catalog(schema_relation.database.lower())
            # For non-Glue Data Catalogs, use the original Athena query against INFORMATION_SCHEMA approach
            if data_catalog["Type"] != "GLUE":
                return super().list_relations_without_caching(schema_relation)
            else:
                catalog_id = data_catalog["Parameters"]["catalog-id"]"""
    
    patched_code = """    def list_relations_without_caching(
        self,
        schema_relation: AthenaRelation,
    ) -> List[BaseRelation]:
        catalog_id = None
        # Skip data catalog check - just use default AwsDataCatalog
        # This is a workaround for dbt-athena 1.4.2 bug where schema_relation.database
        # is set to the schema name instead of the actual database/catalog name
        # if schema_relation.database is not None and schema_relation.database.lower() != "awsdatacatalog":
        #     data_catalog = self._get_data_catalog(schema_relation.database.lower())
        #     # For non-Glue Data Catalogs, use the original Athena query against INFORMATION_SCHEMA approach
        #     if data_catalog["Type"] != "GLUE":
        #         return super().list_relations_without_caching(schema_relation)
        #     else:
        #         catalog_id = data_catalog["Parameters"]["catalog-id"]"""
    
    if original_code in content:
        # Aplicar parche
        new_content = content.replace(original_code, patched_code)
        impl_file.write_text(new_content)
        return True
    
    return False

def main():
    """Función principal"""
    print("🔧 Parcheando dbt-athena adapter...")
    
    # Encontrar archivo
    impl_file = find_impl_file()
    if not impl_file:
        sys.exit(1)
    
    print(f"📁 Encontrado: {impl_file}")
    
    # Verificar si ya está parcheado
    if check_if_patched(impl_file):
        print("✅ El parche ya está aplicado")
        return 0
    
    # Aplicar parche
    if apply_patch(impl_file):
        print("✅ Parche aplicado exitosamente")
        print("📝 Ver ATHENA_ADAPTER_PATCH.md para más detalles")
        return 0
    else:
        print("⚠️  No se pudo aplicar el parche (estructura del código diferente)")
        print("   El archivo puede ya estar modificado o tener una versión diferente")
        return 1

if __name__ == "__main__":
    sys.exit(main())
