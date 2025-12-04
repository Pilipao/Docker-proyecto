#!/bin/bash
set -e

# =========================================================
# ENTRYPOINT PERSONALIZADO PARA REPLICA
# Este script configura PostgreSQL como réplica al iniciar
# =========================================================

echo "=== Configurando PostgreSQL como REPLICA ==="

# Si el directorio de datos ya existe y tiene datos válidos, iniciar directamente
if [ -s "$PGDATA/PG_VERSION" ] && [ -f "$PGDATA/standby.signal" ]; then
    echo "Réplica ya configurada, iniciando PostgreSQL..."
    exec docker-entrypoint.sh postgres
fi

# Si el directorio tiene datos pero no es una réplica, limpiarlo
if [ -s "$PGDATA/PG_VERSION" ] && [ ! -f "$PGDATA/standby.signal" ]; then
    echo "Directorio de datos existe pero no es una réplica. Limpiando..."
    rm -rf "$PGDATA"/*
fi

# Esperar a que el PRIMARY esté listo y tenga el usuario de replicación configurado
echo "Esperando a que el servidor PRIMARY esté listo..."
MAX_RETRIES=30
RETRY_COUNT=0

until PGPASSWORD="$POSTGRES_REPLICATION_PASSWORD" psql -h "$POSTGRES_MASTER_HOST" -p "$POSTGRES_MASTER_PORT" -U "$POSTGRES_REPLICATION_USER" -d postgres -c '\q' 2>/dev/null; do
  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "ERROR: No se pudo conectar al PRIMARY después de $MAX_RETRIES intentos"
    exit 1
  fi
  echo "Esperando a PRIMARY... (intento $RETRY_COUNT/$MAX_RETRIES)"
  sleep 2
done

echo "PRIMARY está listo. Configurando réplica..."

# Asegurar que el directorio de datos esté vacío
if [ -d "$PGDATA" ] && [ "$(ls -A $PGDATA)" ]; then
    echo "Limpiando directorio de datos existente..."
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
    -S "${POSTGRES_MASTER_REPLICATION_SLOT:-replica_slot}" || {
    echo "ERROR: Falló pg_basebackup. Verificando slot de replicación..."
    
    # Intentar crear el slot si no existe
    PGPASSWORD="$POSTGRES_REPLICATION_PASSWORD" psql -h "$POSTGRES_MASTER_HOST" -p "$POSTGRES_MASTER_PORT" -U "$POSTGRES_REPLICATION_USER" -d postgres <<-EOSQL
        SELECT pg_create_physical_replication_slot('${POSTGRES_MASTER_REPLICATION_SLOT:-replica_slot}', true, false)
        WHERE NOT EXISTS (
            SELECT 1 FROM pg_replication_slots WHERE slot_name = '${POSTGRES_MASTER_REPLICATION_SLOT:-replica_slot}'
        );
EOSQL
    
    # Reintentar pg_basebackup
    echo "Reintentando pg_basebackup..."
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
}

# Verificar que el backup se completó correctamente
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "ERROR: pg_basebackup no completó correctamente"
    exit 1
fi

# Configurar postgresql.conf para modo replica
if [ -f "$PGDATA/postgresql.conf" ]; then
    cat >> "$PGDATA/postgresql.conf" <<EOF

# Configuración de réplica
hot_standby = on
max_standby_streaming_delay = 30s
wal_receiver_status_interval = 10s
hot_standby_feedback = on
EOF
fi

# Crear archivo standby.signal para indicar que es una réplica
touch "$PGDATA/standby.signal"

echo "=== Configuración de REPLICA completada ==="
echo "Réplica conectada a: $POSTGRES_MASTER_HOST:$POSTGRES_MASTER_PORT"

# Iniciar PostgreSQL en modo réplica
exec docker-entrypoint.sh postgres
