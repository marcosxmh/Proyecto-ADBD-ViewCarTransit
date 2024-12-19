-- Crear esquema
SET search_path TO public;

-- Tabla SEDE
CREATE TABLE SEDE (
    id_sede SERIAL PRIMARY KEY,
    nombre VARCHAR(50),
    localidad VARCHAR(50),
    calle VARCHAR(50),
    numero VARCHAR(10),
    telefono VARCHAR(20) CHECK (telefono ~ '^\d{3}-\d{3}-\d{3}$'),
    correo_contacto VARCHAR(50) CHECK (correo_contacto LIKE '%@%')
);

-- Tabla ENCARGADO
-- id_sede es UNIQUE, ya que solo trabaja un ENCARGADO por SEDE
CREATE TABLE ENCARGADO (
    dni VARCHAR(9) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellidos VARCHAR(50) NOT NULL,
    id_sede INT UNIQUE NOT NULL,
    FOREIGN KEY (id_sede) REFERENCES SEDE(id_sede) ON DELETE CASCADE
);

-- Tabla EMPRESA
-- El DELETE ON CASCADE, ya que cuando se elimina una sede, también se elimina la empresa
CREATE TABLE EMPRESA (
    id_empresa SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    tipo_empresa VARCHAR(50) NOT NULL,
    telefono VARCHAR(20) CHECK (telefono ~ '^\d{3}-\d{3}-\d{3}$'),
    correo_contacto VARCHAR(50) CHECK (correo_contacto LIKE '%@%'),
    id_sede INT NOT NULL,
    FOREIGN KEY (id_sede) REFERENCES SEDE(id_sede) ON DELETE CASCADE
);

-- Tabla TALLER
CREATE TABLE TALLER (
    id_taller SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    telefono VARCHAR(20) CHECK (telefono ~ '^\d{3}-\d{3}-\d{3}$'),
    localidad VARCHAR(50) NOT NULL,
    calle VARCHAR(50) NOT NULL,
    numero VARCHAR(10) NOT NULL
);

-- Tabla VEHICULO
CREATE TABLE VEHICULO (
    matricula VARCHAR(20) PRIMARY KEY,
    modelo VARCHAR(50) NOT NULL,
    color VARCHAR(20),
    estado VARCHAR(20) CHECK (estado IN ('Disponible', 'En Taller')),
    id_sede INT NOT NULL REFERENCES SEDE(id_sede),
    id_taller INT REFERENCES TALLER(id_taller)
);

-- Tabla INFORME
-- DELETE ON SET NULL, ya que aunque se elimine el taller, queremos mantener el informe
CREATE TABLE INFORME (
    id_informe SERIAL PRIMARY KEY,
    fecha DATE NOT NULL CHECK (fecha <= CURRENT_DATE),
    nombre VARCHAR(50) NOT NULL,
    apellidos VARCHAR(50) NOT NULL,
    id_taller INT REFERENCES TALLER(id_taller) ON DELETE SET NULL
);

-- Tabla PAQUETE
CREATE TABLE PAQUETE (
    id_paquete SERIAL PRIMARY KEY,
    descripcion VARCHAR(255),
    peso DECIMAL(10,2) NOT NULL CHECK (peso > 0),
    id_empresa INT NOT NULL,
    FOREIGN KEY (id_empresa) REFERENCES EMPRESA(id_empresa) ON DELETE CASCADE
);

-- Tabla CONDUCTOR
CREATE TABLE CONDUCTOR (
    dni VARCHAR(9) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellidos VARCHAR(50) NOT NULL,
    licencia VARCHAR(50) NOT NULL CHECK (licencia IN ('B', 'C', 'C+E'))
);

-- Tabla TEST
-- Si se elimina el conductor que se elimine su test
CREATE TABLE TEST (
    id_test SERIAL PRIMARY KEY,
    nota DECIMAL(5,2) NOT NULL CHECK (nota BETWEEN 0 AND 10),
    dni VARCHAR(9) NOT NULL,
    FOREIGN KEY (dni) REFERENCES CONDUCTOR(dni) ON DELETE CASCADE
);

-- Tabla FURGONETA
CREATE TABLE FURGONETA (
    porton_lateral BOOLEAN NOT NULL
) INHERITS (VEHICULO);

-- Tabla CAMION
CREATE TABLE CAMION (
    tiene_trailer BOOLEAN NOT NULL
) INHERITS (VEHICULO);

-- Tabla CONTRATO
CREATE TABLE CONTRATO (
    id_contrato SERIAL PRIMARY KEY,
    id_empresa INT NOT NULL,
    matricula VARCHAR(20) NOT NULL REFERENCES VEHICULO(matricula),
    fecha_ini DATE NOT NULL CHECK (fecha_ini <= fecha_fin),
    fecha_fin DATE NOT NULL CHECK (fecha_fin > CURRENT_DATE),
    FOREIGN KEY (id_empresa) REFERENCES EMPRESA(id_empresa) ON DELETE CASCADE
);

-- Relacion EMPRESA envia PAQUETE en VEHÍCULO (1:1:N)
CREATE TABLE ENVIA (
    matricula VARCHAR(20) NOT NULL REFERENCES VEHICULO(matricula),
    id_paquete INT NOT NULL,
    id_empresa INT NOT NULL,
    destino VARCHAR(100) NOT NULL,
    fecha DATE NOT NULL CHECK (fecha >= CURRENT_DATE),
    FOREIGN KEY (id_empresa) REFERENCES EMPRESA(id_empresa) ON DELETE CASCADE,
    FOREIGN KEY (id_paquete) REFERENCES PAQUETE(id_paquete) ON DELETE CASCADE,
    PRIMARY KEY (id_paquete)
);

-- Relacion CONDUCTOR conduce VEHICULO
CREATE TABLE CONDUCE (
    dni VARCHAR(9) NOT NULL,
    matricula VARCHAR(20) NOT NULL,
    FOREIGN KEY (dni) REFERENCES CONDUCTOR(dni) ON DELETE CASCADE,
    FOREIGN KEY (matricula) REFERENCES VEHICULO(matricula) ON DELETE CASCADE,
    PRIMARY KEY (dni, matricula)
);

-- Trigger para verificar disponibilidad del vehiculo al asignar contrato
CREATE OR REPLACE FUNCTION check_vehiculo_disponible()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT estado FROM VEHICULO WHERE matricula = NEW.matricula LIMIT 1) != 'Disponible' THEN
        RAISE EXCEPTION 'El vehiculo no esta disponible';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_vehiculo_disponible
BEFORE INSERT ON CONTRATO
FOR EACH ROW
EXECUTE FUNCTION check_vehiculo_disponible();

-- Comprobar que se contrata un vehículo que está disponible
CREATE OR REPLACE FUNCTION verificar_solapamiento_contrato()
RETURNS TRIGGER AS $$
BEGIN
    -- Verificar si hay un contrato existente para el mismo vehículo en el período solicitado
    IF EXISTS (
        SELECT 1
        FROM CONTRATO
        WHERE matricula = NEW.matricula
          AND fecha_fin >= NEW.fecha_ini
          AND fecha_ini <= NEW.fecha_fin
    ) THEN
        RAISE EXCEPTION 'El vehículo ya está en un contrato durante este período';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_verificar_solapamiento_contrato
BEFORE INSERT ON CONTRATO
FOR EACH ROW
EXECUTE FUNCTION verificar_solapamiento_contrato();

-- Trigger para asegurarnos de que la empresa está usando un coche que tienen contratado
CREATE OR REPLACE FUNCTION valida_envia_vehiculo()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM CONTRATO
        WHERE CONTRATO.id_empresa = NEW.id_empresa
          AND CONTRATO.matricula = NEW.matricula
          AND NEW.fecha BETWEEN CONTRATO.fecha_ini AND CONTRATO.fecha_fin
    ) THEN
        RAISE EXCEPTION 'La empresa no tiene contratado este vehículo para le fecha de reparto.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER verifica_contrato
BEFORE INSERT OR UPDATE ON ENVIA
FOR EACH ROW
EXECUTE FUNCTION valida_envia_vehiculo();

-- trigger para validar que el conductor ha pasado el test
CREATE OR REPLACE FUNCTION valida_test_conductor()
RETURNS TRIGGER AS $$
BEGIN
    -- Comprobar si el conductor tiene una nota >=5 en el test
    IF NOT EXISTS (
        SELECT 1
        FROM TEST
        WHERE TEST.dni = NEW.dni
          AND TEST.nota >= 5
    ) THEN
        RAISE EXCEPTION 'El conductor con DNI % no ha aprobado el test para nuestra empresa.', NEW.dni;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER verifica_test
BEFORE INSERT OR UPDATE ON CONDUCE
FOR EACH ROW
EXECUTE FUNCTION valida_test_conductor();

-- Trigger para reasignar un taller a los vehículos cuando un taller se elimina
CREATE OR REPLACE FUNCTION reasignar_taller_a_vehiculos()
RETURNS TRIGGER AS $$
DECLARE
    nuevo_taller INT;
BEGIN
    -- Obtener el ID de un taller activo
    SELECT id_taller
    INTO nuevo_taller
    FROM TALLER
    WHERE id_taller != OLD.id_taller
    LIMIT 1;

    -- Si se encuentra un taller activo, reasignar los vehículos
    IF nuevo_taller IS NOT NULL THEN
        UPDATE VEHICULO
        SET id_taller = nuevo_taller
        WHERE id_taller = OLD.id_taller;
    ELSE
        -- Si no hay talleres activos, poner a null
        UPDATE VEHICULO
        SET id_taller = NULL
        WHERE id_taller = OLD.id_taller;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_reasignar_taller
BEFORE DELETE ON TALLER
FOR EACH ROW
EXECUTE FUNCTION reasignar_taller_a_vehiculos();

-- Trigger para reasignar un vehículo cuando se elimina o pasa al taller, en la table ENVIA y CONTRATO
CREATE OR REPLACE FUNCTION reasignar_vehiculo()
RETURNS TRIGGER AS $$
DECLARE
    vehiculo_disponible VEHICULO%ROWTYPE;
BEGIN
    -- Seleccionamos un vehículo disponible que no tenga contrato activo
    SELECT matricula
    INTO vehiculo_disponible
    FROM VEHICULO v
    WHERE v.estado = 'Disponible'
    AND NOT EXISTS (
        SELECT 1
        FROM CONTRATO c
        WHERE c.matricula = v.matricula
        AND c.fecha_ini <= CURRENT_DATE
        AND c.fecha_fin >= CURRENT_DATE
    )
    LIMIT 1; -- Se asegura de obtener solo un vehículo

    -- Si encontramos un vehículo disponible sin contrato activo, actualizamos su estado
    IF FOUND THEN
        UPDATE CONTRATO
        SET matricula = vehiculo_disponible.matricula
        WHERE matricula = OLD.matricula;
        UPDATE ENVIA
        SET matricula = vehiculo_disponible.matricula
        WHERE matricula = OLD.matricula;
    END IF;

    RETURN NULL; -- No necesitamos hacer nada con la fila eliminada
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_reasignar_vehiculo
BEFORE DELETE ON VEHICULO
FOR EACH ROW
EXECUTE FUNCTION reasignar_vehiculo();
CREATE TRIGGER trigger_reasignar_vehiculo_en_taller
BEFORE UPDATE OF estado ON VEHICULO
FOR EACH ROW
EXECUTE FUNCTION reasignar_vehiculo();








-- Insertar datos iniciales
-- Datos en SEDE
INSERT INTO SEDE (nombre, localidad, calle, numero, telefono, correo_contacto)
VALUES ('Sede Central Tenerife', 'Tenerife', 'Los Majuelos', '100', '922-123-456', 'central@viewcartransit.com'),
       ('Sede Sur Tenerife', 'Adeje', 'Sur', '200', '922-456-789', 'sur@viewcartransit.com'),
       ('Sede Norte Tenerife', 'La Orotava', 'Norte', '300', '922-789-123', 'norte@viewcartransit.com');

-- Datos en ENCARGADO
INSERT INTO ENCARGADO (dni, nombre, apellidos, id_sede)
VALUES ('12345678A', 'Juan', 'Perez', 1),
       ('23456789B', 'Maria', 'Lopez', 2),
       ('34567890C', 'Pedro', 'Garcia', 3);

-- Datos en EMPRESA
INSERT INTO EMPRESA (nombre, tipo_empresa, telefono, correo_contacto, id_sede)
VALUES ('Supermercado La Colmena', 'Venta al por menor', '922-111-222', 'contacto@lacolmena.com', 1),
       ('Tienda ElectroMax', 'Venta al por menor', '922-222-333', 'info@electromax.com', 1),
       ('Moda y Complementos SRL', 'Venta al por menor', '922-333-444', 'ventas@modaycomplementos.com', 2),
       ('Jugueteria HappyKids', 'Venta al por menor', '922-444-555', 'contacto@happykids.com', 2),
       ('Hogar Decoracion', 'Venta al por menor', '922-555-666', 'info@hogardecoracion.com', 3);

-- Datos en TALLER
INSERT INTO TALLER (nombre, telefono, localidad, calle, numero)
VALUES ('Taller Central', '922-123-456', 'Los Majuelos', 'Central', '100'),
       ('Taller Sur', '922-456-789', 'Adeje', 'Sur', '200'),
       ('Taller Norte', '922-789-123', 'La Orotava', 'Norte', '300'),
       ('Taller Este', '922-123-456', 'Santa Cruz de Tenerife', 'Este', '400'),
       ('Taller Oeste', '922-456-789', 'Los Realejos', 'Oeste', '500'),
       ('Taller Paco', '922-111-111', 'Localidad 1', 'Calle 1', '101'),
       ('Taller Juan', '922-222-222', 'Localidad 2', 'Calle 2', '102'),
       ('Taller Maria', '922-333-333', 'Localidad 3', 'Calle 3', '103'),
       ('Taller Luis', '922-444-444', 'Localidad 4', 'Calle 4', '104'),
       ('Taller Ana', '922-555-555', 'Localidad 5', 'Calle 5', '105'),
       ('Taller Pedro', '922-666-666', 'Localidad 6', 'Calle 6', '106'),
       ('Taller Carmen', '922-777-777', 'Localidad 7', 'Calle 7', '107'),
       ('Taller Jose', '922-888-888', 'Localidad 8', 'Calle 8', '108'),
       ('Taller Laura', '922-999-999', 'Localidad 9', 'Calle 9', '109'),
       ('Taller Miguel', '922-000-000', 'Localidad 10', 'Calle 10', '110'),
       ('Taller Lucia', '922-111-222', 'Localidad 11', 'Calle 11', '111'),
       ('Taller Antonio', '922-222-333', 'Localidad 12', 'Calle 12', '112'),
       ('Taller Isabel', '922-333-444', 'Localidad 13', 'Calle 13', '113'),
       ('Taller Francisco', '922-444-555', 'Localidad 14', 'Calle 14', '114'),
       ('Taller Sofia', '922-555-666', 'Localidad 15', 'Calle 15', '115');

INSERT INTO VEHICULO (matricula, modelo, color, estado, id_sede, id_taller)
VALUES ('0000AAA', 'Renault Kangoo', 'Blanco', 'Disponible', 1, 1),
    ('0000AAB', 'Mercedes Sprinter', 'Azul', 'Disponible', 1, 2),
    ('0000AAC', 'Iveco Daily', 'Rojo', 'Disponible', 1, 2),
    ('0000AAD', 'Scania R450', 'Negro', 'Disponible', 1, 4),
    ('0000AAE', 'Volvo FH16', 'Gris', 'Disponible', 1, 5),
    ('0000AAF', 'Volkswagen Crafter', 'Verde', 'Disponible', 2, 2),
    ('0000AAG', 'Ford Transit', 'Blanco', 'Disponible', 1, 1),
    ('0000AAH', 'Peugeot Boxer', 'Azul', 'Disponible', 1, 2),
    ('0000AAI', 'Citroen Jumper', 'Rojo', 'Disponible', 1, 2),
    ('0000AAJ', 'Fiat Ducato', 'Negro', 'Disponible', 1, 4),
    ('0000AAK', 'Opel Movano', 'Gris', 'Disponible', 1, 5),
    ('0000AAL', 'Nissan NV400', 'Verde', 'Disponible', 1, 1),
    ('0000AAM', 'Renault Master', 'Blanco', 'Disponible', 1, 2),
    ('0000AAN', 'Mercedes Vito', 'Azul', 'Disponible', 1, 2),
    ('0000AAO', 'Volkswagen Transporter', 'Rojo', 'Disponible', 1, 4),
    ('0000AAP', 'Iveco Daily', 'Negro', 'Disponible', 1, 5),
    ('0000AAQ', 'Ford Transit Custom', 'Gris', 'Disponible', 1, 1),
    ('0000AAR', 'Peugeot Expert', 'Verde', 'Disponible', 1, 2),
    ('0000AAS', 'Citroen Dispatch', 'Blanco', 'Disponible', 1, 2),
    ('0000AAT', 'Fiat Talento', 'Azul', 'Disponible', 1, 4),
    ('0000AAU', 'Opel Vivaro', 'Rojo', 'Disponible', 1, 5),
    ('0000AAV', 'Nissan NV300', 'Negro', 'Disponible', 1, 1),
    ('0000AAW', 'Renault Trafic', 'Gris', 'Disponible', 1, 2),
    ('0000AAX', 'Mercedes Citan', 'Verde', 'Disponible', 1, 2),
    ('0000AAY', 'Volkswagen Caddy', 'Blanco', 'Disponible', 1, 4),
    ('0000AAZ', 'Iveco Eurocargo', 'Azul', 'Disponible', 1, 5),
    ('0000ABA', 'Ford Transit', 'Blanco', 'Disponible', 2, 6),
    ('0000ABB', 'Peugeot Boxer', 'Azul', 'Disponible', 2, 7),
    ('0000ABC', 'Citroen Jumper', 'Rojo', 'Disponible', 2, 8),
    ('0000ABD', 'Fiat Ducato', 'Negro', 'Disponible', 2, 9),
    ('0000ABE', 'Opel Movano', 'Gris', 'Disponible', 2, 10),
    ('0000ABF', 'Nissan NV400', 'Verde', 'Disponible', 2, 11),
    ('0000ABG', 'Renault Master', 'Blanco', 'Disponible', 2, 12),
    ('0000ABH', 'Mercedes Vito', 'Azul', 'Disponible', 2, 13),
    ('0000ABI', 'Volkswagen Transporter', 'Rojo', 'Disponible', 2, 14),
    ('0000ABJ', 'Iveco Daily', 'Negro', 'Disponible', 2, 15),
    ('0000ABK', 'Ford Transit Custom', 'Gris', 'Disponible', 2, 6),
    ('0000ABL', 'Peugeot Expert', 'Verde', 'Disponible', 2, 7),
    ('0000ABM', 'Citroen Dispatch', 'Blanco', 'Disponible', 2, 8),
    ('0000ABN', 'Fiat Talento', 'Azul', 'Disponible', 2, 9),
    ('0000ABO', 'Opel Vivaro', 'Rojo', 'Disponible', 2, 10),
    ('0000ABP', 'Nissan NV300', 'Negro', 'Disponible', 2, 11),
    ('0000ABQ', 'Renault Trafic', 'Gris', 'Disponible', 2, 12),
    ('0000ABR', 'Mercedes Citan', 'Verde', 'Disponible', 2, 13),
    ('0000ABS', 'Volkswagen Caddy', 'Blanco', 'Disponible', 2, 14),
    ('0000ABT', 'Iveco Eurocargo', 'Azul', 'Disponible', 2, 15),
    ('0000ABU', 'Ford Transit', 'Blanco', 'Disponible', 3, 6),
    ('0000ABV', 'Peugeot Boxer', 'Azul', 'Disponible', 3, 7),
    ('0000ABW', 'Citroen Jumper', 'Rojo', 'Disponible', 3, 8),
    ('0000ABX', 'Fiat Ducato', 'Negro', 'Disponible', 3, 9),
    ('0000ABY', 'Opel Movano', 'Gris', 'Disponible', 3, 10),
    ('0000ABZ', 'Nissan NV400', 'Verde', 'Disponible', 3, 11),
    ('0000ACA', 'Renault Master', 'Blanco', 'Disponible', 3, 12),
    ('0000ACB', 'Mercedes Vito', 'Azul', 'Disponible', 3, 13),
    ('0000ACC', 'Volkswagen Transporter', 'Rojo', 'Disponible', 3, 14),
    ('0000ACD', 'Iveco Daily', 'Negro', 'Disponible', 3, 15),
    ('0000ACE', 'Ford Transit Custom', 'Gris', 'Disponible', 3, 6),
    ('0000ACF', 'Peugeot Expert', 'Verde', 'Disponible', 3, 7),
    ('0000ACG', 'Citroen Dispatch', 'Blanco', 'Disponible', 3, 8),
    ('0000ACH', 'Fiat Talento', 'Azul', 'Disponible', 3, 9),
    ('0000ACI', 'Opel Vivaro', 'Rojo', 'Disponible', 3, 10),
    ('0000ACJ', 'Nissan NV300', 'Negro', 'Disponible', 3, 11),
    ('0000ACK', 'Renault Trafic', 'Gris', 'Disponible', 3, 12),
    ('0000ACL', 'Mercedes Citan', 'Verde', 'Disponible', 3, 13),
    ('0000ACM', 'Volkswagen Caddy', 'Blanco', 'Disponible', 3, 14),
    ('0000ACN', 'Iveco Eurocargo', 'Azul', 'Disponible', 3, 15);

-- Datos en FURGONETA
INSERT INTO FURGONETA (matricula, modelo, color, estado, id_sede, id_taller, porton_lateral)
VALUES ('0000AAA', 'Renault Kangoo', 'Blanco', 'Disponible', 1, 1, TRUE),
    ('0000AAB', 'Mercedes Sprinter', 'Azul', 'Disponible', 1, 2, FALSE),
    ('0000AAC', 'Iveco Daily', 'Rojo', 'Disponible', 1, 2, TRUE),
    ('0000AAD', 'Scania R450', 'Negro', 'Disponible', 1, 4, FALSE),
    ('0000AAE', 'Volvo FH16', 'Gris', 'Disponible', 1, 5, TRUE),
    ('0000AAF', 'Volkswagen Crafter', 'Verde', 'Disponible', 2, 2, FALSE),
    ('0000AAG', 'Ford Transit', 'Blanco', 'Disponible', 1, 1, TRUE),
    ('0000AAH', 'Peugeot Boxer', 'Azul', 'Disponible', 1, 2, FALSE),
    ('0000AAI', 'Citroen Jumper', 'Rojo', 'Disponible', 1, 2, TRUE),
    ('0000AAJ', 'Fiat Ducato', 'Negro', 'Disponible', 1, 4, FALSE),
    ('0000AAK', 'Opel Movano', 'Gris', 'Disponible', 1, 5, TRUE),
    ('0000AAL', 'Nissan NV400', 'Verde', 'Disponible', 1, 1, FALSE),
    ('0000AAM', 'Renault Master', 'Blanco', 'Disponible', 1, 2, TRUE),
    ('0000AAN', 'Mercedes Vito', 'Azul', 'Disponible', 1, 2, FALSE),
    ('0000AAO', 'Volkswagen Transporter', 'Rojo', 'Disponible', 1, 4, TRUE),
    ('0000AAP', 'Iveco Daily', 'Negro', 'Disponible', 1, 5, FALSE),
    ('0000AAQ', 'Ford Transit Custom', 'Gris', 'Disponible', 1, 1, TRUE),
    ('0000AAR', 'Peugeot Expert', 'Verde', 'Disponible', 1, 2, FALSE),
    ('0000AAS', 'Citroen Dispatch', 'Blanco', 'Disponible', 1, 2, TRUE),
    ('0000AAT', 'Fiat Talento', 'Azul', 'Disponible', 1, 4, FALSE),
    ('0000AAU', 'Opel Vivaro', 'Rojo', 'Disponible', 1, 5, TRUE),
    ('0000AAV', 'Nissan NV300', 'Negro', 'Disponible', 1, 1, FALSE),
    ('0000AAW', 'Renault Trafic', 'Gris', 'Disponible', 1, 2, TRUE),
    ('0000AAX', 'Mercedes Citan', 'Verde', 'Disponible', 1, 2, FALSE),
    ('0000AAY', 'Volkswagen Caddy', 'Blanco', 'Disponible', 1, 4, TRUE),
    ('0000AAZ', 'Iveco Eurocargo', 'Azul', 'Disponible', 1, 5, FALSE),
    ('0000ABA', 'Ford Transit', 'Blanco', 'Disponible', 2, 6, TRUE),
    ('0000ABB', 'Peugeot Boxer', 'Azul', 'Disponible', 2, 7, FALSE),
    ('0000ABC', 'Citroen Jumper', 'Rojo', 'Disponible', 2, 8, TRUE),
    ('0000ABD', 'Fiat Ducato', 'Negro', 'Disponible', 2, 9, FALSE),
    ('0000ABE', 'Opel Movano', 'Gris', 'Disponible', 2, 10, TRUE);

-- Datos en CAMION
INSERT INTO CAMION (matricula, modelo, color, estado, id_sede, id_taller, tiene_trailer)
VALUES ('0000ABF', 'Nissan NV400', 'Verde', 'Disponible', 2, 11, TRUE),
    ('0000ABG', 'Renault Master', 'Blanco', 'Disponible', 2, 12, FALSE),
    ('0000ABH', 'Mercedes Vito', 'Azul', 'Disponible', 2, 13, TRUE),
    ('0000ABI', 'Volkswagen Transporter', 'Rojo', 'Disponible', 2, 14, FALSE),
    ('0000ABJ', 'Iveco Daily', 'Negro', 'Disponible', 2, 15, TRUE),
    ('0000ABK', 'Ford Transit Custom', 'Gris', 'Disponible', 2, 6, FALSE),
    ('0000ABL', 'Peugeot Expert', 'Verde', 'Disponible', 2, 7, TRUE),
    ('0000ABM', 'Citroen Dispatch', 'Blanco', 'Disponible', 2, 8, FALSE),
    ('0000ABN', 'Fiat Talento', 'Azul', 'Disponible', 2, 9, TRUE),
    ('0000ABO', 'Opel Vivaro', 'Rojo', 'Disponible', 2, 10, FALSE),
    ('0000ABP', 'Nissan NV300', 'Negro', 'Disponible', 2, 11, TRUE),
    ('0000ABQ', 'Renault Trafic', 'Gris', 'Disponible', 2, 12, FALSE),
    ('0000ABR', 'Mercedes Citan', 'Verde', 'Disponible', 2, 13, TRUE),
    ('0000ABS', 'Volkswagen Caddy', 'Blanco', 'Disponible', 2, 14, FALSE),
    ('0000ABT', 'Iveco Eurocargo', 'Azul', 'Disponible', 2, 15, TRUE),
    ('0000ABU', 'Ford Transit', 'Blanco', 'Disponible', 3, 6, FALSE),
    ('0000ABV', 'Peugeot Boxer', 'Azul', 'Disponible', 3, 7, TRUE),
    ('0000ABW', 'Citroen Jumper', 'Rojo', 'Disponible', 3, 8, FALSE),
    ('0000ABX', 'Fiat Ducato', 'Negro', 'Disponible', 3, 9, TRUE),
    ('0000ABY', 'Opel Movano', 'Gris', 'Disponible', 3, 10, FALSE),
    ('0000ABZ', 'Nissan NV400', 'Verde', 'Disponible', 3, 11, TRUE),
    ('0000ACA', 'Renault Master', 'Blanco', 'Disponible', 3, 12, FALSE),
    ('0000ACB', 'Mercedes Vito', 'Azul', 'Disponible', 3, 13, TRUE),
    ('0000ACC', 'Volkswagen Transporter', 'Rojo', 'Disponible', 3, 14, FALSE),
    ('0000ACD', 'Iveco Daily', 'Negro', 'Disponible', 3, 15, TRUE),
    ('0000ACE', 'Ford Transit Custom', 'Gris', 'Disponible', 3, 6, FALSE),
    ('0000ACF', 'Peugeot Expert', 'Verde', 'Disponible', 3, 7, TRUE),
    ('0000ACG', 'Citroen Dispatch', 'Blanco', 'Disponible', 3, 8, FALSE),
    ('0000ACH', 'Fiat Talento', 'Azul', 'Disponible', 3, 9, TRUE),
    ('0000ACI', 'Opel Vivaro', 'Rojo', 'Disponible', 3, 10, FALSE),
    ('0000ACJ', 'Nissan NV300', 'Negro', 'Disponible', 3, 11, TRUE),
    ('0000ACK', 'Renault Trafic', 'Gris', 'Disponible', 3, 12, FALSE),
    ('0000ACL', 'Mercedes Citan', 'Verde', 'Disponible', 3, 13, TRUE),
    ('0000ACM', 'Volkswagen Caddy', 'Blanco', 'Disponible', 3, 14, FALSE),
    ('0000ACN', 'Iveco Eurocargo', 'Azul', 'Disponible', 3, 15, TRUE);

-- Datos en CONTRATO
INSERT INTO CONTRATO(id_empresa, matricula, fecha_ini, fecha_fin)
VALUES (1, '0000AAA', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
    (2, '0000AAB', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
    (3, '0000AAC', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
    (4, '0000AAD', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
    (5, '0000AAE', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
    (1, '0000AAF', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
    (2, '0000AAG', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
    (3, '0000AAH', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
    (4, '0000AAI', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
    (5, '0000AAJ', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
    (1, '0000AAK', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
    (2, '0000AAL', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
    (3, '0000AAM', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
    (4, '0000AAN', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
    (5, '0000AAO', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
    (1, '0000AAP', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
    (2, '0000AAQ', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
    (3, '0000AAR', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
    (4, '0000AAS', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
    (5, '0000AAT', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month');
INSERT INTO CONTRATO(id_empresa, matricula, fecha_ini, fecha_fin)
VALUES (4, '0000AAD', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '1 day', CURRENT_DATE + INTERVAL '2 months'),
    (5, '0000AAE', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '1 day', CURRENT_DATE + INTERVAL '2 months'),
    (1, '0000AAF', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '1 day', CURRENT_DATE + INTERVAL '2 months'),
    (2, '0000AAG', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '1 day', CURRENT_DATE + INTERVAL '2 months'),
    (3, '0000AAH', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '1 day', CURRENT_DATE + INTERVAL '2 months');

-- Datos en PAQUETE
INSERT INTO PAQUETE (descripcion, peso, id_empresa)
VALUES ('Televisor LED 55 pulgadas', 15.00, 1),
    ('Ropa de invierno para niños', 10.50, 2),
    ('Set de muebles de jardin', 80.00, 3),
    ('Juguetes educativos', 12.30, 4),
    ('Decoracion para el hogar', 25.00, 5),
    ('Laptop Ultrabook', 2.50, 1),
    ('Refrigerador 300L', 50.00, 2),
    ('Juego de sabanas premium', 5.00, 3),
    ('Set de herramientas electricas', 18.00, 4),
    ('Cafetera de ultima generacion', 4.50, 5),
    ('Aspiradora robot', 3.00, 1),
    ('Bicicleta de montaña', 12.00, 2),
    ('Consola de videojuegos', 4.00, 3),
    ('Cámara fotográfica', 1.50, 4),
    ('Smartphone de última generación', 0.20, 5),
    ('Tablet 10 pulgadas', 0.50, 1),
    ('Impresora multifunción', 8.00, 2),
    ('Microondas', 12.00, 3),
    ('Lavadora', 60.00, 4),
    ('Secadora', 55.00, 5),
    ('Televisor LED 55 pulgadas', 15.00, 1),
    ('Ropa de invierno para niños', 10.50, 2),
    ('Set de muebles de jardin', 80.00, 3),
    ('Juguetes educativos', 12.30, 4),
    ('Decoracion para el hogar', 25.00, 5),
    ('Laptop Ultrabook', 2.50, 1),
    ('Refrigerador 300L', 50.00, 2),
    ('Juego de sabanas premium', 5.00, 3),
    ('Set de herramientas electricas', 18.00, 4),
    ('Cafetera de ultima generacion', 4.50, 5),
    ('Aspiradora robot', 3.00, 1),
    ('Bicicleta de montaña', 12.00, 2),
    ('Consola de videojuegos', 4.00, 3),
    ('Cámara fotográfica', 1.50, 4),
    ('Smartphone de última generación', 0.20, 5),
    ('Tablet 10 pulgadas', 0.50, 1),
    ('Impresora multifunción', 8.00, 2),
    ('Microondas', 12.00, 3),
    ('Lavadora', 60.00, 4),
    ('Secadora', 55.00, 5);

-- Datos en ENVIA
INSERT INTO ENVIA (matricula, id_paquete, id_empresa, destino, fecha)
VALUES ('0000AAA', 1, 1, 'Santa Cruz de Tenerife', CURRENT_DATE + INTERVAL '1 day'),
    ('0000AAB', 2, 2, 'La Laguna', CURRENT_DATE + INTERVAL '2 days'),
    ('0000AAC', 3, 3, 'Puerto de la Cruz', CURRENT_DATE + INTERVAL '3 days'),
    ('0000AAD', 4, 4, 'Arona', CURRENT_DATE + INTERVAL '4 days'),
    ('0000AAE', 5, 5, 'Granadilla', CURRENT_DATE + INTERVAL '5 days'),
    ('0000AAF', 6, 1, 'Adeje', CURRENT_DATE + INTERVAL '6 days'),
    ('0000AAG', 7, 2, 'La Orotava', CURRENT_DATE + INTERVAL '7 days'),
    ('0000AAH', 8, 3, 'Icod de los Vinos', CURRENT_DATE + INTERVAL '8 days'),
    ('0000AAI', 9, 4, 'Los Realejos', CURRENT_DATE + INTERVAL '9 days'),
    ('0000AAJ', 10, 5, 'Güímar', CURRENT_DATE + INTERVAL '10 days'),
    ('0000AAK', 11, 1, 'Santa Cruz de Tenerife', CURRENT_DATE + INTERVAL '11 days'),
    ('0000AAL', 12, 2, 'La Laguna', CURRENT_DATE + INTERVAL '12 days'),
    ('0000AAM', 13, 3, 'Puerto de la Cruz', CURRENT_DATE + INTERVAL '13 days'),
    ('0000AAN', 14, 4, 'Arona', CURRENT_DATE + INTERVAL '14 days'),
    ('0000AAO', 15, 5, 'Granadilla', CURRENT_DATE + INTERVAL '15 days'),
    ('0000AAP', 16, 1, 'Adeje', CURRENT_DATE + INTERVAL '16 days'),
    ('0000AAQ', 17, 2, 'La Orotava', CURRENT_DATE + INTERVAL '17 days'),
    ('0000AAR', 18, 3, 'Icod de los Vinos', CURRENT_DATE + INTERVAL '18 days'),
    ('0000AAS', 19, 4, 'Los Realejos', CURRENT_DATE + INTERVAL '19 days'),
    ('0000AAT', 20, 5, 'Güímar', CURRENT_DATE + INTERVAL '20 days'),
    ('0000AAF', 21, 1, 'Santa Cruz de Tenerife', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '21 days'),
    ('0000AAG', 22, 2, 'La Laguna', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '22 days'),
    ('0000AAH', 23, 3, 'Puerto de la Cruz', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '23 days'),
    ('0000AAD', 24, 4, 'Arona', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '24 days'),
    ('0000AAE', 25, 5, 'Granadilla', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '25 days'),
    ('0000AAF', 26, 1, 'Adeje', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '26 days'),
    ('0000AAG', 27, 2, 'La Orotava', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '27 days'),
    ('0000AAH', 28, 3, 'Icod de los Vinos', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '28 days'),
    ('0000AAD', 29, 4, 'Los Realejos', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '29 days'),
    ('0000AAE', 30, 5, 'Güímar', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '30 days');

-- Datos en CONDUCTOR
INSERT INTO CONDUCTOR (dni, nombre, apellidos, licencia)
VALUES ('12345678A', 'Juan', 'Perez', 'B'),
       ('23456789B', 'Maria', 'Lopez', 'C'),
       ('34567890C', 'Pedro', 'Garcia', 'C+E'),
       ('45678901D', 'Laura', 'Martinez', 'B'),
       ('56789012E', 'Carlos', 'Sanchez', 'C'),
       ('67890123F', 'Ana', 'Gonzalez', 'C+E');

-- Datos en TEST
INSERT INTO TEST (nota, dni)
VALUES (8.50, '12345678A'),
    (7.00, '23456789B'),
    (9.00, '34567890C'),
    (6.50, '45678901D'),
    (8.00, '56789012E'),
    (5.50, '67890123F');

-- Datos en CONDUCE
INSERT INTO CONDUCE (dni, matricula)
VALUES ('12345678A', '0000AAA'),
    ('12345678A', '0000AAB'),
    ('23456789B', '0000AAC'),
    ('23456789B', '0000AAD'),
    ('34567890C', '0000AAE'),
    ('34567890C', '0000AAF'),
    ('45678901D', '0000AAG'),
    ('45678901D', '0000AAH'),
    ('56789012E', '0000AAI'),
    ('56789012E', '0000AAJ'),
    ('67890123F', '0000AAK'),
    ('67890123F', '0000AAL'),
    ('12345678A', '0000AAM'),
    ('23456789B', '0000AAN'),
    ('34567890C', '0000AAO');

-- Datos en INFORME
INSERT INTO INFORME (fecha, nombre, apellidos, id_taller)
VALUES (CURRENT_DATE, 'Juan', 'Perez', 1),
    (CURRENT_DATE, 'Maria', 'Lopez', 2),
    (CURRENT_DATE, 'Pedro', 'Garcia', 3),
    (CURRENT_DATE, 'Laura', 'Martinez', 4),
    (CURRENT_DATE, 'Carlos', 'Sanchez', 5),
    (CURRENT_DATE, 'Ana', 'Gonzalez', 6);

-- Final: Confirmar esquema
COMMENT ON SCHEMA public IS 'Esquema para la gestion de flotas de vehiculos de empresas clientes';