# Variables de Entorno - Research Portal

Este documento describe todas las variables de entorno utilizadas en el sistema de load balancer con réplica de base de datos.

## Configuración de Puertos

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `FRONTEND_PORT` | Puerto del servicio frontend (Nginx) | `80` |
| `API_PORT` | Puerto del servicio API (FastAPI) | `8000` |
| `DB_PRIMARY_PORT` | Puerto de la base de datos PRIMARY | `5432` |
| `DB_REPLICA_PORT` | Puerto de la base de datos REPLICA | `5433` |

## Configuración Base de Datos PRIMARY (Escritura)

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `DB_PRIMARY_HOST` | Hostname del servidor PRIMARY | `db-primary` |
| `DB_PRIMARY_PORT` | Puerto del servidor PRIMARY | `5432` |
| `DB_PRIMARY_NAME` | Nombre de la base de datos | `synthetic_data_db` |
| `DB_PRIMARY_USER` | Usuario de la base de datos PRIMARY | `postgres_user` |
| `DB_PRIMARY_PASSWORD` | Contraseña del usuario PRIMARY | `postgres_password_secure_2024` |
| `DB_PRIMARY_URL` | URL completa de conexión PRIMARY | `postgresql://postgres_user:postgres_password_secure_2024@db-primary:5432/synthetic_data_db` |

## Configuración Base de Datos REPLICA (Lectura)

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `DB_REPLICA_HOST` | Hostname del servidor REPLICA | `db-replica` |
| `DB_REPLICA_PORT` | Puerto del servidor REPLICA | `5432` |
| `DB_REPLICA_NAME` | Nombre de la base de datos | `synthetic_data_db` |
| `DB_REPLICA_USER` | Usuario de la base de datos REPLICA | `postgres_user` |
| `DB_REPLICA_PASSWORD` | Contraseña del usuario REPLICA | `postgres_password_secure_2024` |
| `DB_REPLICA_URL` | URL completa de conexión REPLICA | `postgresql://postgres_user:postgres_password_secure_2024@db-replica:5432/synthetic_data_db` |

## Configuración de Replicación PostgreSQL

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `POSTGRES_REPLICATION_USER` | Usuario para replicación | `replicator` |
| `POSTGRES_REPLICATION_PASSWORD` | Contraseña para replicación | `replicator_password_secure_2024` |
| `POSTGRES_MASTER_REPLICATION_SLOT` | Nombre del slot de replicación | `replica_slot` |

## Configuración API

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `API_HOST` | Host de la API | `0.0.0.0` |
| `API_PORT` | Puerto de la API | `8000` |
| `API_WORKERS` | Número de workers (no usado actualmente) | `4` |

## Configuración de Red

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `NETWORK_NAME` | Nombre de la red Docker | `research_network` |

## Configuración de Healthchecks

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `HEALTHCHECK_INTERVAL` | Intervalo entre healthchecks | `10s` |
| `HEALTHCHECK_TIMEOUT` | Timeout del healthcheck | `5s` |
| `HEALTHCHECK_RETRIES` | Número de reintentos | `5` |

## Uso

1. Copia el archivo `.env.example` a `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edita el archivo `.env` y ajusta los valores según tu entorno.

3. Asegúrate de cambiar las contraseñas por defecto en producción.

4. Inicia los servicios:
   ```bash
   docker-compose up -d
   ```

## Notas de Seguridad

- **NUNCA** commitees el archivo `.env` al repositorio.
- Cambia todas las contraseñas por defecto en producción.
- Usa contraseñas seguras y únicas para cada entorno.
- Considera usar un gestor de secretos (como Docker Secrets o Vault) en producción.

