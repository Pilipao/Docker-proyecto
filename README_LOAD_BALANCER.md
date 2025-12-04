# Research Portal - Load Balancer con DB Replica

Este documento describe la implementación del sistema de load balancer con réplica de base de datos para el Research Portal.

## Arquitectura

El sistema está compuesto por los siguientes servicios:

1. **db-primary**: Base de datos PostgreSQL PRIMARY (escritura)
2. **db-replica**: Base de datos PostgreSQL REPLICA (lectura)
3. **api**: Servicio FastAPI con lógica de routing automático
4. **frontend**: Servicio Nginx para servir el frontend

## Funcionamiento del Load Balancer

### Routing Automático

El sistema implementa un `DatabaseRouter` que enruta automáticamente las consultas:

- **Lecturas (SELECT)**: Se dirigen a la base de datos REPLICA
- **Escrituras (INSERT/UPDATE/DELETE)**: Se dirigen a la base de datos PRIMARY
- **Fallback**: Si la REPLICA no está disponible, automáticamente usa PRIMARY

### Detección de Tipo de Query

El sistema detecta automáticamente el tipo de operación analizando la query SQL:

```python
# Lectura -> REPLICA
SELECT * FROM contenidos

# Escritura -> PRIMARY
INSERT INTO contenidos VALUES (...)
UPDATE contenidos SET ...
DELETE FROM contenidos WHERE ...
```

## Configuración

### 1. Variables de Entorno

Crea un archivo `.env` basado en `.env.example`:

```bash
cp .env.example .env
```

Edita el archivo `.env` con tus valores personalizados.

### 2. Iniciar los Servicios

```bash
docker-compose up -d
```

### 3. Verificar el Estado

```bash
# Ver logs de todos los servicios
docker-compose logs -f

# Verificar health de la API
curl http://localhost:8000/api/health

# Verificar estado de los servicios
docker-compose ps
```

## Replicación PostgreSQL

### Configuración PRIMARY

El servidor PRIMARY está configurado con:
- `wal_level=replica`: Habilita WAL para replicación
- `max_wal_senders=3`: Permite hasta 3 conexiones de replicación
- `max_replication_slots=3`: Permite hasta 3 slots de replicación
- Usuario de replicación: `replicator`

### Configuración REPLICA

El servidor REPLICA:
- Se configura automáticamente al iniciar
- Realiza un `pg_basebackup` desde PRIMARY
- Se mantiene sincronizado mediante streaming replication
- Solo permite operaciones de lectura

## Estructura de Archivos

```
research_portal/
├── docker-compose.yml          # Orquestación de servicios
├── Dockerfile                  # Imagen de la API
├── app.py                      # API con DatabaseRouter
├── init.sql                    # Script de inicialización de BD
├── nginx.conf                  # Configuración de Nginx
├── index.html                  # Frontend
├── requirements.txt            # Dependencias Python
├── .env                        # Variables de entorno (no commitear)
├── .env.example                # Plantilla de variables de entorno
├── scripts/
│   ├── postgres-primary-init.sh      # Configuración PRIMARY
│   ├── postgres-replica-init.sh      # Script auxiliar (no usado)
│   └── docker-entrypoint-replica.sh  # Entrypoint para REPLICA
├── ENV_VARIABLES.md            # Documentación de variables
└── README_LOAD_BALANCER.md      # Este archivo
```

## Healthchecks

Todos los servicios incluyen healthchecks:

- **db-primary**: Verifica que PostgreSQL esté listo
- **db-replica**: Verifica que PostgreSQL esté listo
- **api**: Verifica que el endpoint `/api/health` responda
- **frontend**: Verifica que Nginx responda

## Monitoreo

### Endpoint de Health

El endpoint `/api/health` proporciona información sobre el estado:

```json
{
  "status": "healthy",
  "primary": "connected",
  "replica": "connected"
}
```

### Verificar Replicación

Para verificar que la replicación está funcionando:

```bash
# Conectarse a PRIMARY
docker exec -it research_db_primary psql -U postgres_user -d synthetic_data_db

# Ver slots de replicación
SELECT * FROM pg_replication_slots;

# Conectarse a REPLICA
docker exec -it research_db_replica psql -U postgres_user -d synthetic_data_db

# Verificar que está en modo réplica
SELECT pg_is_in_recovery();
```

## Troubleshooting

### La réplica no se conecta

1. Verifica que PRIMARY esté corriendo y saludable
2. Verifica las credenciales de replicación
3. Revisa los logs: `docker-compose logs db-replica`

### La API usa PRIMARY para todo

Esto puede ocurrir si:
- La réplica no está disponible (comportamiento esperado con fallback)
- Hay un error de conexión a la réplica

Verifica los logs: `docker-compose logs api`

### Recrear la réplica

Si necesitas recrear la réplica desde cero:

```bash
docker-compose stop db-replica
docker volume rm research_portal_postgres_replica_data
docker-compose up -d db-replica
```

## Seguridad

- **NUNCA** commitees el archivo `.env`
- Cambia todas las contraseñas por defecto en producción
- Usa contraseñas seguras y únicas
- Considera usar Docker Secrets en producción

## Próximos Pasos

- [ ] Implementar múltiples réplicas para mayor escalabilidad
- [ ] Agregar métricas y monitoreo (Prometheus/Grafana)
- [ ] Implementar pool de conexiones
- [ ] Agregar cache (Redis) para lecturas frecuentes
- [ ] Implementar backup automático

