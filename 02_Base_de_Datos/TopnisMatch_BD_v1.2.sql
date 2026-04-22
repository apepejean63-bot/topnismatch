-- =============================================================================
-- TOPNISMATCH - SCRIPT DE BASE DE DATOS ORACLE 19c
-- =============================================================================
-- Proyecto     : TopnisMatch - App de Citas para Relaciones Serias
-- Version      : v1.2
-- Fecha        : Abril 2026
-- Autor        : Junior Altidor
-- Carrera      : Ingenieria Informatica
-- Basado en    : SRS v1.5 (version final definitiva)
-- Base de Datos: Oracle Database 19c
-- Tablas       : 14 tablas
-- =============================================================================
-- INSTRUCCIONES DE EJECUCION:
--   1. Abrir Oracle SQL Developer
--   2. Conectarse como usuario DBA o con privilegios CREATE TABLE
--   3. Ejecutar este script completo (F5 o Run Script)
--   4. Verificar que no haya errores en el log
-- =============================================================================

-- Limpiar objetos existentes (ejecutar si es reinstalacion)
-- EXEC drop_all_topnis; -- Ver procedimiento al final del script

SET ECHO ON
SET FEEDBACK ON
SET LINESIZE 200
SET PAGESIZE 50

PROMPT ================================================================
PROMPT  TopnisMatch v1.2 - Iniciando creacion de Base de Datos
PROMPT  Tablas: 14 | Secuencias: 14 | Indices: 28 | Packages: 1
PROMPT ================================================================

-- =============================================================================
-- SECUENCIAS (AUTO-INCREMENT para Oracle 19c)
-- =============================================================================

PROMPT --> Creando secuencias...

CREATE SEQUENCE seq_usuario_id
    START WITH 1 INCREMENT BY 1
    NOCACHE NOCYCLE NOORDER;

CREATE SEQUENCE seq_foto_id
    START WITH 1 INCREMENT BY 1
    NOCACHE NOCYCLE NOORDER;

CREATE SEQUENCE seq_perfil_id
    START WITH 1 INCREMENT BY 1
    NOCACHE NOCYCLE NOORDER;

CREATE SEQUENCE seq_like_id
    START WITH 1 INCREMENT BY 1
    NOCACHE NOCYCLE NOORDER;

CREATE SEQUENCE seq_match_id
    START WITH 1 INCREMENT BY 1
    NOCACHE NOCYCLE NOORDER;

CREATE SEQUENCE seq_mensaje_id
    START WITH 1 INCREMENT BY 1
    NOCACHE NOCYCLE NOORDER;

CREATE SEQUENCE seq_suscripcion_id
    START WITH 1 INCREMENT BY 1
    NOCACHE NOCYCLE NOORDER;

CREATE SEQUENCE seq_bloqueo_id
    START WITH 1 INCREMENT BY 1
    NOCACHE NOCYCLE NOORDER;

CREATE SEQUENCE seq_reporte_id
    START WITH 1 INCREMENT BY 1
    NOCACHE NOCYCLE NOORDER;

CREATE SEQUENCE seq_blacklist_id
    START WITH 1 INCREMENT BY 1
    NOCACHE NOCYCLE NOORDER;

CREATE SEQUENCE seq_reset_id
    START WITH 1 INCREMENT BY 1
    NOCACHE NOCYCLE NOORDER;

CREATE SEQUENCE seq_fcm_id
    START WITH 1 INCREMENT BY 1
    NOCACHE NOCYCLE NOORDER;

CREATE SEQUENCE seq_notif_pref_id
    START WITH 1 INCREMENT BY 1
    NOCACHE NOCYCLE NOORDER;

CREATE SEQUENCE seq_boost_id
    START WITH 1 INCREMENT BY 1
    NOCACHE NOCYCLE NOORDER;

PROMPT --> Secuencias creadas: 14

-- =============================================================================
-- TABLA 1: USUARIO
-- Descripcion: Tabla principal del sistema. Almacena todos los usuarios
--              registrados con su informacion de autenticacion y estado.
-- Ref SRS    : RF-01 Registro, RF-02 Login, RF-06 Eliminacion
-- =============================================================================

PROMPT --> Creando tabla USUARIO...

CREATE TABLE USUARIO (
    usuario_id          NUMBER          NOT NULL,
    nombre              VARCHAR2(100)   NOT NULL,
    email               VARCHAR2(150)   NOT NULL,
    password_hash       VARCHAR2(255)   NOT NULL,
    fecha_nacimiento    DATE            NOT NULL,
    genero              VARCHAR2(20)    NOT NULL,
    rol                 VARCHAR2(10)    DEFAULT 'USER'      NOT NULL,
    activo              NUMBER(1)       DEFAULT 1           NOT NULL,
    email_verificado    NUMBER(1)       DEFAULT 0           NOT NULL,
    fecha_registro      TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    fecha_actualizacion TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    -- CONSTRAINTS
    CONSTRAINT pk_usuario
        PRIMARY KEY (usuario_id),
    CONSTRAINT uq_usuario_email
        UNIQUE (email),
    CONSTRAINT ck_usuario_rol
        CHECK (rol IN ('USER', 'PREMIUM', 'ADMIN')),
    CONSTRAINT ck_usuario_activo
        CHECK (activo IN (0, 1)),
    CONSTRAINT ck_usuario_email_verificado
        CHECK (email_verificado IN (0, 1)),
    CONSTRAINT ck_usuario_genero
        CHECK (genero IN ('MASCULINO', 'FEMENINO', 'NO_BINARIO', 'PREFIERO_NO_DECIR')),
    -- Validacion de mayoria de edad (18+) en trigger trg_usuario_id (ORA-02436: SYSDATE invalido en CHECK)
    CONSTRAINT ck_usuario_nombre
        CHECK (LENGTH(nombre) >= 2)
);

-- Trigger para ID autogenerado
CREATE OR REPLACE TRIGGER trg_usuario_id
    BEFORE INSERT ON USUARIO
    FOR EACH ROW
DECLARE
    v_edad NUMBER;
BEGIN
    IF :NEW.usuario_id IS NULL THEN
        :NEW.usuario_id := seq_usuario_id.NEXTVAL;
    END IF;
    :NEW.fecha_actualizacion := SYSTIMESTAMP;
    -- Validacion de mayoria de edad 18+ (RF-01, SRS v1.5)
    -- Movida aqui desde CHECK constraint (ORA-02436: SYSDATE no permitido en DDL CHECK)
    v_edad := TRUNC(MONTHS_BETWEEN(SYSDATE, :NEW.fecha_nacimiento) / 12);
    IF v_edad < 18 THEN
        RAISE_APPLICATION_ERROR(-20010,
            'Registro rechazado: el usuario debe ser mayor de 18 anos. Edad: ' || v_edad || ' anos.');
    END IF;
END;
/

-- Trigger para actualizar fecha_actualizacion en UPDATE
CREATE OR REPLACE TRIGGER trg_usuario_update
    BEFORE UPDATE ON USUARIO
    FOR EACH ROW
BEGIN
    :NEW.fecha_actualizacion := SYSTIMESTAMP;
END;
/

-- Comentarios de tabla y columnas
COMMENT ON TABLE USUARIO IS 'Tabla principal de usuarios del sistema TopnisMatch';
COMMENT ON COLUMN USUARIO.usuario_id IS 'Identificador unico autogenerado del usuario';
COMMENT ON COLUMN USUARIO.email IS 'Correo electronico unico - se anonimiza al eliminar cuenta (RF-06)';
COMMENT ON COLUMN USUARIO.rol IS 'Rol del usuario: USER=estandar, PREMIUM=suscrito, ADMIN=administrador';
COMMENT ON COLUMN USUARIO.activo IS '1=cuenta activa, 0=cuenta desactivada o eliminada';
COMMENT ON COLUMN USUARIO.email_verificado IS '0=pendiente verificacion, 1=email verificado (RF-05)';
COMMENT ON COLUMN USUARIO.password_hash IS 'Hash BCrypt con factor de costo 10 (RNF-06)';

PROMPT --> Tabla USUARIO creada

-- =============================================================================
-- TABLA 2: FOTO
-- Descripcion: Fotos de perfil de los usuarios. Maximo 6 fotos por usuario.
--              Las URLs apuntan a Firebase Storage o Amazon S3.
-- Ref SRS    : RF-08 Gestion de Fotos
-- NOTA       : Se crea antes que PERFIL por la FK foto_principal_id
-- =============================================================================

PROMPT --> Creando tabla FOTO...

CREATE TABLE FOTO (
    foto_id         NUMBER          NOT NULL,
    usuario_id      NUMBER          NOT NULL,
    url             VARCHAR2(500)   NOT NULL,
    orden           NUMBER(1)       NOT NULL,
    fecha_subida    TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    -- CONSTRAINTS
    CONSTRAINT pk_foto
        PRIMARY KEY (foto_id),
    CONSTRAINT fk_foto_usuario
        FOREIGN KEY (usuario_id) REFERENCES USUARIO(usuario_id)
        ON DELETE CASCADE,
    CONSTRAINT ck_foto_orden
        CHECK (orden BETWEEN 1 AND 6),
    CONSTRAINT uq_foto_usuario_orden
        UNIQUE (usuario_id, orden)
);

CREATE OR REPLACE TRIGGER trg_foto_id
    BEFORE INSERT ON FOTO
    FOR EACH ROW
BEGIN
    IF :NEW.foto_id IS NULL THEN
        :NEW.foto_id := seq_foto_id.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE FOTO IS 'Fotos de perfil - max 6 por usuario, orden 1 es la principal (RF-08)';
COMMENT ON COLUMN FOTO.url IS 'URL del archivo en Firebase Storage o Amazon S3 (no se almacena en BD)';
COMMENT ON COLUMN FOTO.orden IS 'Posicion de la foto: 1=principal (obligatoria), 2-6=adicionales';

PROMPT --> Tabla FOTO creada

-- =============================================================================
-- TABLA 3: PERFIL
-- Descripcion: Informacion publica del perfil del usuario con preferencias
--              de busqueda para el algoritmo de compatibilidad.
-- Ref SRS    : RF-07 Edicion de Perfil, RF-09 Compatibilidad
-- =============================================================================

PROMPT --> Creando tabla PERFIL...

CREATE TABLE PERFIL (
    perfil_id               NUMBER          NOT NULL,
    usuario_id              NUMBER          NOT NULL,
    bio                     VARCHAR2(500)   NULL,
    ciudad                  VARCHAR2(100)   NULL,
    objetivo                VARCHAR2(30)    DEFAULT 'RELACION_SERIA' NOT NULL,
    intereses               VARCHAR2(1000)  NULL,
    edad_min_buscada        NUMBER(3)       DEFAULT 18  NOT NULL,
    edad_max_buscada        NUMBER(3)       DEFAULT 99  NOT NULL,
    distancia_max_km        NUMBER(4)       DEFAULT 50  NOT NULL,
    genero_buscado          VARCHAR2(20)    NULL,
    foto_principal_id       NUMBER          NULL,
    fecha_actualizacion     TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    -- CONSTRAINTS
    CONSTRAINT pk_perfil
        PRIMARY KEY (perfil_id),
    CONSTRAINT fk_perfil_usuario
        FOREIGN KEY (usuario_id) REFERENCES USUARIO(usuario_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_perfil_foto_principal
        FOREIGN KEY (foto_principal_id) REFERENCES FOTO(foto_id)
        ON DELETE SET NULL,
    CONSTRAINT uq_perfil_usuario
        UNIQUE (usuario_id),
    CONSTRAINT ck_perfil_objetivo
        CHECK (objetivo = 'RELACION_SERIA'),
    CONSTRAINT ck_perfil_edad_min
        CHECK (edad_min_buscada >= 18),
    CONSTRAINT ck_perfil_edad_max
        CHECK (edad_max_buscada <= 99),
    CONSTRAINT ck_perfil_edad_rango
        CHECK (edad_min_buscada <= edad_max_buscada),
    CONSTRAINT ck_perfil_distancia
        CHECK (distancia_max_km BETWEEN 1 AND 500),
    CONSTRAINT ck_perfil_bio
        CHECK (LENGTH(bio) <= 500)
);

CREATE OR REPLACE TRIGGER trg_perfil_id
    BEFORE INSERT ON PERFIL
    FOR EACH ROW
BEGIN
    IF :NEW.perfil_id IS NULL THEN
        :NEW.perfil_id := seq_perfil_id.NEXTVAL;
    END IF;
    :NEW.fecha_actualizacion := SYSTIMESTAMP;
END;
/

CREATE OR REPLACE TRIGGER trg_perfil_update
    BEFORE UPDATE ON PERFIL
    FOR EACH ROW
BEGIN
    :NEW.fecha_actualizacion := SYSTIMESTAMP;
END;
/

COMMENT ON TABLE PERFIL IS 'Perfil publico del usuario con preferencias de busqueda (RF-07, RF-09)';
COMMENT ON COLUMN PERFIL.objetivo IS 'Solo RELACION_SERIA en v1.0 - campo preparado para futuras versiones';
COMMENT ON COLUMN PERFIL.intereses IS 'Etiquetas separadas por coma - usado en formula de compatibilidad RF-09';
COMMENT ON COLUMN PERFIL.foto_principal_id IS 'FK a FOTO.foto_id - foto que aparece en la tarjeta de swipe';
COMMENT ON COLUMN PERFIL.edad_min_buscada IS 'Edad minima del usuario buscado - minimo 18 anos';
COMMENT ON COLUMN PERFIL.genero_buscado IS 'NULL significa buscar todos los generos';

PROMPT --> Tabla PERFIL creada

-- =============================================================================
-- TABLA 4: LIKE_ACCION
-- Descripcion: Registra cada accion de swipe entre usuarios.
--              La restriccion UNIQUE garantiza que cada par tiene exactamente
--              una decision. La decision es permanente (RF-11).
-- Ref SRS    : RF-11 Like/Dislike, RF-12 Deshacer, RF-16 Super Like
-- =============================================================================

PROMPT --> Creando tabla LIKE_ACCION...

CREATE TABLE LIKE_ACCION (
    like_id             NUMBER          NOT NULL,
    usuario_origen      NUMBER          NOT NULL,
    usuario_destino     NUMBER          NOT NULL,
    tipo                VARCHAR2(10)    NOT NULL,
    fecha               TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    -- CONSTRAINTS
    CONSTRAINT pk_like_accion
        PRIMARY KEY (like_id),
    CONSTRAINT fk_like_origen
        FOREIGN KEY (usuario_origen) REFERENCES USUARIO(usuario_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_like_destino
        FOREIGN KEY (usuario_destino) REFERENCES USUARIO(usuario_id)
        ON DELETE CASCADE,
    CONSTRAINT uq_like_par
        UNIQUE (usuario_origen, usuario_destino),
    CONSTRAINT ck_like_tipo
        CHECK (tipo IN ('LIKE', 'DISLIKE', 'SUPERLIKE')),
    CONSTRAINT ck_like_no_autoswipe
        CHECK (usuario_origen <> usuario_destino)
);

CREATE OR REPLACE TRIGGER trg_like_id
    BEFORE INSERT ON LIKE_ACCION
    FOR EACH ROW
BEGIN
    IF :NEW.like_id IS NULL THEN
        :NEW.like_id := seq_like_id.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE LIKE_ACCION IS 'Acciones de swipe entre usuarios - UNIQUE garantiza decision permanente (RF-11)';
COMMENT ON COLUMN LIKE_ACCION.tipo IS 'LIKE=deslizar derecha, DISLIKE=deslizar izquierda, SUPERLIKE=accion especial (RF-16)';
COMMENT ON COLUMN LIKE_ACCION.usuario_origen IS 'Usuario que realiza la accion';
COMMENT ON COLUMN LIKE_ACCION.usuario_destino IS 'Usuario que recibe la accion';

PROMPT --> Tabla LIKE_ACCION creada

-- =============================================================================
-- TABLA 5: MATCH
-- Descripcion: Registro de matches mutuos entre usuarios.
--              activo=0 excluye ambos usuarios de las sugerencias del otro,
--              igual que un BLOQUEO pero sin crear registro en BLOQUEO (RF-17).
-- Ref SRS    : RF-13 Deteccion Match, RF-14 Lista, RF-17 Eliminacion
-- =============================================================================

PROMPT --> Creando tabla MATCH...

CREATE TABLE MATCH_TOPNIS (
    match_id        NUMBER          NOT NULL,
    usuario1_id     NUMBER          NOT NULL,
    usuario2_id     NUMBER          NOT NULL,
    compatibilidad  NUMBER(5,2)     NOT NULL,
    activo          NUMBER(1)       DEFAULT 1   NOT NULL,
    fecha_match     TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    -- CONSTRAINTS
    CONSTRAINT pk_match
        PRIMARY KEY (match_id),
    CONSTRAINT fk_match_usuario1
        FOREIGN KEY (usuario1_id) REFERENCES USUARIO(usuario_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_match_usuario2
        FOREIGN KEY (usuario2_id) REFERENCES USUARIO(usuario_id)
        ON DELETE CASCADE,
    CONSTRAINT uq_match_par
        UNIQUE (usuario1_id, usuario2_id),
    CONSTRAINT ck_match_activo
        CHECK (activo IN (0, 1)),
    CONSTRAINT ck_match_compatibilidad
        CHECK (compatibilidad BETWEEN 0 AND 100),
    CONSTRAINT ck_match_no_automatch
        CHECK (usuario1_id <> usuario2_id)
);
-- NOTA: Tabla nombrada MATCH_TOPNIS porque MATCH es palabra reservada en Oracle

CREATE OR REPLACE TRIGGER trg_match_id
    BEFORE INSERT ON MATCH_TOPNIS
    FOR EACH ROW
BEGIN
    IF :NEW.match_id IS NULL THEN
        :NEW.match_id := seq_match_id.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE MATCH_TOPNIS IS 'Matches mutuos entre usuarios - MATCH es palabra reservada en Oracle (RF-13)';
COMMENT ON COLUMN MATCH_TOPNIS.activo IS '1=activo, 0=eliminado. activo=0 excluye de sugerencias igual que BLOQUEO (RF-17)';
COMMENT ON COLUMN MATCH_TOPNIS.compatibilidad IS 'Porcentaje calculado con formula RF-09: intereses+objetivo+edad';

PROMPT --> Tabla MATCH_TOPNIS creada

-- =============================================================================
-- TABLA 6: MENSAJE
-- Descripcion: Mensajes del chat entre usuarios con match activo.
--              Estados: ENVIADO -> ENTREGADO -> LEIDO
--              El estado LEIDO se actualiza via evento WebSocket STOMP (RF-18).
-- Ref SRS    : RF-18 Chat WebSocket, RF-19 Indicador escritura
-- =============================================================================

PROMPT --> Creando tabla MENSAJE...

CREATE TABLE MENSAJE (
    mensaje_id      NUMBER          NOT NULL,
    match_id        NUMBER          NOT NULL,
    emisor_id       NUMBER          NOT NULL,
    contenido       VARCHAR2(1000)  NOT NULL,
    estado          VARCHAR2(10)    DEFAULT 'ENVIADO'  NOT NULL,
    fecha_envio     TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    fecha_leido     TIMESTAMP       NULL,
    -- CONSTRAINTS
    CONSTRAINT pk_mensaje
        PRIMARY KEY (mensaje_id),
    CONSTRAINT fk_mensaje_match
        FOREIGN KEY (match_id) REFERENCES MATCH_TOPNIS(match_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_mensaje_emisor
        FOREIGN KEY (emisor_id) REFERENCES USUARIO(usuario_id)
        ON DELETE CASCADE,
    CONSTRAINT ck_mensaje_estado
        CHECK (estado IN ('ENVIADO', 'ENTREGADO', 'LEIDO')),
    CONSTRAINT ck_mensaje_contenido
        CHECK (LENGTH(contenido) BETWEEN 1 AND 1000)
);

CREATE OR REPLACE TRIGGER trg_mensaje_id
    BEFORE INSERT ON MENSAJE
    FOR EACH ROW
BEGIN
    IF :NEW.mensaje_id IS NULL THEN
        :NEW.mensaje_id := seq_mensaje_id.NEXTVAL;
    END IF;
END;
/

-- Trigger para registrar fecha_leido automaticamente
CREATE OR REPLACE TRIGGER trg_mensaje_leido
    BEFORE UPDATE ON MENSAJE
    FOR EACH ROW
BEGIN
    IF :NEW.estado = 'LEIDO' AND :OLD.estado != 'LEIDO' THEN
        :NEW.fecha_leido := SYSTIMESTAMP;
    END IF;
END;
/

COMMENT ON TABLE MENSAJE IS 'Mensajes del chat WebSocket STOMP entre usuarios con match activo (RF-18)';
COMMENT ON COLUMN MENSAJE.estado IS 'ENVIADO=persistido en BD, ENTREGADO=receptor conectado, LEIDO=receptor abrio chat';
COMMENT ON COLUMN MENSAJE.fecha_leido IS 'Timestamp cuando el estado cambio a LEIDO via evento STOMP';

PROMPT --> Tabla MENSAJE creada

-- =============================================================================
-- TABLA 7: SUSCRIPCION
-- Descripcion: Planes de suscripcion de los usuarios.
--              Todo usuario tiene registro desde el registro (plan=GRATUITO).
--              Regla de negocio: solo un registro con activo=1 por usuario.
-- Ref SRS    : RF-22 Planes, RF-23 Pagos
-- =============================================================================

PROMPT --> Creando tabla SUSCRIPCION...

CREATE TABLE SUSCRIPCION (
    suscripcion_id      NUMBER          NOT NULL,
    usuario_id          NUMBER          NOT NULL,
    plan                VARCHAR2(20)    NOT NULL,
    fecha_inicio        TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    fecha_fin           TIMESTAMP       NULL,
    activo              NUMBER(1)       DEFAULT 1   NOT NULL,
    recibo_store        VARCHAR2(500)   NULL,
    fecha_registro      TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    -- CONSTRAINTS
    CONSTRAINT pk_suscripcion
        PRIMARY KEY (suscripcion_id),
    CONSTRAINT fk_suscripcion_usuario
        FOREIGN KEY (usuario_id) REFERENCES USUARIO(usuario_id)
        ON DELETE CASCADE,
    CONSTRAINT ck_suscripcion_plan
        CHECK (plan IN ('GRATUITO', 'PREMIUM_MENSUAL', 'PREMIUM_ANUAL')),
    CONSTRAINT ck_suscripcion_activo
        CHECK (activo IN (0, 1))
);

CREATE OR REPLACE TRIGGER trg_suscripcion_id
    BEFORE INSERT ON SUSCRIPCION
    FOR EACH ROW
BEGIN
    IF :NEW.suscripcion_id IS NULL THEN
        :NEW.suscripcion_id := seq_suscripcion_id.NEXTVAL;
    END IF;
END;
/

-- Package para evitar ORA-04091 (mutating table) en validacion de suscripcion unica
-- Solucion: Package de estado + Trigger ROW + Trigger STATEMENT
CREATE OR REPLACE PACKAGE pkg_suscripcion_ctrl AS
    TYPE t_usr_tab IS TABLE OF SUSCRIPCION.usuario_id%TYPE INDEX BY PLS_INTEGER;
    g_usuarios_afectados t_usr_tab;
    g_idx                PLS_INTEGER := 0;
    PROCEDURE reset_control;
END pkg_suscripcion_ctrl;
/

CREATE OR REPLACE PACKAGE BODY pkg_suscripcion_ctrl AS
    PROCEDURE reset_control IS
    BEGIN
        g_usuarios_afectados.DELETE;
        g_idx := 0;
    END reset_control;
END pkg_suscripcion_ctrl;
/

-- Trigger ROW: solo registra el usuario_id (NO consulta la tabla - evita ORA-04091)
CREATE OR REPLACE TRIGGER trg_suscripcion_row
    BEFORE INSERT OR UPDATE ON SUSCRIPCION
    FOR EACH ROW
BEGIN
    IF :NEW.activo = 1 THEN
        pkg_suscripcion_ctrl.g_idx := pkg_suscripcion_ctrl.g_idx + 1;
        pkg_suscripcion_ctrl.g_usuarios_afectados(pkg_suscripcion_ctrl.g_idx) := :NEW.usuario_id;
    END IF;
END;
/

-- Trigger STATEMENT: valida unicidad DESPUES del INSERT/UPDATE completo
-- Ya no hay riesgo ORA-04091 porque es nivel STATEMENT, no FOR EACH ROW
CREATE OR REPLACE TRIGGER trg_suscripcion_unica
    AFTER INSERT OR UPDATE ON SUSCRIPCION
DECLARE
    v_count  NUMBER;
    v_usr_id SUSCRIPCION.usuario_id%TYPE;
BEGIN
    FOR i IN 1 .. pkg_suscripcion_ctrl.g_idx LOOP
        v_usr_id := pkg_suscripcion_ctrl.g_usuarios_afectados(i);
        SELECT COUNT(*) INTO v_count
        FROM SUSCRIPCION
        WHERE usuario_id = v_usr_id AND activo = 1;
        -- Si hay mas de 1 activa, desactivar la mas antigua automaticamente
        IF v_count > 1 THEN
            UPDATE SUSCRIPCION
            SET activo = 0
            WHERE usuario_id = v_usr_id
              AND activo = 1
              AND suscripcion_id = (
                  SELECT MIN(suscripcion_id)
                  FROM SUSCRIPCION
                  WHERE usuario_id = v_usr_id AND activo = 1
              );
        END IF;
    END LOOP;
    pkg_suscripcion_ctrl.reset_control();
END;
/

COMMENT ON TABLE SUSCRIPCION IS 'Planes de suscripcion - todo usuario tiene registro desde registro (RF-22)';
COMMENT ON COLUMN SUSCRIPCION.plan IS 'GRATUITO=plan base, PREMIUM_MENSUAL=+30dias, PREMIUM_ANUAL=+365dias';
COMMENT ON COLUMN SUSCRIPCION.recibo_store IS 'ID del recibo de Google Play o App Store verificado (RF-23)';
COMMENT ON COLUMN SUSCRIPCION.activo IS 'Solo un registro activo=1 por usuario garantizado por trigger';

PROMPT --> Tabla SUSCRIPCION creada

-- =============================================================================
-- TABLA 8: BLOQUEO
-- Descripcion: Registra bloqueos entre usuarios desde el chat.
--              Un bloqueo elimina el match activo y excluye mutuamente
--              de las sugerencias. El bloqueado no recibe notificacion (RF-20).
-- Ref SRS    : RF-20 Bloqueo desde Chat
-- =============================================================================

PROMPT --> Creando tabla BLOQUEO...

CREATE TABLE BLOQUEO (
    bloqueo_id          NUMBER      NOT NULL,
    usuario_bloqueador  NUMBER      NOT NULL,
    usuario_bloqueado   NUMBER      NOT NULL,
    fecha_bloqueo       TIMESTAMP   DEFAULT SYSTIMESTAMP NOT NULL,
    -- CONSTRAINTS
    CONSTRAINT pk_bloqueo
        PRIMARY KEY (bloqueo_id),
    CONSTRAINT fk_bloqueo_bloqueador
        FOREIGN KEY (usuario_bloqueador) REFERENCES USUARIO(usuario_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_bloqueo_bloqueado
        FOREIGN KEY (usuario_bloqueado) REFERENCES USUARIO(usuario_id)
        ON DELETE CASCADE,
    CONSTRAINT uq_bloqueo_par
        UNIQUE (usuario_bloqueador, usuario_bloqueado),
    CONSTRAINT ck_bloqueo_no_autoblock
        CHECK (usuario_bloqueador <> usuario_bloqueado)
);

CREATE OR REPLACE TRIGGER trg_bloqueo_id
    BEFORE INSERT ON BLOQUEO
    FOR EACH ROW
BEGIN
    IF :NEW.bloqueo_id IS NULL THEN
        :NEW.bloqueo_id := seq_bloqueo_id.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE BLOQUEO IS 'Bloqueos entre usuarios - excluye mutuamente de sugerencias (RF-20)';
COMMENT ON COLUMN BLOQUEO.usuario_bloqueador IS 'Usuario que realiza el bloqueo';
COMMENT ON COLUMN BLOQUEO.usuario_bloqueado IS 'Usuario bloqueado - no recibe notificacion del bloqueo';

PROMPT --> Tabla BLOQUEO creada

-- =============================================================================
-- TABLA 9: REPORTE
-- Descripcion: Reportes de usuarios por comportamiento inadecuado.
--              El admin revisa y toma accion manual (no bloqueo automatico).
-- Ref SRS    : RF-21 Reporte, RF-29 Gestion Admin
-- =============================================================================

PROMPT --> Creando tabla REPORTE...

CREATE TABLE REPORTE (
    reporte_id              NUMBER          NOT NULL,
    usuario_denunciante     NUMBER          NOT NULL,
    usuario_denunciado      NUMBER          NOT NULL,
    categoria               VARCHAR2(30)    NOT NULL,
    descripcion             VARCHAR2(300)   NULL,
    estado                  VARCHAR2(15)    DEFAULT 'PENDIENTE' NOT NULL,
    nota_admin              VARCHAR2(500)   NULL,
    fecha_reporte           TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    fecha_resolucion        TIMESTAMP       NULL,
    admin_resolutor_id      NUMBER          NULL,
    -- CONSTRAINTS
    CONSTRAINT pk_reporte
        PRIMARY KEY (reporte_id),
    CONSTRAINT fk_reporte_denunciante
        FOREIGN KEY (usuario_denunciante) REFERENCES USUARIO(usuario_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_reporte_denunciado
        FOREIGN KEY (usuario_denunciado) REFERENCES USUARIO(usuario_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_reporte_admin
        FOREIGN KEY (admin_resolutor_id) REFERENCES USUARIO(usuario_id)
        ON DELETE SET NULL,
    CONSTRAINT ck_reporte_categoria
        CHECK (categoria IN ('SPAM', 'ACOSO', 'PERFIL_FALSO', 'CONTENIDO_INAPROPIADO', 'OTRO')),
    CONSTRAINT ck_reporte_estado
        CHECK (estado IN ('PENDIENTE', 'EN_REVISION', 'RESUELTO')),
    CONSTRAINT ck_reporte_descripcion
        CHECK (LENGTH(descripcion) <= 300),
    CONSTRAINT ck_reporte_no_autoreporte
        CHECK (usuario_denunciante <> usuario_denunciado)
);

CREATE OR REPLACE TRIGGER trg_reporte_id
    BEFORE INSERT ON REPORTE
    FOR EACH ROW
BEGIN
    IF :NEW.reporte_id IS NULL THEN
        :NEW.reporte_id := seq_reporte_id.NEXTVAL;
    END IF;
END;
/

-- Trigger: registra fecha_resolucion al resolver
CREATE OR REPLACE TRIGGER trg_reporte_resolucion
    BEFORE UPDATE ON REPORTE
    FOR EACH ROW
BEGIN
    IF :NEW.estado = 'RESUELTO' AND :OLD.estado != 'RESUELTO' THEN
        :NEW.fecha_resolucion := SYSTIMESTAMP;
    END IF;
END;
/

COMMENT ON TABLE REPORTE IS 'Reportes de usuarios - revision manual por admin, sin bloqueo automatico (RF-21, RF-29)';
COMMENT ON COLUMN REPORTE.categoria IS 'SPAM|ACOSO|PERFIL_FALSO|CONTENIDO_INAPROPIADO|OTRO';
COMMENT ON COLUMN REPORTE.admin_resolutor_id IS 'FK al admin que resolvio el reporte - para auditoria';

PROMPT --> Tabla REPORTE creada

-- =============================================================================
-- TABLA 10: JWT_BLACKLIST
-- Descripcion: Lista negra de tokens JWT revocados (logout).
--              El token permanece hasta su expiracion natural.
--              Se invalida tambien al cambiar de plan (RF-02/RF-23).
-- Ref SRS    : RF-03 Logout, RF-02 JWT Refresh, RNF-08
-- =============================================================================

PROMPT --> Creando tabla JWT_BLACKLIST...

CREATE TABLE JWT_BLACKLIST (
    blacklist_id        NUMBER          NOT NULL,
    token_jti           VARCHAR2(255)   NOT NULL,
    usuario_id          NUMBER          NOT NULL,
    fecha_revocacion    TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    fecha_expiracion    TIMESTAMP       NOT NULL,
    -- CONSTRAINTS
    CONSTRAINT pk_jwt_blacklist
        PRIMARY KEY (blacklist_id),
    CONSTRAINT uq_jwt_token_jti
        UNIQUE (token_jti),
    CONSTRAINT fk_jwt_usuario
        FOREIGN KEY (usuario_id) REFERENCES USUARIO(usuario_id)
        ON DELETE CASCADE
);

CREATE OR REPLACE TRIGGER trg_blacklist_id
    BEFORE INSERT ON JWT_BLACKLIST
    FOR EACH ROW
BEGIN
    IF :NEW.blacklist_id IS NULL THEN
        :NEW.blacklist_id := seq_blacklist_id.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE JWT_BLACKLIST IS 'Tokens JWT revocados - logout y cambio de plan (RF-03, RF-02, RNF-08)';
COMMENT ON COLUMN JWT_BLACKLIST.token_jti IS 'JWT ID claim (jti) - identificador unico del token';
COMMENT ON COLUMN JWT_BLACKLIST.fecha_expiracion IS 'Para limpieza automatica de tokens expirados - job de mantenimiento';

PROMPT --> Tabla JWT_BLACKLIST creada

-- =============================================================================
-- TABLA 11: RESET_TOKEN
-- Descripcion: Tokens de recuperacion de contrasena.
--              Cada token es de un solo uso y expira en 1 hora (RF-04).
-- Ref SRS    : RF-04 Recuperacion de Contrasena
-- =============================================================================

PROMPT --> Creando tabla RESET_TOKEN...

CREATE TABLE RESET_TOKEN (
    reset_id            NUMBER          NOT NULL,
    usuario_id          NUMBER          NOT NULL,
    token               VARCHAR2(255)   NOT NULL,
    usado               NUMBER(1)       DEFAULT 0   NOT NULL,
    fecha_creacion      TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    fecha_expiracion    TIMESTAMP       NOT NULL,
    -- CONSTRAINTS
    CONSTRAINT pk_reset_token
        PRIMARY KEY (reset_id),
    CONSTRAINT uq_reset_token
        UNIQUE (token),
    CONSTRAINT fk_reset_usuario
        FOREIGN KEY (usuario_id) REFERENCES USUARIO(usuario_id)
        ON DELETE CASCADE,
    CONSTRAINT ck_reset_usado
        CHECK (usado IN (0, 1))
);

CREATE OR REPLACE TRIGGER trg_reset_id
    BEFORE INSERT ON RESET_TOKEN
    FOR EACH ROW
BEGIN
    IF :NEW.reset_id IS NULL THEN
        :NEW.reset_id := seq_reset_id.NEXTVAL;
    END IF;
    -- Expiracion automatica en 1 hora (RF-04)
    IF :NEW.fecha_expiracion IS NULL THEN
        :NEW.fecha_expiracion := SYSTIMESTAMP + INTERVAL '1' HOUR;
    END IF;
END;
/

COMMENT ON TABLE RESET_TOKEN IS 'Tokens de recuperacion de contrasena - un solo uso, expira en 1 hora (RF-04)';
COMMENT ON COLUMN RESET_TOKEN.usado IS '0=disponible, 1=ya utilizado - el token queda invalidado tras su uso';
COMMENT ON COLUMN RESET_TOKEN.fecha_expiracion IS 'fecha_creacion + 1 hora - calculado automaticamente por trigger';

PROMPT --> Tabla RESET_TOKEN creada

-- =============================================================================
-- TABLA 12: FCM_TOKEN
-- Descripcion: Tokens de dispositivo para notificaciones push via FCM.
--              Un usuario puede tener multiples dispositivos registrados.
-- Ref SRS    : RF-25 Notificaciones Push FCM
-- =============================================================================

PROMPT --> Creando tabla FCM_TOKEN...

CREATE TABLE FCM_TOKEN (
    fcm_id          NUMBER          NOT NULL,
    usuario_id      NUMBER          NOT NULL,
    token_fcm       VARCHAR2(500)   NOT NULL,
    plataforma      VARCHAR2(10)    NOT NULL,
    activo          NUMBER(1)       DEFAULT 1   NOT NULL,
    fecha_registro  TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    -- CONSTRAINTS
    CONSTRAINT pk_fcm_token
        PRIMARY KEY (fcm_id),
    CONSTRAINT uq_fcm_token
        UNIQUE (token_fcm),
    CONSTRAINT fk_fcm_usuario
        FOREIGN KEY (usuario_id) REFERENCES USUARIO(usuario_id)
        ON DELETE CASCADE,
    CONSTRAINT ck_fcm_plataforma
        CHECK (plataforma IN ('ANDROID', 'IOS')),
    CONSTRAINT ck_fcm_activo
        CHECK (activo IN (0, 1))
);

CREATE OR REPLACE TRIGGER trg_fcm_id
    BEFORE INSERT ON FCM_TOKEN
    FOR EACH ROW
BEGIN
    IF :NEW.fcm_id IS NULL THEN
        :NEW.fcm_id := seq_fcm_id.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE FCM_TOKEN IS 'Tokens FCM de dispositivos para notificaciones push - multiples por usuario (RF-25)';
COMMENT ON COLUMN FCM_TOKEN.plataforma IS 'ANDROID=Google FCM, IOS=Apple APNs via FCM';
COMMENT ON COLUMN FCM_TOKEN.activo IS '0=dispositivo desregistrado, 1=activo para recibir notificaciones';

PROMPT --> Tabla FCM_TOKEN creada

-- =============================================================================
-- TABLA 13: NOTIF_PREFERENCIAS
-- Descripcion: Preferencias de notificaciones push por usuario.
--              1 registro por usuario (UNIQUE en usuario_id).
--              Se crea automaticamente al registrar el usuario.
-- Ref SRS    : RF-26 Configuracion Notificaciones
-- =============================================================================

PROMPT --> Creando tabla NOTIF_PREFERENCIAS...

CREATE TABLE NOTIF_PREFERENCIAS (
    notif_pref_id       NUMBER          NOT NULL,
    usuario_id          NUMBER          NOT NULL,
    notif_matches       NUMBER(1)       DEFAULT 1   NOT NULL,
    notif_mensajes      NUMBER(1)       DEFAULT 1   NOT NULL,
    notif_super_likes   NUMBER(1)       DEFAULT 1   NOT NULL,
    notif_vistas_perfil NUMBER(1)       DEFAULT 1   NOT NULL,
    silencio_inicio     VARCHAR2(5)     NULL,
    silencio_fin        VARCHAR2(5)     NULL,
    -- CONSTRAINTS
    CONSTRAINT pk_notif_pref
        PRIMARY KEY (notif_pref_id),
    CONSTRAINT uq_notif_pref_usuario
        UNIQUE (usuario_id),
    CONSTRAINT fk_notif_pref_usuario
        FOREIGN KEY (usuario_id) REFERENCES USUARIO(usuario_id)
        ON DELETE CASCADE,
    CONSTRAINT ck_notif_matches
        CHECK (notif_matches IN (0, 1)),
    CONSTRAINT ck_notif_mensajes
        CHECK (notif_mensajes IN (0, 1)),
    CONSTRAINT ck_notif_super_likes
        CHECK (notif_super_likes IN (0, 1)),
    CONSTRAINT ck_notif_vistas
        CHECK (notif_vistas_perfil IN (0, 1)),
    CONSTRAINT ck_silencio_formato
        CHECK (
            (silencio_inicio IS NULL AND silencio_fin IS NULL) OR
            (silencio_inicio IS NOT NULL AND silencio_fin IS NOT NULL)
        )
);

CREATE OR REPLACE TRIGGER trg_notif_pref_id
    BEFORE INSERT ON NOTIF_PREFERENCIAS
    FOR EACH ROW
BEGIN
    IF :NEW.notif_pref_id IS NULL THEN
        :NEW.notif_pref_id := seq_notif_pref_id.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE NOTIF_PREFERENCIAS IS '1 registro por usuario - creado automaticamente al registrarse (RF-26)';
COMMENT ON COLUMN NOTIF_PREFERENCIAS.silencio_inicio IS 'Hora inicio modo silencio formato HH:MM UTC - NULL si desactivado';
COMMENT ON COLUMN NOTIF_PREFERENCIAS.silencio_fin IS 'Hora fin modo silencio formato HH:MM UTC - debe ser par con silencio_inicio';
COMMENT ON COLUMN NOTIF_PREFERENCIAS.notif_vistas_perfil IS 'Solo aplica para usuarios Premium (RF-25)';

PROMPT --> Tabla NOTIF_PREFERENCIAS creada

-- =============================================================================
-- TABLA 14: BOOST_HISTORIAL
-- Descripcion: Registra cada activacion de boost para controlar el limite
--              semanal por plan. Semana: lunes 00:00 UTC - domingo 23:59 UTC.
--              PREMIUM_MENSUAL: 1 boost/semana | PREMIUM_ANUAL: 2 boosts/semana
-- Ref SRS    : RF-24 Boost de Perfil
-- =============================================================================

PROMPT --> Creando tabla BOOST_HISTORIAL...

CREATE TABLE BOOST_HISTORIAL (
    boost_id            NUMBER      NOT NULL,
    usuario_id          NUMBER      NOT NULL,
    fecha_activacion    TIMESTAMP   DEFAULT SYSTIMESTAMP NOT NULL,
    fecha_fin           TIMESTAMP   NOT NULL,
    activo              NUMBER(1)   DEFAULT 1   NOT NULL,
    -- CONSTRAINTS
    CONSTRAINT pk_boost_historial
        PRIMARY KEY (boost_id),
    CONSTRAINT fk_boost_usuario
        FOREIGN KEY (usuario_id) REFERENCES USUARIO(usuario_id)
        ON DELETE CASCADE,
    CONSTRAINT ck_boost_activo
        CHECK (activo IN (0, 1))
);

CREATE OR REPLACE TRIGGER trg_boost_id
    BEFORE INSERT ON BOOST_HISTORIAL
    FOR EACH ROW
BEGIN
    IF :NEW.boost_id IS NULL THEN
        :NEW.boost_id := seq_boost_id.NEXTVAL;
    END IF;
    -- Duracion del boost: 30 minutos (RF-24)
    IF :NEW.fecha_fin IS NULL THEN
        :NEW.fecha_fin := SYSTIMESTAMP + INTERVAL '30' MINUTE;
    END IF;
END;
/

-- Trigger: desactiva boost automaticamente cuando expira
CREATE OR REPLACE TRIGGER trg_boost_expiracion
    BEFORE UPDATE ON BOOST_HISTORIAL
    FOR EACH ROW
BEGIN
    IF SYSTIMESTAMP > :NEW.fecha_fin THEN
        :NEW.activo := 0;
    END IF;
END;
/

COMMENT ON TABLE BOOST_HISTORIAL IS 'Historial de boosts - limite semanal lunes-domingo UTC (RF-24)';
COMMENT ON COLUMN BOOST_HISTORIAL.fecha_fin IS 'fecha_activacion + 30 minutos - calculado automaticamente por trigger';
COMMENT ON COLUMN BOOST_HISTORIAL.activo IS '1=boost activo, 0=expirado. PREMIUM_MENSUAL: 1/semana, PREMIUM_ANUAL: 2/semana';

PROMPT --> Tabla BOOST_HISTORIAL creada

-- =============================================================================
-- INDICES DE RENDIMIENTO
-- Descripcion: Indices para optimizar las consultas mas frecuentes del sistema
-- =============================================================================

PROMPT --> Creando indices de rendimiento...

-- USUARIO
CREATE INDEX idx_usuario_email         ON USUARIO(email);
CREATE INDEX idx_usuario_rol           ON USUARIO(rol, activo);

-- PERFIL
CREATE INDEX idx_perfil_usuario        ON PERFIL(usuario_id);
CREATE INDEX idx_perfil_ciudad         ON PERFIL(ciudad);

-- FOTO
CREATE INDEX idx_foto_usuario          ON FOTO(usuario_id, orden);

-- LIKE_ACCION (consultas frecuentes en swipe y deteccion de match)
CREATE INDEX idx_like_origen           ON LIKE_ACCION(usuario_origen, tipo);
CREATE INDEX idx_like_destino          ON LIKE_ACCION(usuario_destino, tipo);
CREATE INDEX idx_like_fecha            ON LIKE_ACCION(usuario_origen, fecha);

-- MATCH_TOPNIS (consultas de lista de matches)
CREATE INDEX idx_match_usuario1        ON MATCH_TOPNIS(usuario1_id, activo);
CREATE INDEX idx_match_usuario2        ON MATCH_TOPNIS(usuario2_id, activo);
CREATE INDEX idx_match_fecha           ON MATCH_TOPNIS(fecha_match DESC);

-- MENSAJE (historial de chat paginado)
CREATE INDEX idx_mensaje_match         ON MENSAJE(match_id, fecha_envio DESC);
CREATE INDEX idx_mensaje_emisor        ON MENSAJE(emisor_id);
CREATE INDEX idx_mensaje_estado        ON MENSAJE(match_id, estado);

-- SUSCRIPCION (verificacion rapida del plan activo)
CREATE INDEX idx_suscripcion_usuario   ON SUSCRIPCION(usuario_id, activo);
CREATE INDEX idx_suscripcion_plan      ON SUSCRIPCION(plan, activo);

-- BLOQUEO (exclusion en discover)
CREATE INDEX idx_bloqueo_bloqueador    ON BLOQUEO(usuario_bloqueador);
CREATE INDEX idx_bloqueo_bloqueado     ON BLOQUEO(usuario_bloqueado);

-- REPORTE (gestion admin)
CREATE INDEX idx_reporte_estado        ON REPORTE(estado, fecha_reporte DESC);
CREATE INDEX idx_reporte_denunciado    ON REPORTE(usuario_denunciado);

-- JWT_BLACKLIST (validacion rapida de token)
CREATE INDEX idx_jwt_jti               ON JWT_BLACKLIST(token_jti);
CREATE INDEX idx_jwt_expiracion        ON JWT_BLACKLIST(fecha_expiracion);

-- FCM_TOKEN (envio de notificaciones)
CREATE INDEX idx_fcm_usuario           ON FCM_TOKEN(usuario_id, activo);

-- BOOST_HISTORIAL (calculo limite semanal)
CREATE INDEX idx_boost_usuario_fecha   ON BOOST_HISTORIAL(usuario_id, fecha_activacion DESC);

-- INDICES OPCIONALES DE RENDIMIENTO (discover, reset, boost activo)
-- PERFIL: filtros del algoritmo discover RF-10
CREATE INDEX idx_perfil_edad           ON PERFIL(edad_min_buscada, edad_max_buscada);
CREATE INDEX idx_perfil_genero         ON PERFIL(genero_buscado);

-- RESET_TOKEN: invalidar tokens anteriores del mismo usuario (RF-04)
CREATE INDEX idx_reset_usuario_usado   ON RESET_TOKEN(usuario_id, usado);

-- BOOST_HISTORIAL: verificar boost activo actual (RF-24)
CREATE INDEX idx_boost_activo          ON BOOST_HISTORIAL(usuario_id, activo, fecha_fin);

PROMPT --> Indices creados: 28 (24 criticos + 4 opcionales de rendimiento)

-- =============================================================================
-- DATOS INICIALES (INSERT para pruebas)
-- =============================================================================

PROMPT --> Insertando datos de prueba...

-- Usuario Admin
INSERT INTO USUARIO (nombre, email, password_hash, fecha_nacimiento, genero, rol, activo, email_verificado)
VALUES (
    'Admin TopnisMatch',
    'admin@topnismatch.com',
    '$2a$10$placeholder_hash_admin_bcrypt_factor10',
    TO_DATE('1990-01-01', 'YYYY-MM-DD'),
    'MASCULINO',
    'ADMIN',
    1,
    1
);

-- Usuario de prueba 1 (Estandar)
INSERT INTO USUARIO (nombre, email, password_hash, fecha_nacimiento, genero, rol, activo, email_verificado)
VALUES (
    'Juan Perez',
    'juan@test.com',
    '$2a$10$placeholder_hash_juan_bcrypt_factor10',
    TO_DATE('1995-06-15', 'YYYY-MM-DD'),
    'MASCULINO',
    'USER',
    1,
    1
);

-- Usuario de prueba 2 (Premium)
INSERT INTO USUARIO (nombre, email, password_hash, fecha_nacimiento, genero, rol, activo, email_verificado)
VALUES (
    'Maria Garcia',
    'maria@test.com',
    '$2a$10$placeholder_hash_maria_bcrypt_factor10',
    TO_DATE('1997-03-22', 'YYYY-MM-DD'),
    'FEMENINO',
    'PREMIUM',
    1,
    1
);

-- Suscripciones iniciales (GRATUITO por defecto para todos)
INSERT INTO SUSCRIPCION (usuario_id, plan, fecha_inicio, activo)
SELECT usuario_id, 'GRATUITO', SYSTIMESTAMP, 1
FROM USUARIO;

-- Preferencias de notificaciones (todas activas por defecto)
INSERT INTO NOTIF_PREFERENCIAS (usuario_id, notif_matches, notif_mensajes, notif_super_likes, notif_vistas_perfil)
SELECT usuario_id, 1, 1, 1, 1
FROM USUARIO;

-- Perfiles de prueba
INSERT INTO PERFIL (usuario_id, bio, ciudad, intereses, edad_min_buscada, edad_max_buscada, distancia_max_km)
VALUES (
    (SELECT usuario_id FROM USUARIO WHERE email = 'juan@test.com'),
    'Me gusta la musica y los viajes',
    'Santiago',
    'musica,viajes,gastronomia,deporte',
    22, 35, 30
);

INSERT INTO PERFIL (usuario_id, bio, ciudad, intereses, edad_min_buscada, edad_max_buscada, distancia_max_km)
VALUES (
    (SELECT usuario_id FROM USUARIO WHERE email = 'maria@test.com'),
    'Amo la naturaleza y el yoga',
    'Santiago',
    'yoga,naturaleza,lectura,musica',
    25, 38, 25
);

COMMIT;

PROMPT --> Datos de prueba insertados

-- =============================================================================
-- VERIFICACION FINAL
-- =============================================================================

PROMPT ================================================================
PROMPT  VERIFICACION FINAL - TopnisMatch Base de Datos
PROMPT ================================================================

SELECT 'Tablas creadas: ' || COUNT(*) AS resultado
FROM user_tables
WHERE table_name IN (
    'USUARIO','FOTO','PERFIL','LIKE_ACCION','MATCH_TOPNIS',
    'MENSAJE','SUSCRIPCION','BLOQUEO','REPORTE','JWT_BLACKLIST',
    'RESET_TOKEN','FCM_TOKEN','NOTIF_PREFERENCIAS','BOOST_HISTORIAL'
);

SELECT 'Secuencias creadas: ' || COUNT(*) AS resultado
FROM user_sequences
WHERE sequence_name LIKE 'SEQ_%';

SELECT 'Indices creados: ' || COUNT(*) AS resultado
FROM user_indexes
WHERE table_name IN (
    'USUARIO','FOTO','PERFIL','LIKE_ACCION','MATCH_TOPNIS',
    'MENSAJE','SUSCRIPCION','BLOQUEO','REPORTE','JWT_BLACKLIST',
    'RESET_TOKEN','FCM_TOKEN','NOTIF_PREFERENCIAS','BOOST_HISTORIAL'
)
AND index_type = 'NORMAL';

SELECT 'Triggers creados: ' || COUNT(*) AS resultado
FROM user_triggers
WHERE table_name IN (
    'USUARIO','FOTO','PERFIL','LIKE_ACCION','MATCH_TOPNIS',
    'MENSAJE','SUSCRIPCION','BLOQUEO','REPORTE','JWT_BLACKLIST',
    'RESET_TOKEN','FCM_TOKEN','NOTIF_PREFERENCIAS','BOOST_HISTORIAL'
);

SELECT 'Usuarios de prueba: ' || COUNT(*) AS resultado
FROM USUARIO;

PROMPT ================================================================
PROMPT  TopnisMatch BD v1.2 - Creacion completada exitosamente
PROMPT  Tablas: 14 | Secuencias: 14 | Indices: 28 | Triggers: 22 | Packages: 1
PROMPT  Autor: Junior Altidor | Abril 2026 | Basado en SRS v1.5
PROMPT ================================================================
-- =============================================================================
-- HISTORIAL DE VERSIONES
-- =============================================================================
-- v1.0 Abril 2026: Version inicial - 14 tablas, 14 secuencias, 24 indices,
--                  20 triggers. Basado en SRS v1.5.
-- v1.1 Abril 2026: CORRECCIONES CRITICAS DE ORACLE:
--   FIX-1: CHECK ck_usuario_mayor_edad eliminado (ORA-02436).
--           Oracle no permite SYSDATE en CHECK constraints DDL.
--           Validacion 18+ movida a trg_usuario_id con MONTHS_BETWEEN.
--   FIX-2: trg_suscripcion_unica refactorizado (ORA-04091 mutating table).
--           SELECT en FOR EACH ROW sobre misma tabla causa error en INSERT masivo.
--           Solucion: pkg_suscripcion_ctrl + trg_suscripcion_row (ROW)
--                     + trg_suscripcion_unica (STATEMENT LEVEL).
-- v1.2 Abril 2026: 4 INDICES OPCIONALES DE RENDIMIENTO AGREGADOS:
--   idx_perfil_edad    : PERFIL(edad_min_buscada, edad_max_buscada) - filtro discover
--   idx_perfil_genero  : PERFIL(genero_buscado) - filtro genero discover
--   idx_reset_usuario_usado: RESET_TOKEN(usuario_id, usado) - invalidar tokens
--   idx_boost_activo   : BOOST_HISTORIAL(usuario_id, activo, fecha_fin) - boost actual
--   Total indices: 28 (24 criticos + 4 opcionales). Version definitiva.
-- =============================================================================
