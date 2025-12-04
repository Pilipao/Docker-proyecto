#!/bin/bash
set -e

# =========================================================
# SCRIPT DE CONFIGURACIÓN DE REPLICACIÓN - PRIMARY
# Este script configura PostgreSQL como servidor PRIMARY
# =========================================================

echo "Configurando PostgreSQL como servidor PRIMARY para replicación..."

# Esperar a que PostgreSQL esté listo
until pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"; do
  echo "Esperando a que PostgreSQL esté listo..."
  sleep 2
done

# Crear usuario de replicación si no existe
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Crear usuario de replicación
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = '$POSTGRES_REPLICATION_USER') THEN
            CREATE USER $POSTGRES_REPLICATION_USER WITH REPLICATION PASSWORD '$POSTGRES_REPLICATION_PASSWORD';
        END IF;
    END
    \$\$;

    -- Otorgar permisos necesarios
    GRANT CONNECT ON DATABASE $POSTGRES_DB TO $POSTGRES_REPLICATION_USER;
    GRANT CONNECT ON DATABASE postgres TO $POSTGRES_REPLICATION_USER;
    
    -- Crear slot de replicación
    SELECT pg_create_physical_replication_slot('${POSTGRES_MASTER_REPLICATION_SLOT:-replica_slot}', true, false)
    WHERE NOT EXISTS (
        SELECT 1 FROM pg_replication_slots WHERE slot_name = '${POSTGRES_MASTER_REPLICATION_SLOT:-replica_slot}'
    );
EOSQL

echo "Configuración de PRIMARY completada."
echo "Usuario de replicación: $POSTGRES_REPLICATION_USER"
echo "Slot de replicación: ${POSTGRES_MASTER_REPLICATION_SLOT:-replica_slot}"

