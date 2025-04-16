-- =======================================================
-- FILE: data.sql
-- Script para cargar datos de prueba en la base de datos
-- =======================================================

-- Conectarse a la base de datos
-- \c reservaciones

-- Iniciar transacción
BEGIN;

-- Limpiar datos existentes manteniendo la estructura
TRUNCATE eventos.reserva_detalle CASCADE;
TRUNCATE eventos.reserva CASCADE;
TRUNCATE eventos.asiento CASCADE;
TRUNCATE eventos.seccion CASCADE;
TRUNCATE eventos.tipo_asiento CASCADE;
TRUNCATE eventos.evento CASCADE;
TRUNCATE eventos.usuario CASCADE;
TRUNCATE eventos.log_intentos_reserva CASCADE;

-- Resetear secuencias
ALTER SEQUENCE eventos.evento_evento_id_seq RESTART WITH 1;
ALTER SEQUENCE eventos.tipo_asiento_tipo_id_seq RESTART WITH 1;
ALTER SEQUENCE eventos.seccion_seccion_id_seq RESTART WITH 1;
ALTER SEQUENCE eventos.asiento_asiento_id_seq RESTART WITH 1;
ALTER SEQUENCE eventos.usuario_usuario_id_seq RESTART WITH 1;
ALTER SEQUENCE eventos.reserva_reserva_id_seq RESTART WITH 1;
ALTER SEQUENCE eventos.reserva_detalle_detalle_id_seq RESTART WITH 1;
ALTER SEQUENCE eventos.log_intentos_reserva_log_id_seq RESTART WITH 1;

-- Insertar datos de eventos
INSERT INTO eventos.evento (nombre, descripcion, fecha_inicio, fecha_fin, lugar, capacidad_total)
VALUES 
('Concierto Primavera', 'Gran concierto de música clásica', '2025-05-15 19:00:00', '2025-05-15 23:00:00', 'Auditorio Nacional', 500),
('Festival de Jazz', 'Festival anual de jazz', '2025-06-20 16:00:00', '2025-06-22 23:00:00', 'Parque Central', 1000);

-- Insertar tipos de asiento
INSERT INTO eventos.tipo_asiento (nombre, descripcion, precio)
VALUES 
('VIP', 'Asientos preferenciales con mejor vista', 200.00),
('Platea', 'Asientos centrales con buena visibilidad', 120.00),
('General', 'Asientos generales', 80.00);

-- Insertar secciones para el evento "Concierto Primavera"
INSERT INTO eventos.seccion (evento_id, nombre, tipo_asiento_id, capacidad)
VALUES 
(1, 'Sección A', 1, 50),  -- VIP
(1, 'Sección B', 2, 150), -- Platea
(1, 'Sección C', 3, 300); -- General

-- Insertar asientos para la Sección A (VIP) del Concierto Primavera - Filas A-E
DO $$
DECLARE
    v_ascii INTEGER;
    v_fila CHAR(1);
    v_numero INTEGER;
BEGIN
    FOR v_ascii IN 65..69 LOOP  -- A to E
        v_fila := CHR(v_ascii);
        FOR v_numero IN 1..10 LOOP
            INSERT INTO eventos.asiento (seccion_id, fila, numero, estado)
            VALUES (1, v_fila, v_numero::TEXT, 'DISPONIBLE');
        END LOOP;
    END LOOP;
END $$;

-- Insertar asientos para la Sección B (Platea) del Concierto Primavera - Filas F-J
DO $$
DECLARE
    v_ascii INTEGER;
    v_fila CHAR(1);
    v_numero INTEGER;
BEGIN
    FOR v_ascii IN 70..74 LOOP  -- F to J
        v_fila := CHR(v_ascii);
        FOR v_numero IN 1..30 LOOP
            INSERT INTO eventos.asiento (seccion_id, fila, numero, estado)
            VALUES (2, v_fila, v_numero::TEXT, 'DISPONIBLE');
        END LOOP;
    END LOOP;
END $$;

-- Insertar asientos para la Sección C (General) del Concierto Primavera - Filas K-T
DO $$
DECLARE
    v_ascii INTEGER;
    v_fila CHAR(1);
    v_numero INTEGER;
BEGIN
    FOR v_ascii IN 75..84 LOOP  -- K to T
        v_fila := CHR(v_ascii);
        FOR v_numero IN 1..30 LOOP
            INSERT INTO eventos.asiento (seccion_id, fila, numero, estado)
            VALUES (3, v_fila, v_numero::TEXT, 'DISPONIBLE');
        END LOOP;
    END LOOP;
END $$;

-- Insertar usuarios para las pruebas
INSERT INTO eventos.usuario (nombre, apellido, email, telefono)
VALUES
('Juan', 'Pérez', 'juan.perez@email.com', '5551234001'),
('María', 'González', 'maria.gonzalez@email.com', '5551234002'),
('Carlos', 'López', 'carlos.lopez@email.com', '5551234003'),
('Ana', 'Martínez', 'ana.martinez@email.com', '5551234004'),
('Pedro', 'Sánchez', 'pedro.sanchez@email.com', '5551234005'),
('Laura', 'Rodríguez', 'laura.rodriguez@email.com', '5551234006'),
('Javier', 'Díaz', 'javier.diaz@email.com', '5551234007'),
('Sofía', 'Torres', 'sofia.torres@email.com', '5551234008'),
('Miguel', 'Ramírez', 'miguel.ramirez@email.com', '5551234009'),
('Carmen', 'Flores', 'carmen.flores@email.com', '5551234010'),
('Roberto', 'Vargas', 'roberto.vargas@email.com', '5551234011'),
('Patricia', 'Luna', 'patricia.luna@email.com', '5551234012'),
('Alejandro', 'Ortiz', 'alejandro.ortiz@email.com', '5551234013'),
('Isabel', 'Núñez', 'isabel.nunez@email.com', '5551234014'),
('Fernando', 'Mendoza', 'fernando.mendoza@email.com', '5551234015'),
('Gabriela', 'Castro', 'gabriela.castro@email.com', '5551234016'),
('Daniel', 'Herrera', 'daniel.herrera@email.com', '5551234017'),
('Lucía', 'Silva', 'lucia.silva@email.com', '5551234018'),
('Ricardo', 'Cordero', 'ricardo.cordero@email.com', '5551234019'),
('Verónica', 'Morales', 'veronica.morales@email.com', '5551234020'),
('Héctor', 'Navarro', 'hector.navarro@email.com', '5551234021'),
('Adriana', 'Romero', 'adriana.romero@email.com', '5551234022'),
('Eduardo', 'Campos', 'eduardo.campos@email.com', '5551234023'),
('Claudia', 'Ríos', 'claudia.rios@email.com', '5551234024'),
('Francisco', 'Vega', 'francisco.vega@email.com', '5551234025'),
('Mariana', 'Santos', 'mariana.santos@email.com', '5551234026'),
('Alberto', 'Miranda', 'alberto.miranda@email.com', '5551234027'),
('Susana', 'Cortés', 'susana.cortes@email.com', '5551234028'),
('José', 'Estrada', 'jose.estrada@email.com', '5551234029'),
('Teresa', 'Guzmán', 'teresa.guzman@email.com', '5551234030'),
('Antonio', 'Lara', 'antonio.lara@email.com', '5551234031'),
('Silvia', 'Mejía', 'silvia.mejia@email.com', '5551234032'),
('Guillermo', 'Delgado', 'guillermo.delgado@email.com', '5551234033'),
('Beatriz', 'Acosta', 'beatriz.acosta@email.com', '5551234034'),
('Salvador', 'Fuentes', 'salvador.fuentes@email.com', '5551234035'),
('Mónica', 'Pacheco', 'monica.pacheco@email.com', '5551234036'),
('Ernesto', 'Guerra', 'ernesto.guerra@email.com', '5551234037'),
('Alicia', 'Cervantes', 'alicia.cervantes@email.com', '5551234038'),
('Raúl', 'Medina', 'raul.medina@email.com', '5551234039'),
('Cristina', 'Valencia', 'cristina.valencia@email.com', '5551234040');

-- Reservas iniciales

-- Usuario 1 reserva asientos VIP
INSERT INTO eventos.reserva (usuario_id, estado, total_precio, metodo_pago, referencia_pago)
VALUES (1, 'CONFIRMADA', 400.00, 'TARJETA', 'REF123456');

UPDATE eventos.asiento SET estado = 'RESERVADO' WHERE seccion_id = 1 AND fila = 'A' AND numero IN ('1', '2');
INSERT INTO eventos.reserva_detalle (reserva_id, asiento_id, precio_unitario)
SELECT 1, asiento_id, 200.00
FROM eventos.asiento
WHERE seccion_id = 1 AND fila = 'A' AND numero IN ('1', '2');

-- Usuario 2 reserva asientos Platea
INSERT INTO eventos.reserva (usuario_id, estado, total_precio, metodo_pago, referencia_pago)
VALUES (2, 'CONFIRMADA', 240.00, 'TRANSFERENCIA', 'REF789012');

UPDATE eventos.asiento SET estado = 'RESERVADO' WHERE seccion_id = 2 AND fila = 'F' AND numero IN ('1', '2');
INSERT INTO eventos.reserva_detalle (reserva_id, asiento_id, precio_unitario)
SELECT 2, asiento_id, 120.00
FROM eventos.asiento
WHERE seccion_id = 2 AND fila = 'F' AND numero IN ('1', '2');

-- Usuario 3 reserva asientos Generales
INSERT INTO eventos.reserva (usuario_id, estado, total_precio, metodo_pago, referencia_pago)
VALUES (3, 'CONFIRMADA', 160.00, 'EFECTIVO', 'REF345678');

UPDATE eventos.asiento SET estado = 'RESERVADO' WHERE seccion_id = 3 AND fila = 'K' AND numero IN ('1', '2');
INSERT INTO eventos.reserva_detalle (reserva_id, asiento_id, precio_unitario)
SELECT 3, asiento_id, 80.00
FROM eventos.asiento
WHERE seccion_id = 3 AND fila = 'K' AND numero IN ('1', '2');

-- Finalizar transacción
COMMIT;