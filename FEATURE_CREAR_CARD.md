# Feature: Panel de Creación de Cards

## ✅ Implementación Completada

Se ha implementado un panel lateral deslizable en el frontend que permite a los usuarios crear nuevas cards de contenido sin necesidad de autenticación.

## Características Implementadas

### 1. Panel Lateral (Drawer)
- Panel deslizable desde la derecha
- Diseño responsive y consistente con el estilo existente
- Se abre/cierra con animación suave
- Se puede cerrar haciendo clic fuera del panel

### 2. Formulario Completo
El formulario incluye todos los campos de la tabla `contenidos`:

#### Campos Obligatorios:
- **Facultad**: Select con todas las facultades disponibles
- **Tema**: Select con todos los temas disponibles
- **Tipo**: Select (Debate, Análisis, Estudio)
- **Título**: Texto (máx. 255 caracteres)
- **Resumen**: Textarea

**Nota**: El **ID Contenido** se genera automáticamente por el backend para garantizar la integridad de los datos. El usuario no puede ni debe escribir el ID.

#### Campos Opcionales:
- **Emoción Dominante**: Select (Miedo, Preocupación, Conflicto, Curiosidad, Duda, Interés, Esperanza, Riesgo)
- **Intensidad de Emoción**: Number (0.0 - 1.0)
- **Tipo de Fuente**: Select (Paper Académico, Think Tank, Artículo, Libro, Informe)
- **Origen de Fuente**: Texto (máx. 100 caracteres)
- **URL Ver**: URL del artículo
- **URL Descargar**: URL para descargar
- **Tags**: Campo de texto separado por comas

### 3. Endpoint API POST
- **Ruta**: `/api/contenidos`
- **Método**: POST
- **Body**: JSON con todos los campos del formulario
- **Comportamiento**: 
  - Usa PRIMARY database (escritura)
  - Inserta el contenido principal
  - Inserta los tags asociados si existen
  - Maneja errores de integridad (IDs duplicados, claves foráneas)

### 4. Validación y Feedback
- Validación de campos requeridos en el frontend
- Mensajes de éxito/error visuales
- Recarga automática de contenidos después de crear exitosamente
- Manejo de errores de integridad de base de datos

## Archivos Modificados

### Backend (`app.py`)
- ✅ Agregado modelo Pydantic `ContenidoCreate`
- ✅ Agregado endpoint `POST /api/contenidos`
- ✅ Manejo de inserción de contenido y tags
- ✅ Uso de PRIMARY database para escritura

### Frontend (`index.html`)
- ✅ Botón "Crear Card" en el header
- ✅ Panel lateral con formulario completo
- ✅ JavaScript para manejo del formulario
- ✅ Carga dinámica de facultades y temas
- ✅ Validación y envío de datos
- ✅ Mensajes de feedback

## Uso

1. **Abrir el panel**: Hacer clic en el botón "Crear Card" en el header
2. **Completar el formulario**: Llenar los campos requeridos y opcionales
3. **Enviar**: Hacer clic en "Crear Card"
4. **Resultado**: 
   - Si es exitoso: Se muestra mensaje de éxito y se recarga la lista
   - Si hay error: Se muestra mensaje de error con detalles

## Estructura de Datos

### Modelo ContenidoCreate
```python
{
    "id_tema": "string (requerido)",
    "id_facultad": "string (requerido)",
    "tipo": "string (requerido: Debate/Analisis/Estudio)",
    "titulo": "string (requerido, máx. 255)",
    "resumen": "string (requerido)",
    "emocion_dominante": "string (opcional)",
    "emocion_intensidad": "float (opcional, 0.0-1.0)",
    "tipo_fuente": "string (opcional)",
    "origen_fuente": "string (opcional, máx. 100)",
    "url_ver": "string URL (opcional)",
    "url_descargar": "string URL (opcional)",
    "tags": ["string"] (opcional, array de strings)
}
```

**Nota**: El campo `id_contenido` se genera automáticamente en el backend usando la función `generar_id_contenido_unico()` que crea IDs únicos basados en:
- ID de facultad
- Tipo de contenido (abreviado)
- Hash del título
- Timestamp

Formato del ID generado: `{facultad}_{tipo_abrev}_{hash_titulo}_{timestamp}`

## Ejemplo de Uso

```javascript
// El formulario envía automáticamente (sin id_contenido):
{
    "id_tema": "gp_deepfakes_electorales",
    "id_facultad": "GP",
    "tipo": "Debate",
    "titulo": "Nuevo tema de debate",
    "resumen": "Descripción del nuevo contenido...",
    "emocion_dominante": "Preocupación",
    "emocion_intensidad": 0.75,
    "tipo_fuente": "paper",
    "origen_fuente": "paper_academico",
    "url_ver": "https://ejemplo.com/articulo",
    "tags": ["tag1", "tag2", "tag3"]
}

// El backend genera automáticamente el ID, por ejemplo:
// "gp_deb_a1b2c3d4_123456"
```

## Notas Técnicas

- **Sin Autenticación**: Como se solicitó, no hay validación de permisos o roles
- **Routing Automático**: El endpoint usa `force_primary=True` para asegurar escritura en PRIMARY
- **Validación**: 
  - Frontend: Validación HTML5 de campos requeridos
  - Backend: Validación Pydantic automática
  - Base de datos: Constraints de integridad referencial
- **Estilos**: Mantiene consistencia con Tailwind CSS y diseño existente
- **Responsive**: El panel se adapta a diferentes tamaños de pantalla

## Logging en Terminal

✅ **Implementado**: Logging detallado en la terminal cuando se crea una card.

### Ver Logs en Tiempo Real

```bash
# Ver logs de la API (recomendado)
docker-compose logs -f api

# Ver logs del contenedor directamente
docker logs -f research_api
```

### Información Mostrada

Cuando se crea una card, verás en la terminal:
- 📝 Detalles completos del contenido creado
- 💾 Confirmación de conexión a PRIMARY database
- ✅ Estado de inserción del contenido
- 🏷️ Tags insertados (si hay)
- 💾 Confirmación de COMMIT
- ✨ Mensaje de éxito final

Ver documentación completa en `VER_LOGS.md`

## Generación Automática de IDs

✅ **Implementado**: El sistema genera automáticamente IDs únicos para cada contenido.

### Función de Generación

El backend incluye la función `generar_id_contenido_unico()` que:
1. Crea un ID base usando: `{facultad}_{tipo_abrev}_{hash_titulo}_{timestamp}`
2. Verifica que el ID sea único en la base de datos
3. Si existe, genera uno nuevo con un sufijo adicional
4. Garantiza unicidad hasta 10 intentos
5. Usa UUID como fallback si es necesario

### Ventajas

- ✅ **Integridad de datos**: No hay riesgo de IDs duplicados
- ✅ **Consistencia**: Formato uniforme de IDs
- ✅ **Automatización**: El usuario no necesita preocuparse por el ID
- ✅ **Trazabilidad**: Los IDs incluyen información sobre el contenido

## Próximas Mejoras Posibles

- [x] Generación automática de IDs (✅ Implementado)
- [ ] Preview de la card antes de crear
- [ ] Edición de cards existentes
- [ ] Eliminación de cards
- [ ] Validación de URLs antes de enviar
- [ ] Mostrar el ID generado al usuario después de crear

