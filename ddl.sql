-- =======================================================
-- FILE: ddl.sql
-- Script de creación de la base de datos, usuario, esquemas, tipos, tablas y funciones
-- para el sistema de reservas de eventos.
-- =======================================================

-- 1) Eliminar la base de datos y el usuario si ya existen
DROP DATABASE IF EXISTS reservaciones;
DROP USER IF EXISTS reserva_user;

-- 2) Crear el usuario y la base de datos con OWNER
CREATE USER reserva_user WITH PASSWORD 'reserva_password';
ALTER ROLE reserva_user WITH CREATEDB;

CREATE DATABASE reservaciones
    WITH OWNER = reserva_user
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- IMPORTANTE: En psql se haría:
--   \c reservaciones
-- O en tu cliente, conectarse ahora a la base 'reservaciones' como 'reserva_user'.

-- 3) Definición de estructuras dentro de un bloque DO

DO $$
BEGIN
    RAISE NOTICE 'Iniciando la creación de esquemas, tipos y tablas...';

    -- -------------------------------------------------------------------------
    -- Eliminar objetos en orden inverso, por si se reejecuta
    -- -------------------------------------------------------------------------
    EXECUTE 'DROP SCHEMA IF EXISTS eventos CASCADE';

    -- -------------------------------------------------------------------------
    -- Creación de esquema
    -- -------------------------------------------------------------------------
    EXECUTE 'CREATE SCHEMA eventos';

    -- -------------------------------------------------------------------------
    -- Función global update_timestamp
    -- -------------------------------------------------------------------------
    EXECUTE '
        CREATE OR REPLACE FUNCTION update_timestamp()
        RETURNS TRIGGER AS $BODY$
        BEGIN
            NEW.updated_at = NOW();
            RETURN NEW;
        END;
        $BODY$ LANGUAGE plpgsql;
    ';

    -- -------------------------------------------------------------------------
    -- SCHEMA: eventos
    -- -------------------------------------------------------------------------
    
    -- Tabla de Eventos
    EXECUTE '
        CREATE TABLE eventos.evento (
            evento_id SERIAL PRIMARY KEY,
            nombre VARCHAR(255) NOT NULL,
            descripcion TEXT,
            fecha_inicio TIMESTAMP NOT NULL,
            fecha_fin TIMESTAMP NOT NULL,
            lugar VARCHAR(255) NOT NULL,
            capacidad_total INTEGER NOT NULL,
            created_at TIMESTAMP NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
            CONSTRAINT chk_fecha_valida CHECK (fecha_fin > fecha_inicio)
        );
    ';

    EXECUTE 'COMMENT ON TABLE eventos.evento IS ''Información de los eventos disponibles para reserva'';';

    EXECUTE '
        CREATE TRIGGER trg_evento_update_timestamp
        BEFORE UPDATE ON eventos.evento
        FOR EACH ROW
        EXECUTE FUNCTION update_timestamp();
    ';

    -- Tabla de tipos de asiento
    EXECUTE '
        CREATE TABLE eventos.tipo_asiento (
            tipo_id SERIAL PRIMARY KEY,
            nombre VARCHAR(100) NOT NULL,
            descripcion TEXT,
            precio NUMERIC(10,2) NOT NULL,
            created_at TIMESTAMP NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMP NOT NULL DEFAULT NOW()
        );
    ';

    EXECUTE 'COMMENT ON TABLE eventos.tipo_asiento IS ''Categorías de asientos disponibles (VIP, General, etc.)'';';

    EXECUTE '
        CREATE TRIGGER trg_tipo_asiento_update_timestamp
        BEFORE UPDATE ON eventos.tipo_asiento
        FOR EACH ROW
        EXECUTE FUNCTION update_timestamp();
    ';

    -- Tabla de Secciones del Evento
    EXECUTE '
        CREATE TABLE eventos.seccion (
            seccion_id SERIAL PRIMARY KEY,
            evento_id INTEGER NOT NULL REFERENCES eventos.evento(evento_id) ON DELETE CASCADE,
            nombre VARCHAR(100) NOT NULL,
            tipo_asiento_id INTEGER NOT NULL REFERENCES eventos.tipo_asiento(tipo_id) ON DELETE RESTRICT,
            capacidad INTEGER NOT NULL,
            created_at TIMESTAMP NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
            CONSTRAINT uq_seccion_evento UNIQUE (evento_id, nombre)
        );
    ';

    EXECUTE 'COMMENT ON TABLE eventos.seccion IS ''Secciones dentro de un evento (Zonas)'';';

    EXECUTE '
        CREATE TRIGGER trg_seccion_update_timestamp
        BEFORE UPDATE ON eventos.seccion
        FOR EACH ROW
        EXECUTE FUNCTION update_timestamp();
    ';

    -- Tabla de Asientos
    EXECUTE '
        CREATE TABLE eventos.asiento (
            asiento_id SERIAL PRIMARY KEY,
            seccion_id INTEGER NOT NULL REFERENCES eventos.seccion(seccion_id) ON DELETE CASCADE,
            fila VARCHAR(10) NOT NULL,
            numero VARCHAR(10) NOT NULL,
            estado VARCHAR(20) NOT NULL DEFAULT ''DISPONIBLE'',
            created_at TIMESTAMP NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
            CONSTRAINT uq_asiento_seccion UNIQUE (seccion_id, fila, numero),
            CONSTRAINT chk_estado_asiento CHECK (estado IN (''DISPONIBLE'', ''RESERVADO'', ''BLOQUEADO''))
        );
    ';

    EXECUTE 'COMMENT ON TABLE eventos.asiento IS ''Asientos individuales dentro de una sección'';';

    EXECUTE '
        CREATE TRIGGER trg_asiento_update_timestamp
        BEFORE UPDATE ON eventos.asiento
        FOR EACH ROW
        EXECUTE FUNCTION update_timestamp();
    ';

    -- Tabla de Usuarios
    EXECUTE '
        CREATE TABLE eventos.usuario (
            usuario_id SERIAL PRIMARY KEY,
            nombre VARCHAR(100) NOT NULL,
            apellido VARCHAR(100) NOT NULL,
            email VARCHAR(255) NOT NULL UNIQUE,
            telefono VARCHAR(20),
            created_at TIMESTAMP NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMP NOT NULL DEFAULT NOW()
        );
    ';

    EXECUTE 'COMMENT ON TABLE eventos.usuario IS ''Información de los usuarios que realizan reservas'';';

    EXECUTE '
        CREATE TRIGGER trg_usuario_update_timestamp
        BEFORE UPDATE ON eventos.usuario
        FOR EACH ROW
        EXECUTE FUNCTION update_timestamp();
    ';

    -- Tabla de Reservas
    EXECUTE '
        CREATE TABLE eventos.reserva (
            reserva_id SERIAL PRIMARY KEY,
            usuario_id INTEGER NOT NULL REFERENCES eventos.usuario(usuario_id) ON DELETE RESTRICT,
            fecha_reserva TIMESTAMP NOT NULL DEFAULT NOW(),
            estado VARCHAR(20) NOT NULL DEFAULT ''PENDIENTE'',
            total_precio NUMERIC(10,2) NOT NULL DEFAULT 0,
            metodo_pago VARCHAR(50),
            referencia_pago VARCHAR(100),
            created_at TIMESTAMP NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
            CONSTRAINT chk_estado_reserva CHECK (estado IN (''PENDIENTE'', ''CONFIRMADA'', ''CANCELADA''))
        );
    ';

    EXECUTE 'COMMENT ON TABLE eventos.reserva IS ''Encabezado de reservas realizadas por los usuarios'';';

    EXECUTE '
        CREATE TRIGGER trg_reserva_update_timestamp
        BEFORE UPDATE ON eventos.reserva
        FOR EACH ROW
        EXECUTE FUNCTION update_timestamp();
    ';

    -- Tabla de Detalle de Reserva (Asientos reservados)
    EXECUTE '
        CREATE TABLE eventos.reserva_detalle (
            detalle_id SERIAL PRIMARY KEY,
            reserva_id INTEGER NOT NULL REFERENCES eventos.reserva(reserva_id) ON DELETE CASCADE,
            asiento_id INTEGER NOT NULL REFERENCES eventos.asiento(asiento_id) ON DELETE RESTRICT,
            precio_unitario NUMERIC(10,2) NOT NULL,
            created_at TIMESTAMP NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
            CONSTRAINT uq_asiento_reserva UNIQUE (asiento_id, reserva_id)
        );
    ';

    EXECUTE 'COMMENT ON TABLE eventos.reserva_detalle IS ''Detalle de asientos incluidos en una reserva'';';

    EXECUTE '
        CREATE TRIGGER trg_reserva_detalle_update_timestamp
        BEFORE UPDATE ON eventos.reserva_detalle
        FOR EACH ROW
        EXECUTE FUNCTION update_timestamp();
    ';

    -- Tabla de Registro de Intentos de Reserva (para análisis de concurrencia)
    EXECUTE '
        CREATE TABLE eventos.log_intentos_reserva (
            log_id SERIAL PRIMARY KEY,
            usuario_id INTEGER NOT NULL REFERENCES eventos.usuario(usuario_id) ON DELETE CASCADE,
            asiento_id INTEGER NOT NULL REFERENCES eventos.asiento(asiento_id) ON DELETE CASCADE,
            resultado VARCHAR(20) NOT NULL, -- EXITOSO, FALLIDO
            nivel_aislamiento VARCHAR(50), -- READ COMMITTED, REPEATABLE READ, SERIALIZABLE
            tiempo_ejecucion INTEGER, -- en milisegundos
            mensaje_error TEXT,
            timestamp TIMESTAMP NOT NULL DEFAULT NOW()
        );
    ';

    EXECUTE 'COMMENT ON TABLE eventos.log_intentos_reserva IS ''Registro de intentos de reserva para análisis de concurrencia'';';

    -- Índices para mejorar el rendimiento en consultas frecuentes
    EXECUTE 'CREATE INDEX idx_asiento_estado ON eventos.asiento(estado);';
    EXECUTE 'CREATE INDEX idx_reserva_usuario ON eventos.reserva(usuario_id);';
    EXECUTE 'CREATE INDEX idx_reserva_estado ON eventos.reserva(estado);';
    EXECUTE 'CREATE INDEX idx_log_resultado ON eventos.log_intentos_reserva(resultado);';
    EXECUTE 'CREATE INDEX idx_log_nivel_aislamiento ON eventos.log_intentos_reserva(nivel_aislamiento);';

    -- Función para realizar reserva
    EXECUTE '
        CREATE OR REPLACE FUNCTION eventos.realizar_reserva(
            p_usuario_id INTEGER,
            p_asiento_id INTEGER
        ) RETURNS INTEGER AS $BODY$
        DECLARE
            v_reserva_id INTEGER;
            v_precio NUMERIC(10,2);
            v_estado_asiento VARCHAR(20);
        BEGIN
            -- Verificar si el asiento está disponible
            SELECT estado INTO v_estado_asiento
            FROM eventos.asiento
            WHERE asiento_id = p_asiento_id
            FOR UPDATE;

            IF v_estado_asiento != ''DISPONIBLE'' THEN
                RAISE EXCEPTION ''El asiento ya no está disponible. Estado actual: %'', v_estado_asiento;
            END IF;

            -- Obtener el precio del asiento
            SELECT ta.precio INTO v_precio
            FROM eventos.asiento a
            JOIN eventos.seccion s ON a.seccion_id = s.seccion_id
            JOIN eventos.tipo_asiento ta ON s.tipo_asiento_id = ta.tipo_id
            WHERE a.asiento_id = p_asiento_id;

            -- Crear o actualizar la reserva pendiente del usuario
            SELECT reserva_id INTO v_reserva_id
            FROM eventos.reserva
            WHERE usuario_id = p_usuario_id AND estado = ''PENDIENTE''
            LIMIT 1;

            IF v_reserva_id IS NULL THEN
                INSERT INTO eventos.reserva (usuario_id, total_precio)
                VALUES (p_usuario_id, v_precio)
                RETURNING reserva_id INTO v_reserva_id;
            ELSE
                UPDATE eventos.reserva
                SET total_precio = total_precio + v_precio
                WHERE reserva_id = v_reserva_id;
            END IF;

            -- Agregar el asiento a la reserva
            INSERT INTO eventos.reserva_detalle (reserva_id, asiento_id, precio_unitario)
            VALUES (v_reserva_id, p_asiento_id, v_precio);

            -- Actualizar el estado del asiento
            UPDATE eventos.asiento
            SET estado = ''RESERVADO''
            WHERE asiento_id = p_asiento_id;

            RETURN v_reserva_id;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE;
        END;
        $BODY$ LANGUAGE plpgsql;
    ';

    EXECUTE 'COMMENT ON FUNCTION eventos.realizar_reserva IS ''Función para realizar la reserva de un asiento específico, considerando concurrencia'';';

    RAISE NOTICE 'Creación de esquemas, tipos y tablas finalizada exitosamente.';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERROR al crear la estructura. Código: % - Mensaje: %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Otorgar permisos al usuario en todos los esquemas
GRANT ALL PRIVILEGES ON SCHEMA eventos TO reserva_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA eventos TO reserva_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA eventos TO reserva_user;