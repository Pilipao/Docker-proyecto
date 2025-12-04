#!/bin/bash
set -e

# =========================================================
# SCRIPT DE CONFIGURACIÓN DE REPLICACIÓN - REPLICA
# Este script configura PostgreSQL como servidor REPLICA
# =========================================================

echo "Configurando PostgreSQL como servidor REPLICA..."

# Esperar a que el servidor PRIMARY esté listo
until pg_isready -h "$POSTGRES_MASTER_HOST" -p "$POSTGRES_MASTER_PORT" -U "$POSTGRES_REPLICATION_USER"; do
  echo "Esperando a que el servidor PRIMARY esté listo..."
  sleep 2
done

# Detener PostgreSQL si está corriendo
pg_ctl -D "$PGDATA" -m fast -w stop || true

# Limpiar directorio de datos si existe
if [ -d "$PGDATA" ]; then
    rm -rf "$PGDATA"/*
fi

# Realizar backup base desde PRIMARY
echo "Realizando backup base desde PRIMARY..."
PGPASSWORD="$POSTGRES_REPLICATION_PASSWORD" pg_basebackup \
    -h "$POSTGRES_MASTER_HOST" \
    -p "$POSTGRES_MASTER_PORT" \
    -U "$POSTGRES_REPLICATION_USER" \
    -D "$PGDATA" \
    -Fp \
    -Xs \
    -P \
    -R \
    -S "${POSTGRES_MASTER_REPLICATION_SLOT:-replica_slot}"

# Configurar postgresql.conf para modo replica
cat >> "$PGDATA/postgresql.conf" <<EOF

# Configuración de réplica
hot_standby = on
max_standby_streaming_delay = 30s
wal_receiver_status_interval = 10s
hot_standby_feedback = on
EOF

# Configurar pg_hba.conf para permitir conexiones de replicación
cat >> "$PGDATA/pg_hba.conf" <<EOF

# Replicación desde PRIMARY
host replication $POSTGRES_REPLICATION_USER $POSTGRES_MASTER_HOST/32 md5
EOF

# Crear archivo standby.signal para indicar que es una réplica
touch "$PGDATA/standby.signal"

echo "Configuración de REPLICA completada."
echo "Réplica conectada a: $POSTGRES_MASTER_HOST:$POSTGRES_MASTER_PORT"

