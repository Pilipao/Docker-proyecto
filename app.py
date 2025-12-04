from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import psycopg2
from psycopg2.extras import RealDictCursor
import os
import json
import re
import logging
import hashlib
from contextlib import contextmanager
from datetime import datetime

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

app = FastAPI()

# Configurar CORS para permitir solicitudes desde el frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

# =========================================================
# CONFIGURACIÓN DE BASE DE DATOS - LOAD BALANCER
# =========================================================

# Configuración Primary (Escritura)
DB_PRIMARY_HOST = os.getenv("DB_PRIMARY_HOST", "db-primary")
DB_PRIMARY_PORT = int(os.getenv("DB_PRIMARY_PORT", "5432"))
DB_PRIMARY_NAME = os.getenv("DB_PRIMARY_NAME", "synthetic_data_db")
DB_PRIMARY_USER = os.getenv("DB_PRIMARY_USER", "postgres_user")
DB_PRIMARY_PASSWORD = os.getenv("DB_PRIMARY_PASSWORD", "postgres_password_secure_2024")

# Configuración Replica (Lectura)
DB_REPLICA_HOST = os.getenv("DB_REPLICA_HOST", "db-replica")
DB_REPLICA_PORT = int(os.getenv("DB_REPLICA_PORT", "5432"))
DB_REPLICA_NAME = os.getenv("DB_REPLICA_NAME", "synthetic_data_db")
DB_REPLICA_USER = os.getenv("DB_REPLICA_USER", "postgres_user")
DB_REPLICA_PASSWORD = os.getenv("DB_REPLICA_PASSWORD", "postgres_password_secure_2024")


class DatabaseRouter:
    """
    Router de base de datos que enruta automáticamente:
    - Lecturas (SELECT) -> Replica
    - Escrituras (INSERT/UPDATE/DELETE) -> Primary
    - Fallback a Primary si Replica no está disponible
    """
    
    def __init__(self):
        self._primary_conn = None
        self._replica_conn = None
        self._replica_available = True
    
    def _get_primary_connection(self):
        """Obtener conexión a la base de datos PRIMARY (escritura)."""
        try:
            if self._primary_conn is None or self._primary_conn.closed:
                self._primary_conn = psycopg2.connect(
                    host=DB_PRIMARY_HOST,
                    port=DB_PRIMARY_PORT,
                    database=DB_PRIMARY_NAME,
                    user=DB_PRIMARY_USER,
                    password=DB_PRIMARY_PASSWORD
                )
            return self._primary_conn
        except Exception as e:
            raise ConnectionError(f"Error conectando a PRIMARY: {str(e)}")
    
    def _get_replica_connection(self):
        """Obtener conexión a la base de datos REPLICA (lectura)."""
        if not self._replica_available:
            # Si la réplica no está disponible, usar primary como fallback
            return self._get_primary_connection()
        
        try:
            if self._replica_conn is None or self._replica_conn.closed:
                self._replica_conn = psycopg2.connect(
                    host=DB_REPLICA_HOST,
                    port=DB_REPLICA_PORT,
                    database=DB_REPLICA_NAME,
                    user=DB_REPLICA_USER,
                    password=DB_REPLICA_PASSWORD
                )
            return self._replica_conn
        except Exception as e:
            # Si falla la réplica, marcar como no disponible y usar primary
            print(f"Warning: Réplica no disponible, usando PRIMARY como fallback: {str(e)}")
            self._replica_available = False
            return self._get_primary_connection()
    
    def _is_read_query(self, query: str) -> bool:
        """
        Determinar si una query es de lectura (SELECT) o escritura (INSERT/UPDATE/DELETE).
        """
        # Normalizar query: remover espacios y convertir a mayúsculas
        normalized = re.sub(r'\s+', ' ', query.strip().upper())
        
        # Verificar si comienza con SELECT
        if normalized.startswith('SELECT'):
            return True
        
        # Verificar si contiene operaciones de escritura
        write_keywords = ['INSERT', 'UPDATE', 'DELETE', 'CREATE', 'DROP', 'ALTER', 'TRUNCATE']
        for keyword in write_keywords:
            if normalized.startswith(keyword) or f' {keyword} ' in normalized:
                return False
        
        # Por defecto, asumir lectura si no se puede determinar
        return True
    
    @contextmanager
    def get_connection(self, query: Optional[str] = None, force_primary: bool = False):
        """
        Obtener conexión apropiada según el tipo de query.
        
        Args:
            query: La query SQL a ejecutar (opcional, para auto-detección)
            force_primary: Forzar uso de PRIMARY incluso para lecturas
        
        Returns:
            Conexión a la base de datos apropiada
        """
        if force_primary:
            conn = self._get_primary_connection()
        elif query and not self._is_read_query(query):
            # Escritura -> PRIMARY
            conn = self._get_primary_connection()
        else:
            # Lectura -> REPLICA (con fallback a PRIMARY)
            conn = self._get_replica_connection()
        
        try:
            yield conn
        except Exception as e:
            # Si hay error con la réplica, intentar con primary
            if conn == self._replica_conn and self._replica_available:
                print(f"Error con réplica, intentando con PRIMARY: {str(e)}")
                self._replica_available = False
                conn = self._get_primary_connection()
                yield conn
            else:
                raise
    
    def check_replica_health(self) -> bool:
        """Verificar si la réplica está disponible."""
        try:
            conn = self._get_replica_connection()
            cur = conn.cursor()
            cur.execute("SELECT 1")
            cur.close()
            if conn != self._primary_conn:
                conn.close()
            self._replica_available = True
            return True
        except:
            self._replica_available = False
            return False


# Instancia global del router
db_router = DatabaseRouter()


# =========================================================
# FUNCIONES AUXILIARES
# =========================================================

def generar_id_contenido(id_facultad: str, tipo: str, titulo: str) -> str:
    """
    Genera un ID único para un contenido basado en:
    - ID de facultad
    - Tipo de contenido (abreviado)
    - Hash del título para unicidad
    - Timestamp para evitar colisiones
    """
    # Abreviar tipo de contenido
    tipo_abrev = {
        "Debate": "deb",
        "Analisis": "ana",
        "Análisis": "ana",
        "Estudio": "est"
    }.get(tipo, "con")
    
    # Crear hash corto del título (primeros 8 caracteres)
    titulo_hash = hashlib.md5(titulo.encode('utf-8')).hexdigest()[:8]
    
    # Timestamp corto (últimos 6 dígitos)
    timestamp = str(int(datetime.now().timestamp()))[-6:]
    
    # Formato: {facultad}_{tipo_abrev}_{hash}_{timestamp}
    id_contenido = f"{id_facultad.lower()}_{tipo_abrev}_{titulo_hash}_{timestamp}"
    
    return id_contenido


def verificar_id_unico(id_contenido: str) -> bool:
    """
    Verifica si un ID de contenido ya existe en la base de datos.
    Retorna True si el ID es único, False si ya existe.
    """
    try:
        query = "SELECT COUNT(*) FROM contenidos WHERE id_contenido = %s"
        with db_router.get_connection(query, force_primary=True) as conn:
            cur = conn.cursor()
            cur.execute(query, (id_contenido,))
            count = cur.fetchone()[0]
            cur.close()
        return count == 0
    except Exception as e:
        logger.warning(f"Error verificando ID único: {e}")
        return True  # En caso de error, asumir que es único


def generar_id_contenido_unico(id_facultad: str, tipo: str, titulo: str) -> str:
    """
    Genera un ID único para contenido, verificando que no exista en la BD.
    Si existe, genera uno nuevo con un sufijo adicional.
    """
    id_base = generar_id_contenido(id_facultad, tipo, titulo)
    id_contenido = id_base
    
    # Verificar unicidad y generar nuevo si es necesario
    intentos = 0
    max_intentos = 10
    
    while not verificar_id_unico(id_contenido) and intentos < max_intentos:
        intentos += 1
        # Agregar sufijo numérico
        timestamp_extra = str(int(datetime.now().timestamp()))[-4:]
        id_contenido = f"{id_base}_{timestamp_extra}"
    
    if intentos >= max_intentos:
        # Fallback: usar UUID corto
        import uuid
        id_contenido = f"{id_facultad.lower()}_{tipo[:3].lower()}_{uuid.uuid4().hex[:12]}"
        logger.warning(f"Se generó ID con UUID fallback: {id_contenido}")
    
    return id_contenido


# =========================================================
# MODELOS PYDANTIC
# =========================================================

class ContenidoCreate(BaseModel):
    id_tema: str
    id_facultad: str
    tipo: str
    titulo: str
    resumen: str
    emocion_dominante: Optional[str] = None
    emocion_intensidad: Optional[float] = None
    tipo_fuente: Optional[str] = None
    origen_fuente: Optional[str] = None
    url_ver: Optional[str] = None
    url_descargar: Optional[str] = None
    tags: Optional[List[str]] = []


# =========================================================
# ENDPOINTS DE LA API
# =========================================================

@app.get("/api/facultades")
def get_facultades():
    """Obtener todas las facultades (LECTURA -> REPLICA)."""
    try:
        query = "SELECT id_facultad, nombre, color_hex FROM facultades ORDER BY nombre"
        with db_router.get_connection(query) as conn:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            cur.execute(query)
            facultades = cur.fetchall()
            cur.close()
        return {"success": True, "data": facultades}
    except Exception as e:
        return {"success": False, "error": str(e)}

@app.get("/api/temas")
def get_temas():
    """Obtener todos los temas (LECTURA -> REPLICA)."""
    try:
        query = "SELECT id_tema, nombre, descripcion FROM temas ORDER BY nombre"
        with db_router.get_connection(query) as conn:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            cur.execute(query)
            temas = cur.fetchall()
            cur.close()
        return {"success": True, "data": temas}
    except Exception as e:
        return {"success": False, "error": str(e)}

@app.get("/api/contenidos")
def get_contenidos(facultad: str = None, search: str = None):
    """Obtener contenidos, opcionalmente filtrados por facultad o búsqueda (LECTURA -> REPLICA)."""
    try:
        query = """
            SELECT 
                c.id_contenido, c.id_tema, c.id_facultad, c.tipo, c.titulo, c.resumen,
                c.emocion_dominante, c.emocion_intensidad, c.tipo_fuente, c.origen_fuente,
                c.url_ver, c.url_descargar,
                f.nombre as facultad_nombre, f.color_hex,
                t.nombre as tema_nombre
            FROM contenidos c
            JOIN facultades f ON c.id_facultad = f.id_facultad
            JOIN temas t ON c.id_tema = t.id_tema
            WHERE 1=1
        """
        
        params = []
        
        if facultad and facultad != "Todos":
            query += " AND c.id_facultad = %s"
            params.append(facultad)
        
        if search:
            query += " AND (c.titulo ILIKE %s OR c.resumen ILIKE %s OR t.nombre ILIKE %s)"
            search_param = f"%{search}%"
            params.extend([search_param, search_param, search_param])
        
        query += " ORDER BY c.created_at DESC"
        
        with db_router.get_connection(query) as conn:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            cur.execute(query, params)
            contenidos = cur.fetchall()
            cur.close()
        return {"success": True, "data": contenidos}
    except Exception as e:
        return {"success": False, "error": str(e)}

@app.get("/api/contenidos/{id_contenido}")
def get_contenido_detail(id_contenido: str):
    """Obtener detalles de un contenido específico con sus listas asociadas (LECTURA -> REPLICA)."""
    try:
        with db_router.get_connection() as conn:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            
            # Obtener el contenido principal
            cur.execute("""
                SELECT 
                    c.id_contenido, c.id_tema, c.id_facultad, c.tipo, c.titulo, c.resumen,
                    c.emocion_dominante, c.emocion_intensidad, c.tipo_fuente, c.origen_fuente,
                    c.url_ver, c.url_descargar,
                    f.nombre as facultad_nombre, f.color_hex,
                    t.nombre as tema_nombre, t.descripcion as tema_descripcion
                FROM contenidos c
                JOIN facultades f ON c.id_facultad = f.id_facultad
                JOIN temas t ON c.id_tema = t.id_tema
                WHERE c.id_contenido = %s
            """, (id_contenido,))
            contenido = cur.fetchone()
            
            if not contenido:
                cur.close()
                return {"success": False, "error": "Contenido no encontrado"}
            
            # Obtener tags
            cur.execute("SELECT tag FROM contenido_tags WHERE id_contenido = %s", (id_contenido,))
            tags = [row['tag'] for row in cur.fetchall()]
            
            # Obtener conceptos clave del tema
            cur.execute("SELECT concepto FROM tema_key_concepts WHERE id_tema = %s", (contenido['id_tema'],))
            key_concepts = [row['concepto'] for row in cur.fetchall()]
            
            # Obtener actores principales
            cur.execute("SELECT actor FROM tema_main_actors WHERE id_tema = %s", (contenido['id_tema'],))
            main_actors = [row['actor'] for row in cur.fetchall()]
            
            # Obtener casos de estudio
            cur.execute("SELECT caso_estudio FROM tema_case_studies WHERE id_tema = %s", (contenido['id_tema'],))
            case_studies = [row['caso_estudio'] for row in cur.fetchall()]
            
            # Obtener tendencias futuras
            cur.execute("SELECT tendencia_futura FROM tema_future_trends WHERE id_tema = %s", (contenido['id_tema'],))
            future_trends = [row['tendencia_futura'] for row in cur.fetchall()]
            
            cur.close()
        
        contenido['tags'] = tags
        contenido['key_concepts'] = key_concepts
        contenido['main_actors'] = main_actors
        contenido['case_studies'] = case_studies
        contenido['future_trends'] = future_trends
        
        return {"success": True, "data": contenido}
    except Exception as e:
        return {"success": False, "error": str(e)}

@app.get("/api/search")
def search_contenidos(q: str):
    """Buscar contenidos por término (LECTURA -> REPLICA)."""
    try:
        search_param = f"%{q}%"
        query = """
            SELECT 
                c.id_contenido, c.id_tema, c.id_facultad, c.tipo, c.titulo, c.resumen,
                f.nombre as facultad_nombre, f.color_hex,
                t.nombre as tema_nombre
            FROM contenidos c
            JOIN facultades f ON c.id_facultad = f.id_facultad
            JOIN temas t ON c.id_tema = t.id_tema
            WHERE c.titulo ILIKE %s OR c.resumen ILIKE %s OR t.nombre ILIKE %s
            ORDER BY c.created_at DESC
            LIMIT 20
        """
        
        with db_router.get_connection(query) as conn:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            cur.execute(query, (search_param, search_param, search_param))
            resultados = cur.fetchall()
            cur.close()
        return {"success": True, "data": resultados}
    except Exception as e:
        return {"success": False, "error": str(e)}

@app.delete("/api/contenidos/{id_contenido}", status_code=204)
async def delete_contenido(id_contenido: str):
    """
    Eliminar un contenido por su ID (ESCRITURA -> PRIMARY).
    También elimina automáticamente los tags asociados debido a la restricción CASCADE.
    """
    try:
        with db_router.get_connection(force_primary=True) as conn:
            with conn.cursor() as cur:
                # Verificar si el contenido existe
                cur.execute(
                    "SELECT 1 FROM contenidos WHERE id_contenido = %s",
                    (id_contenido,)
                )
                if not cur.fetchone():
                    raise HTTPException(
                        status_code=404,
                        detail=f"No se encontró el contenido con ID: {id_contenido}"
                    )
                
                # Eliminar el contenido (los tags se eliminan en cascada)
                cur.execute(
                    "DELETE FROM contenidos WHERE id_contenido = %s",
                    (id_contenido,)
                )
                conn.commit()
                
                logger.info(f"Contenido eliminado exitosamente: {id_contenido}")
                return None
                
    except HTTPException as he:
        raise he
    except Exception as e:
        logger.error(f"Error al eliminar contenido: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al eliminar el contenido: {str(e)}"
        )

@app.post("/api/contenidos")
def create_contenido(contenido: ContenidoCreate):
    """Crear un nuevo contenido (ESCRITURA -> PRIMARY). El ID se genera automáticamente."""
    try:
        logger.info("=" * 80)
        logger.info("📝 NUEVA SOLICITUD DE CREACIÓN DE CONTENIDO")
        logger.info("=" * 80)
        logger.info(f"📚 Facultad: {contenido.id_facultad}")
        logger.info(f"🎯 Tema: {contenido.id_tema}")
        logger.info(f"📋 Tipo: {contenido.tipo}")
        logger.info(f"📌 Título: {contenido.titulo}")
        logger.info(f"📄 Resumen: {contenido.resumen[:100]}..." if len(contenido.resumen) > 100 else f"📄 Resumen: {contenido.resumen}")
        
        if contenido.emocion_dominante:
            logger.info(f"😊 Emoción: {contenido.emocion_dominante} (Intensidad: {contenido.emocion_intensidad or 'N/A'})")
        if contenido.tipo_fuente:
            logger.info(f"📖 Fuente: {contenido.tipo_fuente} - {contenido.origen_fuente or 'N/A'}")
        if contenido.url_ver:
            logger.info(f"🔗 URL Ver: {contenido.url_ver}")
        if contenido.url_descargar:
            logger.info(f"⬇️ URL Descargar: {contenido.url_descargar}")
        if contenido.tags and len(contenido.tags) > 0:
            logger.info(f"🏷️ Tags: {', '.join(contenido.tags)}")
        
        logger.info("-" * 80)
        logger.info("🔑 Generando ID único para el contenido...")
        
        # Generar ID único automáticamente
        id_contenido = generar_id_contenido_unico(
            contenido.id_facultad,
            contenido.tipo,
            contenido.titulo
        )
        
        logger.info(f"✅ ID generado: {id_contenido}")
        logger.info("-" * 80)
        logger.info("💾 Conectando a PRIMARY database para escritura...")
        
        # Usar PRIMARY para escritura
        query = """
            INSERT INTO contenidos (
                id_contenido, id_tema, id_facultad, tipo, titulo, resumen,
                emocion_dominante, emocion_intensidad, tipo_fuente, origen_fuente,
                url_ver, url_descargar
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id_contenido
        """
        
        with db_router.get_connection(query, force_primary=True) as conn:
            cur = conn.cursor()
            
            logger.info("✅ Conexión establecida con PRIMARY database")
            logger.info("📥 Insertando contenido principal...")
            
            # Insertar contenido principal
            cur.execute(query, (
                id_contenido,
                contenido.id_tema,
                contenido.id_facultad,
                contenido.tipo,
                contenido.titulo,
                contenido.resumen,
                contenido.emocion_dominante,
                contenido.emocion_intensidad,
                contenido.tipo_fuente,
                contenido.origen_fuente,
                contenido.url_ver,
                contenido.url_descargar
            ))
            
            resultado = cur.fetchone()
            logger.info(f"✅ Contenido insertado exitosamente. ID: {resultado[0] if resultado else id_contenido}")
            
            # Insertar tags si existen
            tags_insertados = 0
            if contenido.tags and len(contenido.tags) > 0:
                logger.info(f"🏷️ Insertando {len(contenido.tags)} tag(s)...")
                tags_query = "INSERT INTO contenido_tags (id_contenido, tag) VALUES (%s, %s)"
                for tag in contenido.tags:
                    if tag.strip():  # Solo insertar tags no vacíos
                        cur.execute(tags_query, (id_contenido, tag.strip()))
                        tags_insertados += 1
                        logger.info(f"   ✓ Tag insertado: '{tag.strip()}'")
                
                if tags_insertados > 0:
                    logger.info(f"✅ {tags_insertados} tag(s) insertado(s) exitosamente")
            
            conn.commit()
            logger.info("💾 Cambios confirmados (COMMIT) en PRIMARY database")
            cur.close()
        
        logger.info("=" * 80)
        logger.info(f"✨ CONTENIDO CREADO EXITOSAMENTE: {id_contenido}")
        logger.info("=" * 80)
        logger.info("")
        
        return {"success": True, "message": "Contenido creado exitosamente", "id_contenido": id_contenido}
    except psycopg2.IntegrityError as e:
        logger.error("=" * 80)
        logger.error("❌ ERROR DE INTEGRIDAD EN BASE DE DATOS")
        logger.error("=" * 80)
        logger.error(f"🔴 Error: {str(e)}")
        logger.error("💡 Posibles causas:")
        logger.error("   - La facultad o tema no existe en la base de datos")
        logger.error("   - Violación de restricción de clave foránea")
        logger.error("=" * 80)
        logger.error("")
        return {"success": False, "error": f"Error de integridad: Hay un problema con las claves foráneas (facultad o tema no existe)"}
    except Exception as e:
        logger.error("=" * 80)
        logger.error("❌ ERROR AL CREAR CONTENIDO")
        logger.error("=" * 80)
        logger.error(f"🔴 Error: {str(e)}")
        logger.error("=" * 80)
        logger.error("")
        return {"success": False, "error": str(e)}

@app.get("/api/health")
def health_check():
    """Verificar la salud de la API y las conexiones a las bases de datos."""
    try:
        health_status = {
            "status": "healthy",
            "primary": "unknown",
            "replica": "unknown"
        }
        
        # Verificar PRIMARY
        try:
            with db_router.get_connection(force_primary=True) as conn:
                cur = conn.cursor()
                cur.execute("SELECT 1")
                cur.close()
            health_status["primary"] = "connected"
        except Exception as e:
            health_status["primary"] = f"disconnected: {str(e)}"
            health_status["status"] = "unhealthy"
        
        # Verificar REPLICA
        replica_available = db_router.check_replica_health()
        health_status["replica"] = "connected" if replica_available else "disconnected"
        
        return health_status
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e),
            "primary": "unknown",
            "replica": "unknown"
        }
