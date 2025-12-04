#!/bin/bash
set -e

# =========================================================
# CONFIGURAR pg_hba.conf PARA REPLICACIÓN
# Este script se ejecuta después de la inicialización
# =========================================================

echo "Configurando pg_hba.conf para replicación..."

# Esperar a que PostgreSQL esté listo
until pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"; do
  echo "Esperando a que PostgreSQL esté listo..."
  sleep 2
done

# Agregar configuración de replicación a pg_hba.conf si no existe
if ! grep -q "host replication $POSTGRES_REPLICATION_USER" "$PGDATA/pg_hba.conf"; then
    echo "" >> "$PGDATA/pg_hba.conf"
    echo "# Replicación desde réplicas en la red Docker" >> "$PGDATA/pg_hba.conf"
    echo "host replication $POSTGRES_REPLICATION_USER 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"
    
    # Recargar configuración
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        SELECT pg_reload_conf();
EOSQL
    
    echo "pg_hba.conf configurado para replicación"
else
    echo "pg_hba.conf ya está configurado para replicación"
fi

