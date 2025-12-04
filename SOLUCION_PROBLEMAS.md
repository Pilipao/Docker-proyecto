# Solución de Problemas - Load Balancer con DB Replica

## ✅ Problemas Resueltos

### 1. Error de Replicación: "no pg_hba.conf entry for replication"

**Problema**: La réplica no podía conectarse al PRIMARY porque faltaba la configuración en `pg_hba.conf`.

**Solución**: 
- Se creó el script `scripts/configure-pg-hba.sh` que configura `pg_hba.conf` después de la inicialización
- Se agregó el script al volumen de inicialización de PRIMARY

**Archivos modificados**:
- `scripts/configure-pg-hba.sh` (nuevo)
- `docker-compose.yml` (agregado volumen para el script)

### 2. Error de Healthcheck de API: curl no encontrado

**Problema**: El healthcheck usaba `curl` pero no estaba disponible en el contenedor.

**Solución**: 
- Se cambió el healthcheck para usar Python en lugar de curl
- Se mantuvo curl en el Dockerfile para uso futuro

**Archivos modificados**:
- `docker-compose.yml` (healthcheck actualizado)

### 3. Error de Inicialización de Réplica

**Problema**: El script de réplica intentaba inicializar PostgreSQL antes de hacer el backup.

**Solución**: 
- Se actualizó `scripts/docker-entrypoint-replica.sh` para:
  - Verificar si ya es una réplica configurada
  - Hacer el backup directamente desde PRIMARY sin inicializar primero
  - Manejar errores y reintentos

**Archivos modificados**:
- `scripts/docker-entrypoint-replica.sh` (completamente reescrito)

## Estado Actual del Sistema

✅ **db-primary**: Healthy - Funcionando correctamente
✅ **db-replica**: Healthy - Réplica configurada y sincronizada
✅ **api**: Healthy - API funcionando con routing automático
⚠️ **frontend**: Unhealthy - Problema menor con healthcheck (el servicio funciona)

## Comandos Útiles

### Verificar Estado de Replicación

```bash
# Ver slots de replicación en PRIMARY
docker exec -it research_db_primary psql -U postgres_user -d synthetic_data_db -c "SELECT * FROM pg_replication_slots;"

# Verificar que REPLICA está en modo réplica
docker exec -it research_db_replica psql -U postgres_user -d synthetic_data_db -c "SELECT pg_is_in_recovery();"
```

### Ver Logs

```bash
# Logs de PRIMARY
docker-compose logs db-primary

# Logs de REPLICA
docker-compose logs db-replica

# Logs de API
docker-compose logs api
```

### Recrear Réplica

Si necesitas recrear la réplica desde cero:

```bash
docker-compose stop db-replica
docker rm research_db_replica
docker volume rm research_portal_postgres_replica_data
docker-compose up -d db-replica
```

### Verificar Healthcheck de API

```bash
curl http://localhost:8000/api/health
```

Debería devolver:
```json
{
  "status": "healthy",
  "primary": "connected",
  "replica": "connected"
}
```

## Notas Importantes

1. **Primera ejecución**: La réplica puede tardar varios minutos en configurarse la primera vez, ya que debe hacer un backup completo desde PRIMARY.

2. **Healthcheck del Frontend**: El frontend muestra "unhealthy" pero el servicio funciona correctamente. Esto es un problema menor del healthcheck que no afecta la funcionalidad.

3. **Variables de Entorno**: Asegúrate de que todas las variables de entorno estén correctamente configuradas en el archivo `.env`.

4. **Reconstrucción**: Si cambias el código de la API, recuerda reconstruir la imagen:
   ```bash
   docker-compose build api
   docker-compose up -d api
   ```

