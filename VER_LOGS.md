# Cómo Ver los Logs de Creación de Cards

## 📋 Logging Implementado

Se ha agregado logging detallado en el endpoint POST `/api/contenidos` que muestra información completa cuando se crea una nueva card en la base de datos.

## 🔍 Ver Logs en Tiempo Real

### Opción 1: Logs de Docker Compose (Recomendado)

```bash
# Ver todos los logs de la API
docker-compose logs -f api

# Ver solo los últimos 50 logs
docker-compose logs --tail=50 api

# Ver logs con timestamps
docker-compose logs -f --timestamps api
```

### Opción 2: Logs Directos del Contenedor

```bash
# Ver logs del contenedor de la API
docker logs -f research_api

# Ver últimos 100 logs
docker logs --tail=100 research_api

# Ver logs con timestamps
docker logs -f --timestamps research_api
```

### Opción 3: Logs de la Base de Datos

```bash
# Ver logs de PRIMARY (donde se escriben los datos)
docker logs -f research_db_primary

# Ver logs de REPLICA (donde se replican los datos)
docker logs -f research_db_replica
```

## 📊 Información que se Muestra

Cuando se crea una card, verás en los logs:

```
================================================================================
📝 NUEVA SOLICITUD DE CREACIÓN DE CONTENIDO
================================================================================
🆔 ID Contenido: nuevo_cont_1
📚 Facultad: GP
🎯 Tema: gp_deepfakes_electorales
📋 Tipo: Debate
📌 Título: Nuevo tema de debate
📄 Resumen: Descripción del nuevo contenido...
😊 Emoción: Preocupación (Intensidad: 0.75)
📖 Fuente: paper - paper_academico
🔗 URL Ver: https://ejemplo.com/articulo
🏷️ Tags: tag1, tag2, tag3
--------------------------------------------------------------------------------
💾 Conectando a PRIMARY database para escritura...
✅ Conexión establecida con PRIMARY database
📥 Insertando contenido principal...
✅ Contenido insertado exitosamente. ID: nuevo_cont_1
🏷️ Insertando 3 tag(s)...
   ✓ Tag insertado: 'tag1'
   ✓ Tag insertado: 'tag2'
   ✓ Tag insertado: 'tag3'
✅ 3 tag(s) insertado(s) exitosamente
💾 Cambios confirmados (COMMIT) en PRIMARY database
================================================================================
✨ CONTENIDO CREADO EXITOSAMENTE: nuevo_cont_1
================================================================================
```

## ⚠️ En Caso de Error

Si hay un error, verás información detallada:

```
================================================================================
❌ ERROR DE INTEGRIDAD EN BASE DE DATOS
================================================================================
🔴 Error: duplicate key value violates unique constraint "contenidos_pkey"
🆔 ID Contenido: nuevo_cont_1
💡 Posibles causas:
   - El ID de contenido ya existe
   - La facultad o tema no existe en la base de datos
   - Violación de restricción de clave foránea
================================================================================
```

## 🎯 Ejemplo de Uso

1. **Abrir una terminal y ejecutar:**
   ```bash
   docker-compose logs -f api
   ```

2. **En otra terminal o en el navegador, crear una card**

3. **Verás inmediatamente en la primera terminal todos los detalles de la creación**

## 🔧 Filtrado de Logs

### Ver solo logs de creación de contenidos:
```bash
docker-compose logs -f api | grep "NUEVA SOLICITUD"
```

### Ver solo errores:
```bash
docker-compose logs -f api | grep "ERROR"
```

### Ver solo operaciones exitosas:
```bash
docker-compose logs -f api | grep "CONTENIDO CREADO EXITOSAMENTE"
```

## 📝 Notas

- Los logs se muestran en tiempo real con `-f` (follow)
- Los timestamps están incluidos en cada línea
- Los logs persisten incluso después de reiniciar el contenedor
- Puedes usar `Ctrl+C` para salir del modo follow

