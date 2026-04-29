-- ================================================================
-- TopnisMatch - Script PostgreSQL v1.0
-- Migración desde Oracle XE 21c a PostgreSQL 17
-- ================================================================

-- Extensiones
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================================================
-- SECUENCIAS
-- ================================================================
CREATE SEQUENCE seq_usuario_id START 1 INCREMENT 1;
CREATE SEQUENCE seq_foto_id START 1 INCREMENT 1;
CREATE SEQUENCE seq_perfil_id START 1 INCREMENT 1;
CREATE SEQUENCE seq_like_id START 1 INCREMENT 1;
CREATE SEQUENCE seq_match_id START 1 INCREMENT 1;
CREATE SEQUENCE seq_mensaje_id START 1 INCREMENT 1;
CREATE SEQUENCE seq_suscripcion_id START 1 INCREMENT 1;
CREATE SEQUENCE seq_bloqueo_id START 1 INCREMENT 1;
CREATE SEQUENCE seq_reporte_id START 1 INCREMENT 1;
CREATE SEQUENCE seq_blacklist_id START 1 INCREMENT 1;
CREATE SEQUENCE seq_reset_id START 1 INCREMENT 1;
CREATE SEQUENCE seq_fcm_id START 1 INCREMENT 1;
CREATE SEQUENCE seq_notif_pref_id START 1 INCREMENT 1;
CREATE SEQUENCE seq_boost_id START 1 INCREMENT 1;

-- ================================================================
-- TABLAS
-- ================================================================

-- USUARIO
CREATE TABLE USUARIO (
    usuario_id      BIGINT DEFAULT NEXTVAL('seq_usuario_id') PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    genero          VARCHAR(20) NOT NULL CHECK (genero IN ('MASCULINO','FEMENINO','NO_BINARIO','PREFIERO_NO_DECIR')),
    rol             VARCHAR(20) NOT NULL DEFAULT 'USER' CHECK (rol IN ('USER','PREMIUM','ADMIN')),
    activo          SMALLINT NOT NULL DEFAULT 1 CHECK (activo IN (0,1)),
    email_verificado SMALLINT NOT NULL DEFAULT 0 CHECK (email_verificado IN (0,1)),
    fecha_registro  TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP DEFAULT NOW(),
    CONSTRAINT chk_edad_minima CHECK (fecha_nacimiento <= CURRENT_DATE - INTERVAL '18 years')
);

-- FOTO
CREATE TABLE FOTO (
    foto_id     BIGINT DEFAULT NEXTVAL('seq_foto_id') PRIMARY KEY,
    usuario_id  BIGINT NOT NULL REFERENCES USUARIO(usuario_id),
    url         VARCHAR(500) NOT NULL,
    orden       SMALLINT NOT NULL CHECK (orden BETWEEN 1 AND 6),
    fecha_subida TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (usuario_id, orden)
);

-- PERFIL
CREATE TABLE PERFIL (
    perfil_id           BIGINT DEFAULT NEXTVAL('seq_perfil_id') PRIMARY KEY,
    usuario_id          BIGINT NOT NULL UNIQUE REFERENCES USUARIO(usuario_id),
    bio                 VARCHAR(500),
    ciudad              VARCHAR(100),
    objetivo            VARCHAR(30) NOT NULL DEFAULT 'RELACION_SERIA',
    intereses           VARCHAR(1000),
    edad_min_buscada    SMALLINT NOT NULL DEFAULT 18 CHECK (edad_min_buscada >= 18),
    edad_max_buscada    SMALLINT NOT NULL DEFAULT 99 CHECK (edad_max_buscada <= 99),
    distancia_max_km    SMALLINT NOT NULL DEFAULT 50,
    genero_buscado      VARCHAR(20),
    foto_principal_id   BIGINT REFERENCES FOTO(foto_id),
    fecha_actualizacion TIMESTAMP DEFAULT NOW()
);

-- LIKE_ACCION
CREATE TABLE LIKE_ACCION (
    like_id         BIGINT DEFAULT NEXTVAL('seq_like_id') PRIMARY KEY,
    usuario_origen  BIGINT NOT NULL REFERENCES USUARIO(usuario_id),
    usuario_destino BIGINT NOT NULL REFERENCES USUARIO(usuario_id),
    tipo            VARCHAR(10) NOT NULL CHECK (tipo IN ('LIKE','DISLIKE','SUPERLIKE')),
    fecha           TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (usuario_origen, usuario_destino),
    CHECK (usuario_origen <> usuario_destino)
);

-- MATCH_TOPNIS
CREATE TABLE MATCH_TOPNIS (
    match_id        BIGINT DEFAULT NEXTVAL('seq_match_id') PRIMARY KEY,
    usuario1_id     BIGINT NOT NULL REFERENCES USUARIO(usuario_id),
    usuario2_id     BIGINT NOT NULL REFERENCES USUARIO(usuario_id),
    compatibilidad  DECIMAL(5,2) DEFAULT 0,
    fecha_match     TIMESTAMP NOT NULL DEFAULT NOW(),
    activo          SMALLINT NOT NULL DEFAULT 1 CHECK (activo IN (0,1)),
    UNIQUE (usuario1_id, usuario2_id),
    CHECK (usuario1_id < usuario2_id)
);

-- MENSAJE
CREATE TABLE MENSAJE (
    mensaje_id  BIGINT DEFAULT NEXTVAL('seq_mensaje_id') PRIMARY KEY,
    match_id    BIGINT NOT NULL REFERENCES MATCH_TOPNIS(match_id),
    emisor_id   BIGINT NOT NULL REFERENCES USUARIO(usuario_id),
    contenido   VARCHAR(1000) NOT NULL,
    estado      VARCHAR(10) NOT NULL DEFAULT 'ENVIADO' CHECK (estado IN ('ENVIADO','ENTREGADO','LEIDO')),
    fecha_envio TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_leido TIMESTAMP
);

-- SUSCRIPCION
CREATE TABLE SUSCRIPCION (
    suscripcion_id  BIGINT DEFAULT NEXTVAL('seq_suscripcion_id') PRIMARY KEY,
    usuario_id      BIGINT NOT NULL REFERENCES USUARIO(usuario_id),
    plan            VARCHAR(20) NOT NULL DEFAULT 'GRATUITO' CHECK (plan IN ('GRATUITO','PREMIUM_MENSUAL','PREMIUM_ANUAL')),
    fecha_inicio    TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_fin       TIMESTAMP,
    activo          SMALLINT NOT NULL DEFAULT 1 CHECK (activo IN (0,1)),
    recibo_store    VARCHAR(500)
);

-- BLOQUEO
CREATE TABLE BLOQUEO (
    bloqueo_id          BIGINT DEFAULT NEXTVAL('seq_bloqueo_id') PRIMARY KEY,
    usuario_bloqueador  BIGINT NOT NULL REFERENCES USUARIO(usuario_id),
    usuario_bloqueado   BIGINT NOT NULL REFERENCES USUARIO(usuario_id),
    fecha_bloqueo       TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (usuario_bloqueador, usuario_bloqueado),
    CHECK (usuario_bloqueador <> usuario_bloqueado)
);

-- REPORTE
CREATE TABLE REPORTE (
    reporte_id          BIGINT DEFAULT NEXTVAL('seq_reporte_id') PRIMARY KEY,
    usuario_denunciante BIGINT NOT NULL REFERENCES USUARIO(usuario_id),
    usuario_denunciado  BIGINT NOT NULL REFERENCES USUARIO(usuario_id),
    categoria           VARCHAR(30) NOT NULL DEFAULT 'OTRO',
    descripcion         VARCHAR(300),
    estado              VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    nota_admin          VARCHAR(500),
    admin_resolutor_id  BIGINT REFERENCES USUARIO(usuario_id),
    fecha_reporte       TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_resolucion    TIMESTAMP
);

-- JWT_BLACKLIST
CREATE TABLE JWT_BLACKLIST (
    blacklist_id    BIGINT DEFAULT NEXTVAL('seq_blacklist_id') PRIMARY KEY,
    token_jti       VARCHAR(255) NOT NULL UNIQUE,
    usuario_id      BIGINT NOT NULL REFERENCES USUARIO(usuario_id),
    fecha_expiracion TIMESTAMP NOT NULL,
    fecha_revocacion TIMESTAMP NOT NULL DEFAULT NOW()
);

-- RESET_TOKEN
CREATE TABLE RESET_TOKEN (
    reset_id        BIGINT DEFAULT NEXTVAL('seq_reset_id') PRIMARY KEY,
    usuario_id      BIGINT NOT NULL REFERENCES USUARIO(usuario_id),
    token           VARCHAR(255) NOT NULL UNIQUE,
    usado           SMALLINT NOT NULL DEFAULT 0 CHECK (usado IN (0,1)),
    fecha_creacion  TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_expiracion TIMESTAMP NOT NULL
);

-- FCM_TOKEN
CREATE TABLE FCM_TOKEN (
    fcm_id      BIGINT DEFAULT NEXTVAL('seq_fcm_id') PRIMARY KEY,
    usuario_id  BIGINT NOT NULL REFERENCES USUARIO(usuario_id),
    token       VARCHAR(500) NOT NULL,
    plataforma  VARCHAR(10) NOT NULL DEFAULT 'ANDROID',
    activo      SMALLINT NOT NULL DEFAULT 1,
    fecha_registro TIMESTAMP NOT NULL DEFAULT NOW()
);

-- NOTIF_PREFERENCIAS
CREATE TABLE NOTIF_PREFERENCIAS (
    notif_pref_id       BIGINT DEFAULT NEXTVAL('seq_notif_pref_id') PRIMARY KEY,
    usuario_id          BIGINT NOT NULL UNIQUE REFERENCES USUARIO(usuario_id),
    notif_matches       SMALLINT NOT NULL DEFAULT 1,
    notif_mensajes      SMALLINT NOT NULL DEFAULT 1,
    notif_super_likes   SMALLINT NOT NULL DEFAULT 1,
    notif_vistas_perfil SMALLINT NOT NULL DEFAULT 1,
    silencio_inicio     VARCHAR(5),
    silencio_fin        VARCHAR(5)
);

-- BOOST_HISTORIAL
CREATE TABLE BOOST_HISTORIAL (
    boost_id            BIGINT DEFAULT NEXTVAL('seq_boost_id') PRIMARY KEY,
    usuario_id          BIGINT NOT NULL REFERENCES USUARIO(usuario_id),
    fecha_activacion    TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_fin           TIMESTAMP NOT NULL,
    activo              SMALLINT NOT NULL DEFAULT 1 CHECK (activo IN (0,1))
);

-- ================================================================
-- ÍNDICES
-- ================================================================
CREATE INDEX idx_usuario_email ON USUARIO(email);
CREATE INDEX idx_foto_usuario ON FOTO(usuario_id);
CREATE INDEX idx_perfil_usuario ON PERFIL(usuario_id);
CREATE INDEX idx_like_origen ON LIKE_ACCION(usuario_origen);
CREATE INDEX idx_like_destino ON LIKE_ACCION(usuario_destino);
CREATE INDEX idx_match_usuario1 ON MATCH_TOPNIS(usuario1_id);
CREATE INDEX idx_match_usuario2 ON MATCH_TOPNIS(usuario2_id);
CREATE INDEX idx_mensaje_match ON MENSAJE(match_id);
CREATE INDEX idx_suscripcion_usuario ON SUSCRIPCION(usuario_id);
CREATE INDEX idx_bloqueo_bloqueador ON BLOQUEO(usuario_bloqueador);
CREATE INDEX idx_reporte_estado ON REPORTE(estado);
CREATE INDEX idx_jwt_jti ON JWT_BLACKLIST(token_jti);
CREATE INDEX idx_reset_token ON RESET_TOKEN(token);
CREATE INDEX idx_boost_usuario ON BOOST_HISTORIAL(usuario_id);

-- ================================================================
-- TRIGGERS
-- ================================================================

-- Trigger actualizar fecha_actualizacion en USUARIO
CREATE OR REPLACE FUNCTION fn_update_usuario_fecha()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_usuario_fecha
BEFORE UPDATE ON USUARIO
FOR EACH ROW EXECUTE FUNCTION fn_update_usuario_fecha();

-- Trigger actualizar fecha_actualizacion en PERFIL
CREATE OR REPLACE FUNCTION fn_update_perfil_fecha()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_perfil_fecha
BEFORE UPDATE ON PERFIL
FOR EACH ROW EXECUTE FUNCTION fn_update_perfil_fecha();

-- Trigger fecha_leido en MENSAJE
CREATE OR REPLACE FUNCTION fn_mensaje_leido()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado = 'LEIDO' AND OLD.estado != 'LEIDO' THEN
        NEW.fecha_leido = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_mensaje_leido
BEFORE UPDATE ON MENSAJE
FOR EACH ROW EXECUTE FUNCTION fn_mensaje_leido();

-- ================================================================
-- DATOS DE PRUEBA
-- ================================================================

-- Usuario Admin
INSERT INTO USUARIO (nombre, email, password_hash, fecha_nacimiento, genero, rol, activo, email_verificado)
VALUES ('Admin TopnisMatch', 'superadmin@test.com',
'$2a$10$JhsDnW87Sj81Ue0KZQYvI.06QYskFpxFXMmpxs1rplqP1lbPZSi/a',
'1990-01-01', 'MASCULINO', 'ADMIN', 1, 1);

-- Usuario de prueba
INSERT INTO USUARIO (nombre, email, password_hash, fecha_nacimiento, genero, rol, activo, email_verificado)
VALUES ('Juan Perez', 'juan@test.com',
'$2a$10$JhsDnW87Sj81Ue0KZQYvI.06QYskFpxFXMmpxs1rplqP1lbPZSi/a',
'1996-05-15', 'MASCULINO', 'USER', 1, 1);

COMMIT;