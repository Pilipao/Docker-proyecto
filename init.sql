-- =========================================================
-- SCRIPT DE INICIALIZACIÓN DE BASE DE DATOS (PostgreSQL)
-- Estructura de Tablas y Datos Sintéticos
-- =========================================================

-- 1. ESTRUCTURA DE TABLAS (Schema)

-- 1.1 Facultades (Ingeniería, Ciencias Políticas, etc.)
CREATE TABLE IF NOT EXISTS facultades (
    id_facultad      VARCHAR(10)  PRIMARY KEY,
    nombre           VARCHAR(100) NOT NULL,
    color_hex        VARCHAR(7)   NULL,
    created_at       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 1.2 Temas globales (topics)
CREATE TABLE IF NOT EXISTS temas (
    id_tema          VARCHAR(100) PRIMARY KEY,
    nombre           VARCHAR(150) NOT NULL,
    descripcion      TEXT NULL,
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 1.3 Contenidos (Las cards que ves en la UI)
CREATE TABLE IF NOT EXISTS contenidos (
    id_contenido        VARCHAR(100) PRIMARY KEY,
    id_tema             VARCHAR(100) NOT NULL,
    id_facultad         VARCHAR(10)  NOT NULL,
    tipo                VARCHAR(50)  NOT NULL,
    titulo              VARCHAR(255) NOT NULL,
    resumen             TEXT NOT NULL,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    emocion_dominante   VARCHAR(50) NULL,
    emocion_intensidad  DECIMAL(3,2) NULL,
    tipo_fuente         VARCHAR(50) NULL,
    origen_fuente       VARCHAR(100) NULL,
    url_ver             VARCHAR(255) NULL,
    url_descargar       VARCHAR(255) NULL,
    FOREIGN KEY (id_tema)     REFERENCES temas(id_tema)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (id_facultad) REFERENCES facultades(id_facultad)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- 1.4 Listas Asociadas a cada Tema
CREATE TABLE IF NOT EXISTS tema_key_concepts (
    id                  SERIAL PRIMARY KEY,
    id_tema             VARCHAR(100) NOT NULL,
    concepto            VARCHAR(255) NOT NULL,
    FOREIGN KEY (id_tema) REFERENCES temas(id_tema)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS tema_main_actors (
    id                  SERIAL PRIMARY KEY,
    id_tema             VARCHAR(100) NOT NULL,
    actor               VARCHAR(255) NOT NULL,
    FOREIGN KEY (id_tema) REFERENCES temas(id_tema)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS tema_case_studies (
    id                  SERIAL PRIMARY KEY,
    id_tema             VARCHAR(100) NOT NULL,
    caso_estudio        VARCHAR(255) NOT NULL,
    FOREIGN KEY (id_tema) REFERENCES temas(id_tema)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS tema_future_trends (
    id                  SERIAL PRIMARY KEY,
    id_tema             VARCHAR(100) NOT NULL,
    tendencia_futura    VARCHAR(255) NOT NULL,
    FOREIGN KEY (id_tema) REFERENCES temas(id_tema)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- 1.5 Tags por contenido
CREATE TABLE IF NOT EXISTS contenido_tags (
    id              SERIAL PRIMARY KEY,
    id_contenido    VARCHAR(100) NOT NULL,
    tag             VARCHAR(100) NOT NULL,
    FOREIGN KEY (id_contenido) REFERENCES contenidos(id_contenido)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- 2. INSERCIÓN DE DATOS SINTÉTICOS

-- 2.1 Inserción de Facultades
INSERT INTO facultades (id_facultad, nombre, color_hex) VALUES
('GP', 'Ciencias Políticas y RR.II.', '#3B82F6'),
('CS', 'Ciencias Sociales', '#EC4899'),
('EC', 'Ciencias Económicas', '#F59E0B'),
('CN', 'Ciencias Naturales', '#10B981'),
('DR', 'Derecho', '#6366F1'),
('IN', 'Ingeniería', '#06B6D4'),
('PS', 'Psicología', '#F97316')
ON CONFLICT (id_facultad) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    color_hex = EXCLUDED.color_hex;

-- 2.2 Inserción de Temas Globales
INSERT INTO temas (id_tema, nombre, descripcion) VALUES
('gp_deepfakes_electorales', 'Deepfakes Electorales y Desinformación', 'Análisis de la nueva geopolítica de la desinformación y el uso de deepfakes en procesos electorales.'),
('gp_politica_eeuu_global', 'Impacto Global de la Política Interna de EE. UU.', 'Estudio del impacto de la política interna de EE. UU. (e.g., elecciones 2024/2025) en el orden global y las alianzas tradicionales.'),
('gp_polarizacion_genero', 'Polarización Global y Consenso de Género', 'La polarización global en torno a los derechos y el consenso de género como factor de conflicto internacional.'),
('gp_negacionismo_climatico', 'Narrativas de Negacionismo Climático en Streaming', 'El papel de las plataformas de streaming y redes sociales en la difusión de narrativas de negacionismo climático y su efecto en la política pública.'),
('cs_antropologia_inmersiva', 'Antropología del Futuro y Realidad Inmersiva', 'La redefinición de la humanidad por la realidad virtual, aumentada y la tecnología inmersiva.'),
('cs_confianza_medios_ia', 'Impacto Social y Confianza en Medios Digitales con IA', 'El impacto social y la confianza del consumidor en los medios digitales transformados por la IA.'),
('cs_migracion_digital', 'Migración y Globalización en la Era Digital', 'La migración y la globalización en la era digital: Nuevas metodologías reflexivas en la investigación social.'),
('cs_ansiedad_climatica', 'Ansiedad Climática como Fenómeno Social', 'La ansiedad climática como fenómeno social y cultural: ¿Es el nuevo malestar de la civilización?'),
('ec_costo_cambio_climatico', 'Costo Económico Global del Cambio Climático', 'El verdadero costo económico global del cambio climático y la efectividad de las políticas de mitigación.'),
('ec_megafirmas_big_tech', 'El Auge de las Megafirmas (Big Tech)', 'El auge de las "Megafirmas" (Big Tech) y su impacto en la inversión, la competencia y la política fiscal.'),
('ec_cbdcs_viabilidad', 'Viabilidad e Implicaciones de las CBDCs', 'La viabilidad y las implicaciones de las Monedas Digitales de Banco Central (CBDCs) en la estabilidad financiera y la privacidad.'),
('ec_expiracion_fiscal', 'Expiración de los Recortes Fiscales de 2025', 'El debate sobre la expiración de los recortes fiscales de 2025 y su efecto en la política económica y la desigualdad.'),
('cn_geoingenieria_oceanica', 'Geoingeniería Oceánica: Solución o Riesgo', 'Geoingeniería oceánica: ¿Una solución viable o un riesgo incalculable para la crisis climática?'),
('cn_ia_descubrimiento', 'El Papel de la IA en el Descubrimiento Científico', 'El papel de la IA en la aceleración del descubrimiento científico (e.g., nuevos materiales, química, medicina).'),
('cn_eficiencia_energetica', 'Investigación de Bajo Consumo y Eficiencia Energética', 'La investigación de bajo consumo y eficiencia energética para el monitoreo ambiental y la sostenibilidad.'),
('cn_oro_invisible', 'Búsqueda de "Oro Invisible" (Elementos Críticos)', 'La búsqueda de "oro invisible" (elementos críticos) y su impacto en la transición energética y la geopolítica de recursos.'),
('dr_regulacion_ia_justicia', 'Regulación de la IA en el Sistema de Justicia', 'La regulación de la IA en el sistema de justicia: Desafíos para la transparencia, el acceso y la equidad.'),
('dr_derecho_contractual_ia', 'El Futuro del Derecho Contractual y Contratos Inteligentes', 'El futuro del Derecho Contractual en 2025 ante la automatización y los contratos inteligentes.'),
('dr_ciberseguridad_derecho', 'Ciberseguridad y Derecho del Ciberespacio', 'La evolución de la Ciberseguridad y el Derecho del Ciberespacio frente a la desinformación y los ataques a infraestructuras críticas.'),
('dr_tendencias_jurisprudenciales', 'Tendencias Jurisprudenciales de las Cortes Supremas', 'El análisis de las tendencias jurisprudenciales de las Cortes Supremas y su impacto en la interpretación de la ley.'),
('in_llms_edge_computing', 'Despliegue de LLMs en Entornos de Baja Potencia', 'La eficiencia en el despliegue de Grandes Modelos de Lenguaje (LLMs) en entornos de baja potencia y el edge computing.'),
('in_computacion_reversible', 'Viabilidad de la Computación Reversible', 'La viabilidad de la computación reversible como paradigma para la eficiencia energética extrema.'),
('in_ve_autonomia_extendida', 'Vehículos Eléctricos de Autonomía Extendida e Infraestructura', 'El desarrollo de vehículos eléctricos de autonomía extendida y la infraestructura de carga inteligente.'),
('in_ia_sistemas_ciberfisicos', 'Convergencia de IA y Sistemas Ciber-Físicos', 'La convergencia de la IA y la ingeniería para la creación de sistemas ciber-físicos resilientes.'),
('ps_psicoterapia_ia', 'Psicoterapia Asistida por IA', 'La psicoterapia asistida por IA: Implicaciones éticas y clínicas de una IA que conoce al paciente mejor que él mismo.'),
('ps_disparidades_salud_mental', 'Psicología y Disparidades en Salud Mental', 'El papel de la psicología en la reducción de las disparidades en salud mental y la promoción de la equidad.'),
('ps_vr_juegos_terapia', 'Uso de Juegos de Rol y Realidad Virtual en Terapia', 'El uso de juegos de rol y realidad virtual en la terapia para trastornos de personalidad y ansiedad.'),
('ps_medios_digitales_ninos', 'Desarrollo de Medios Digitales para Niños', 'El desarrollo de medios digitales y contenidos para niños que promuevan un desarrollo psicológico saludable.')
ON CONFLICT (id_tema) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    descripcion = EXCLUDED.descripcion;

-- 2.3 Inserción de Contenidos (cards)
INSERT INTO contenidos (
    id_contenido, id_tema, id_facultad, tipo, titulo, resumen,
    emocion_dominante, emocion_intensidad, tipo_fuente, origen_fuente, url_ver, url_descargar
) VALUES
('gp_cont_1', 'gp_deepfakes_electorales', 'GP', 'Debate', '¿Sobrevivirá la democracia a la próxima ola de deepfakes electorales generados por IA?', 'Análisis de la nueva geopolítica de la desinformación y el uso de deepfakes en procesos electorales, un tema de máxima actualidad en diciembre de 2025.', 'Miedo', 0.85, 'paper', 'paper_academico', 'https://www.foreignaffairs.com/deepfakes-2025', NULL),
('gp_cont_2', 'gp_politica_eeuu_global', 'GP', 'Analisis', '¿Y si la política de "América Primero" de 2025 desmantela las alianzas tradicionales de la OTAN y el Pacífico?', 'Estudio del impacto de la política interna de EE. UU. (e.g., elecciones 2024/2025) en el orden global y las alianzas tradicionales.', 'Preocupación', 0.70, 'paper', 'think_tank', 'https://www.brookings.edu/us-policy-2025', NULL),
('gp_cont_3', 'gp_polarizacion_genero', 'GP', 'Estudio', '¿Quién gana y quién pierde con la polarización global en torno a los derechos de género y el consenso internacional?', 'La polarización global en torno a los derechos y el consenso de género como factor de conflicto internacional y su análisis en las RR.II.', 'Conflicto', 0.65, 'paper', 'paper_academico', 'https://www.internationalorganization.org/gender-conflict', NULL),
('gp_cont_4', 'gp_negacionismo_climatico', 'GP', 'Debate', '¿Cuál es el verdadero precio de la desinformación climática cuando se financia y distribuye a través de plataformas de streaming?', 'El papel de las plataformas de streaming y redes sociales en la difusión de narrativas de negacionismo climático y su efecto en la política pública.', 'Preocupación', 0.75, 'paper', 'paper_academico', 'https://www.ssrn.com/negacionismo-streaming', NULL),
('cs_cont_1', 'cs_antropologia_inmersiva', 'CS', 'Analisis', '¿Cómo la realidad virtual y aumentada redefinirán la identidad humana y la pertenencia social en 2025?', 'Antropología del futuro: La redefinición de la humanidad por la realidad virtual, aumentada y la tecnología inmersiva.', 'Curiosidad', 0.80, 'paper', 'paper_academico', 'https://www.anthro-future.org/vr-identity', NULL),
('cs_cont_2', 'cs_confianza_medios_ia', 'CS', 'Debate', '¿Está realmente la IA destruyendo la confianza del consumidor en los medios digitales o solo acelerando su evolución?', 'El impacto social y la confianza del consumidor en los medios digitales transformados por la IA.', 'Duda', 0.60, 'paper', 'paper_academico', 'https://www.ssrn.com/ia-confianza-medios', NULL),
('cs_cont_3', 'cs_migracion_digital', 'CS', 'Estudio', '¿De qué manera las nuevas metodologías reflexivas en la investigación social están capturando la complejidad de la migración digital?', 'La migración y la globalización en la era digital: Nuevas metodologías reflexivas en la investigación social.', 'Interés', 0.70, 'paper', 'paper_academico', 'https://www.soc-migracion.org/digital', NULL),
('cs_cont_4', 'cs_ansiedad_climatica', 'CS', 'Analisis', '¿Es la ansiedad climática el nuevo tabaquismo social que la psicología y la sociología deben abordar urgentemente?', 'La ansiedad climática como fenómeno social y cultural: ¿Es el nuevo malestar de la civilización?', 'Preocupación', 0.80, 'paper', 'paper_academico', 'https://www.apa.org/ansiedad-climatica', NULL),
('ec_cont_1', 'ec_costo_cambio_climatico', 'EC', 'Analisis', '¿Cuál es el verdadero precio de la inacción climática en términos de PIB global y estabilidad financiera para 2030?', 'El verdadero costo económico global del cambio climático y la efectividad de las políticas de mitigación.', 'Preocupación', 0.90, 'paper', 'paper_academico', 'https://www.nber.org/climate-cost', NULL),
('ec_cont_2', 'ec_megafirmas_big_tech', 'EC', 'Debate', '¿Quién gana y quién pierde con el dominio de las Megafirmas en la inversión, la competencia y la política fiscal global?', 'El auge de las "Megafirmas" (Big Tech) y su impacto en la inversión, la competencia y la política fiscal.', 'Conflicto', 0.75, 'paper', 'paper_academico', 'https://www.nber.org/megafirmas', NULL),
('ec_cont_3', 'ec_cbdcs_viabilidad', 'EC', 'Estudio', '¿Debería el Banco Central Europeo acelerar la implementación de las CBDCs a pesar de las preocupaciones sobre privacidad y estabilidad?', 'La viabilidad y las implicaciones de las Monedas Digitales de Banco Central (CBDCs) en la estabilidad financiera y la privacidad.', 'Duda', 0.65, 'paper', 'paper_academico', 'https://www.repec.org/cbdc-viabilidad', NULL),
('ec_cont_4', 'ec_expiracion_fiscal', 'EC', 'Analisis', '¿Cómo afectará la expiración de los recortes fiscales de 2025 a la desigualdad económica y la política fiscal en EE. UU. y el mundo?', 'El debate sobre la expiración de los recortes fiscales de 2025 y su efecto en la política económica y la desigualdad.', 'Preocupación', 0.70, 'paper', 'paper_academico', 'https://www.ssrn.com/expiracion-fiscal', NULL),
('cn_cont_1', 'cn_geoingenieria_oceanica', 'CN', 'Debate', '¿Es la geoingeniería oceánica una solución viable o un riesgo incalculable para la crisis climática global?', 'Geoingeniería oceánica: ¿Una solución viable o un riesgo incalculable para la crisis climática?', 'Riesgo', 0.80, 'paper', 'paper_academico', 'https://www.nature.com/geoingenieria', NULL),
('cn_cont_2', 'cn_ia_descubrimiento', 'CN', 'Estudio', '¿Puede la IA acelerar el descubrimiento de nuevos materiales y medicinas a una velocidad que la ciencia tradicional no puede igualar?', 'El papel de la IA en la aceleración del descubrimiento científico (e.g., nuevos materiales, química, medicina).', 'Esperanza', 0.90, 'paper', 'paper_academico', 'https://www.science.org/ia-descubrimiento', NULL),
('cn_cont_3', 'cn_eficiencia_energetica', 'CN', 'Analisis', '¿De qué manera la investigación en eficiencia energética extrema puede asegurar la sostenibilidad del monitoreo ambiental global?', 'La investigación de bajo consumo y eficiencia energética para el monitoreo ambiental y la sostenibilidad.', 'Interés', 0.75, 'paper', 'paper_academico', 'https://www.ieee.org/eficiencia-energetica', NULL),
('cn_cont_4', 'cn_oro_invisible', 'CN', 'Debate', '¿Quién controla el "oro invisible" (elementos críticos) y cómo impacta esto en la geopolítica de la transición energética?', 'La búsqueda de "oro invisible" (elementos críticos) y su impacto en la transición energética y la geopolítica de recursos.', 'Conflicto', 0.70, 'paper', 'paper_academico', 'https://www.nature.com/oro-invisible', NULL),
('dr_cont_1', 'dr_regulacion_ia_justicia', 'DR', 'Analisis', '¿Está realmente la regulación actual de la IA garantizando la transparencia y la equidad en el sistema de justicia penal?', 'La regulación de la IA en el sistema de justicia: Desafíos para la transparencia, el acceso y la equidad.', 'Duda', 0.75, 'paper', 'paper_academico', 'https://www.ssrn.com/ia-justicia', NULL),
('dr_cont_2', 'dr_derecho_contractual_ia', 'DR', 'Debate', '¿Sobrevivirá el Derecho Contractual tradicional a la ola de automatización y la proliferación de contratos inteligentes en 2025?', 'El futuro del Derecho Contractual en 2025 ante la automatización y los contratos inteligentes.', 'Riesgo', 0.60, 'paper', 'paper_academico', 'https://www.heinonline.org/contratos-ia', NULL),
('dr_cont_3', 'dr_ciberseguridad_derecho', 'DR', 'Estudio', '¿Y si el próximo gran ciberataque a infraestructuras críticas requiere una redefinición total del Derecho del Ciberespacio?', 'La evolución de la Ciberseguridad y el Derecho del Ciberespacio frente a la desinformación y los ataques a infraestructuras críticas.', 'Miedo', 0.80, 'paper', 'paper_academico', 'https://www.ssrn.com/ciberseguridad-derecho', NULL),
('dr_cont_4', 'dr_tendencias_jurisprudenciales', 'DR', 'Analisis', '¿Cómo la polarización política está influyendo en las tendencias jurisprudenciales de las Cortes Supremas y la interpretación de la ley?', 'El análisis de las tendencias jurisprudenciales de las Cortes Supremas y su impacto en la interpretación de la ley.', 'Preocupación', 0.65, 'paper', 'paper_academico', 'https://www.heinonline.org/jurisprudencia-2025', NULL),
('in_cont_1', 'in_llms_edge_computing', 'IN', 'Estudio', '¿Puede la eficiencia en el despliegue de LLMs en edge computing democratizar el acceso a la IA avanzada?', 'La eficiencia en el despliegue de Grandes Modelos de Lenguaje (LLMs) en entornos de baja potencia y el edge computing.', 'Esperanza', 0.85, 'paper', 'paper_academico', 'https://www.ieee.org/llms-edge', NULL),
('in_cont_2', 'in_computacion_reversible', 'IN', 'Analisis', '¿Es la computación reversible el nuevo paradigma para alcanzar la eficiencia energética extrema en la próxima década?', 'La viabilidad de la computación reversible como paradigma para la eficiencia energética extrema.', 'Interés', 0.90, 'paper', 'paper_academico', 'https://www.acm.org/computacion-reversible', NULL),
('in_cont_3', 'in_ve_autonomia_extendida', 'IN', 'Estudio', '¿Qué falta para que los vehículos eléctricos de autonomía extendida y la infraestructura de carga inteligente sean la norma global?', 'El desarrollo de vehículos eléctricos de autonomía extendida y la infraestructura de carga inteligente.', 'Duda', 0.70, 'paper', 'paper_academico', 'https://www.ieee.org/ve-autonomia', NULL),
('in_cont_4', 'in_ia_sistemas_ciberfisicos', 'IN', 'Analisis', '¿De qué manera la convergencia de la IA y la ingeniería está creando sistemas ciber-físicos más resilientes y seguros?', 'La convergencia de la IA y la ingeniería para la creación de sistemas ciber-físicos resilientes.', 'Interés', 0.75, 'paper', 'paper_academico', 'https://www.acm.org/sistemas-ciberfisicos', NULL),
('ps_cont_1', 'ps_psicoterapia_ia', 'PS', 'Debate', '¿Y si la psicoterapia del futuro la imparte una IA que te conoce mejor que tú mismo, cuáles son las implicaciones éticas?', 'La psicoterapia asistida por IA: Implicaciones éticas y clínicas de una IA que conoce al paciente mejor que él mismo.', 'Riesgo', 0.80, 'paper', 'paper_academico', 'https://www.apa.org/psicoterapia-ia', NULL),
('ps_cont_2', 'ps_disparidades_salud_mental', 'PS', 'Estudio', '¿Cómo puede la psicología moderna reducir las disparidades en salud mental y promover la equidad en el acceso a la atención?', 'El papel de la psicología en la reducción de las disparidades en salud mental y la promoción de la equidad.', 'Esperanza', 0.75, 'paper', 'paper_academico', 'https://www.apa.org/equidad-salud-mental', NULL),
('ps_cont_3', 'ps_vr_juegos_terapia', 'PS', 'Analisis', '¿Está realmente la realidad virtual y los juegos de rol transformando la terapia para trastornos de personalidad y ansiedad?', 'El uso de juegos de rol y realidad virtual en la terapia para trastornos de personalidad y ansiedad.', 'Curiosidad', 0.70, 'paper', 'paper_academico', 'https://www.apa.org/vr-terapia', NULL),
('ps_cont_4', 'ps_medios_digitales_ninos', 'PS', 'Estudio', '¿Qué tipo de medios digitales y contenidos promueven un desarrollo psicológico saludable en la infancia y la adolescencia?', 'El desarrollo de medios digitales y contenidos para niños que promuevan un desarrollo psicológico saludable.', 'Interés', 0.65, 'paper', 'paper_academico', 'https://www.apa.org/medios-ninos', NULL);

-- 2.4 Inserción de Tags por Contenido
INSERT INTO contenido_tags (id_contenido, tag) VALUES
('gp_cont_1', 'deepfakes'), ('gp_cont_1', 'elecciones'), ('gp_cont_1', 'IA'), ('gp_cont_1', 'desinformación'),
('cs_cont_1', 'realidad virtual'), ('cs_cont_1', 'antropología'), ('cs_cont_1', 'identidad digital'),
('ec_cont_1', 'cambio climático'), ('ec_cont_1', 'PIB'), ('ec_cont_1', 'política fiscal'),
('cn_cont_1', 'geoingeniería'), ('cn_cont_1', 'océanos'), ('cn_cont_1', 'crisis climática'),
('dr_cont_1', 'regulación IA'), ('dr_cont_1', 'justicia penal'), ('dr_cont_1', 'equidad'),
('in_cont_1', 'LLMs'), ('in_cont_1', 'edge computing'), ('in_cont_1', 'democratización IA'),
('ps_cont_1', 'psicoterapia'), ('ps_cont_1', 'ética IA'), ('ps_cont_1', 'salud mental');

-- 2.5 Inserción de Listas Asociadas (ejemplo para el primer tema de cada facultad)
INSERT INTO tema_key_concepts (id_tema, concepto) VALUES ('gp_deepfakes_electorales', 'Guerra Híbrida'), ('gp_deepfakes_electorales', 'IA Generativa'), ('gp_deepfakes_electorales', 'Desinformación');
INSERT INTO tema_main_actors (id_tema, actor) VALUES ('gp_deepfakes_electorales', 'Estados-nación'), ('gp_deepfakes_electorales', 'Plataformas de Redes Sociales'), ('gp_deepfakes_electorales', 'Agencias de Inteligencia');
INSERT INTO tema_case_studies (id_tema, caso_estudio) VALUES ('gp_deepfakes_electorales', 'Elecciones Presidenciales 2024/2025'), ('gp_deepfakes_electorales', 'Conflictos en el Sudeste Asiático');
INSERT INTO tema_future_trends (id_tema, tendencia_futura) VALUES ('gp_deepfakes_electorales', 'Regulación de Contenido Sintético'), ('gp_deepfakes_electorales', 'Sistemas de Detección de Deepfakes');

INSERT INTO tema_key_concepts (id_tema, concepto) VALUES ('cs_antropologia_inmersiva', 'Metaverso'), ('cs_antropologia_inmersiva', 'Identidad Digital'), ('cs_antropologia_inmersiva', 'Etnografía Digital');
INSERT INTO tema_main_actors (id_tema, actor) VALUES ('cs_antropologia_inmersiva', 'Empresas de Tecnología Inmersiva'), ('cs_antropologia_inmersiva', 'Comunidades Virtuales');
INSERT INTO tema_case_studies (id_tema, caso_estudio) VALUES ('cs_antropologia_inmersiva', 'Estudios de Comunidades en VR'), ('cs_antropologia_inmersiva', 'Impacto de AR en Espacios Públicos');
INSERT INTO tema_future_trends (id_tema, tendencia_futura) VALUES ('cs_antropologia_inmersiva', 'Fronteras entre lo Real y lo Virtual'), ('cs_antropologia_inmersiva', 'Nuevas Formas de Pertenencia Social');

INSERT INTO tema_key_concepts (id_tema, concepto) VALUES ('ec_costo_cambio_climatico', 'Riesgo Sistémico'), ('ec_costo_cambio_climatico', 'Valoración de Activos Verdes'), ('ec_costo_cambio_climatico', 'Modelos Econométricos Climáticos');
INSERT INTO tema_main_actors (id_tema, actor) VALUES ('ec_costo_cambio_climatico', 'Bancos Centrales'), ('ec_costo_cambio_climatico', 'Fondo Monetario Internacional'), ('ec_costo_cambio_climatico', 'IPCC');
INSERT INTO tema_case_studies (id_tema, caso_estudio) VALUES ('ec_costo_cambio_climatico', 'Impacto de Eventos Extremos en el PIB'), ('ec_costo_cambio_climatico', 'Análisis de Bonos Verdes');
INSERT INTO tema_future_trends (id_tema, tendencia_futura) VALUES ('ec_costo_cambio_climatico', 'Contabilidad de Carbono Obligatoria'), ('ec_costo_cambio_climatico', 'Mercados de Carbono Globales');

INSERT INTO tema_key_concepts (id_tema, concepto) VALUES ('cn_geoingenieria_oceanica', 'Secuestro de Carbono'), ('cn_geoingenieria_oceanica', 'Acidificación Oceánica'), ('cn_geoingenieria_oceanica', 'Riesgo Ecológico');
INSERT INTO tema_main_actors (id_tema, actor) VALUES ('cn_geoingenieria_oceanica', 'Organizaciones Científicas (Nature/Science)'), ('cn_geoingenieria_oceanica', 'Gobiernos con Intereses Marítimos');
INSERT INTO tema_case_studies (id_tema, caso_estudio) VALUES ('cn_geoingenieria_oceanica', 'Experimentos de Fertilización con Hierro'), ('cn_geoingenieria_oceanica', 'Regulación de la ONU sobre Océanos');
INSERT INTO tema_future_trends (id_tema, tendencia_futura) VALUES ('cn_geoingenieria_oceanica', 'Desarrollo de Protocolos de Seguridad'), ('cn_geoingenieria_oceanica', 'Debate Ético y Político sobre Implementación');

INSERT INTO tema_key_concepts (id_tema, concepto) VALUES ('dr_regulacion_ia_justicia', 'Transparencia Algorítmica'), ('dr_regulacion_ia_justicia', 'Sesgo en la IA'), ('dr_regulacion_ia_justicia', 'Acceso a la Justicia');
INSERT INTO tema_main_actors (id_tema, actor) VALUES ('dr_regulacion_ia_justicia', 'Cortes Supremas'), ('dr_regulacion_ia_justicia', 'Colegios de Abogados'), ('dr_regulacion_ia_justicia', 'Comisiones de Derechos Humanos');
INSERT INTO tema_case_studies (id_tema, caso_estudio) VALUES ('dr_regulacion_ia_justicia', 'Casos de Sesgo en Sentencias Predictivas'), ('dr_regulacion_ia_justicia', 'Regulación de la IA en la UE (AI Act)');
INSERT INTO tema_future_trends (id_tema, tendencia_futura) VALUES ('dr_regulacion_ia_justicia', 'Creación de Tribunales Especializados en IA'), ('dr_regulacion_ia_justicia', 'Auditoría Algorítmica Obligatoria');

INSERT INTO tema_key_concepts (id_tema, concepto) VALUES ('in_llms_edge_computing', 'Edge AI'), ('in_llms_edge_computing', 'Eficiencia Energética'), ('in_llms_edge_computing', 'Modelos de Lenguaje Ligeros');
INSERT INTO tema_main_actors (id_tema, actor) VALUES ('in_llms_edge_computing', 'Fabricantes de Chips (NVIDIA, ARM)'), ('in_llms_edge_computing', 'Compañías de Telecomunicaciones');
INSERT INTO tema_case_studies (id_tema, caso_estudio) VALUES ('in_llms_edge_computing', 'Despliegue de IA en Dispositivos Móviles'), ('in_llms_edge_computing', 'Optimización de LLMs para IoT');
INSERT INTO tema_future_trends (id_tema, tendencia_futura) VALUES ('in_llms_edge_computing', 'IA Personalizada y Privada'), ('in_llms_edge_computing', 'Reducción de la Latencia en Aplicaciones de IA');

INSERT INTO tema_key_concepts (id_tema, concepto) VALUES ('ps_psicoterapia_ia', 'Ética en la IA'), ('ps_psicoterapia_ia', 'Vínculo Terapéutico Digital'), ('ps_psicoterapia_ia', 'Privacidad del Paciente');
INSERT INTO tema_main_actors (id_tema, actor) VALUES ('ps_psicoterapia_ia', 'Asociación Americana de Psicología (APA)'), ('ps_psicoterapia_ia', 'Desarrolladores de Apps de Salud Mental');
INSERT INTO tema_case_studies (id_tema, caso_estudio) VALUES ('ps_psicoterapia_ia', 'Estudios Clínicos de Terapia Cognitivo-Conductual con IA'), ('ps_psicoterapia_ia', 'Regulación de Terapeutas Virtuales');
INSERT INTO tema_future_trends (id_tema, tendencia_futura) VALUES ('ps_psicoterapia_ia', 'IA como Herramienta de Diagnóstico Avanzado'), ('ps_psicoterapia_ia', 'Integración de VR en la Psicoterapia');
