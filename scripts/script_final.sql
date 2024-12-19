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
CREATE TABLE ENCARGADO (
    dni VARCHAR(9) PRIMARY KEY,
    nombre VARCHAR(50),
    apellidos VARCHAR(50),
    id_sede INT REFERENCES SEDE(id_sede) DELETE ON CASCADE
);

-- Tabla EMPRESA
-- El DELETE ON CASCADE, ya que cuando se elimina una sede, también se elimina la empresa
CREATE TABLE EMPRESA (
    id_empresa SERIAL PRIMARY KEY,
    nombre VARCHAR(50),
    tipo_empresa VARCHAR(50),
    telefono VARCHAR(20) CHECK (telefono ~ '^\d{3}-\d{3}-\d{3}$'),
    correo_contacto VARCHAR(50) CHECK (correo_contacto LIKE '%@%'),
    id_sede INT REFERENCES SEDE(id_sede) DELETE ON CASCADE
);

-- Tabla TALLER
CREATE TABLE TALLER (
    id_taller SERIAL PRIMARY KEY,
    nombre VARCHAR(50),
    telefono VARCHAR(20) CHECK (telefono ~ '^\d{3}-\d{3}-\d{3}$'),
    localidad VARCHAR(50),
    calle VARCHAR(50),
    numero VARCHAR(10)
);

-- Tabla VEHICULO
CREATE TABLE VEHICULO (
    matricula VARCHAR(20) PRIMARY KEY,
    modelo VARCHAR(50),
    color VARCHAR(20),
    estado VARCHAR(20) CHECK (estado IN ('Disponible', 'No disponible', 'En taller')),
    id_sede INT REFERENCES SEDE(id_sede),
    id_taller INT REFERENCES TALLER(id_taller)
);

-- Tabla INFORME
CREATE TABLE INFORME (
    id_informe SERIAL PRIMARY KEY,
    fecha DATE CHECK (fecha <= CURRENT_DATE),
    nombre VARCHAR(50),
    apellidos VARCHAR(50),
    id_taller INT REFERENCES TALLER(id_taller)
);

-- Tabla PAQUETE
CREATE TABLE PAQUETE (
    id_paquete SERIAL PRIMARY KEY,
    descripcion VARCHAR(255),
    peso DECIMAL(10,2) CHECK (peso > 0)
);

-- Tabla CONDUCTOR
CREATE TABLE CONDUCTOR (
    dni VARCHAR(9) PRIMARY KEY,
    nombre VARCHAR(50),
    apellidos VARCHAR(50),
    licencia VARCHAR(50)
);

-- Tabla TEST
CREATE TABLE TEST (
    id_test SERIAL PRIMARY KEY,
    nota DECIMAL(5,2) CHECK (nota BETWEEN 0 AND 10),
    dni VARCHAR(9) REFERENCES CONDUCTOR(dni)
);

-- Tabla FURGONETA
CREATE TABLE FURGONETA (
    porton_lateral BOOLEAN,
) INHERITS (VEHICULO);

-- Tabla CAMION
CREATE TABLE CAMION (
    tiene_trailer BOOLEAN,
) INHERITS (VEHICULO);

-- Relacion EMPRESA contrata VEHICULO (1:N)
CREATE TABLE CONTRATA (
    id_empresa INT REFERENCES EMPRESA(id_empresa),
    matricula VARCHAR(20) REFERENCES VEHICULO(matricula),
    fecha_ini DATE CHECK (fecha_ini <= fecha_fin),
    fecha_fin DATE CHECK (fecha_fin > CURRENT_DATE),
    PRIMARY KEY (id_empresa, matricula)
);

-- Relacion EMPRESA envia PAQUETE en VEHÍCULO (1:M:N)
CREATE TABLE ENVIA (
    matricula VARCHAR(20) REFERENCES VEHICULO(matricula),
    id_paquete INT REFERENCES PAQUETE(id_paquete),
    id_empresa INT REFERENCES EMPRESA(id_empresa),
    destino VARCHAR(100),
    fecha DATE CHECK (fecha >= CURRENT_DATE),
    PRIMARY KEY (matricula, id_paquete)
);

-- Relacion CONDUCTOR conduce VEHICULO (1:1)
CREATE TABLE CONDUCE (
    dni VARCHAR(20) REFERENCES CONDUCTOR(dni),
    matricula VARCHAR(20) REFERENCES VEHICULO(matricula),
    PRIMARY KEY (dni, matricula)
);

-- Trigger para verificar disponibilidad del vehiculo al asignar conductor
CREATE OR REPLACE FUNCTION check_vehiculo_disponible()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT estado FROM VEHICULO WHERE matricula = NEW.matricula) != 'Disponible' THEN
        RAISE EXCEPTION 'El vehiculo no esta disponible';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_vehiculo_disponible
BEFORE INSERT ON CONTRATA
FOR EACH ROW
EXECUTE FUNCTION check_vehiculo_disponible();

-- Trigger para asegurarnos de que la empresa está usando un coche que tienen contratado
CREATE OR REPLACE FUNCTION valida_envia_vehiculo()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM CONTRATA
        WHERE CONTRATA.id_empresa = NEW.id_empresa
          AND CONTRATA.matricula = NEW.matricula
          AND NEW.fecha BETWEEN CONTRATA.fecha_ini AND CONTRATA.fecha_fin
    ) THEN
        RAISE EXCEPTION 'La empresa no tiene contratado este vehículo para le fecha de reparto.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER verifica_contrata
BEFORE INSERT OR UPDATE ON ENVIA
FOR EACH ROW
EXECUTE FUNCTION valida_envia_vehiculo();

-- Función para validar que el conductor ha pasado el test
CREATE OR REPLACE FUNCTION valida_test_conductor()
RETURNS TRIGGER AS $$
BEGIN
    -- Comprobar si el conductor tiene una nota aprobatoria en el test
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

-- Crear el trigger en la tabla CONDUCE
CREATE TRIGGER verifica_test
BEFORE INSERT OR UPDATE ON CONDUCE
FOR EACH ROW
EXECUTE FUNCTION valida_test_conductor();





-- Insertar datos iniciales
-- Datos en SEDE
INSERT INTO SEDE (nombre, localidad, calle, numero, telefono, correo_contacto)
VALUES ('Sede Central Tenerife', 'Tenerife', 'Los Majuelos', '100', '922-123-456', 'central@viewcartransit.com'),
       ('Sede Sur Tenerife', 'Adeje', 'Sur', '200', '922-456-789', 'sur@viewcartransit.com'),
       ('Sede Norte Tenerife', 'La Orotava', 'Norte', '300', '922-789-123', 'norte@viewcartransit.com');

-- Datos en EMPRESA
INSERT INTO EMPRESA (nombre, tipo_empresa, telefono, correo_contacto)
VALUES ('Supermercado La Colmena', 'Venta al por menor', '922-111-222', 'contacto@lacolmena.com'),
       ('Tienda ElectroMax', 'Venta al por menor', '922-222-333', 'info@electromax.com'),
       ('Moda y Complementos SRL', 'Venta al por menor', '922-333-444', 'ventas@modaycomplementos.com'),
       ('Jugueteria HappyKids', 'Venta al por menor', '922-444-555', 'contacto@happykids.com'),
       ('Hogar Decoracion', 'Venta al por menor', '922-555-666', 'info@hogardecoracion.com');

-- Datos en VEHICULO
INSERT INTO VEHICULO (matricula, modelo, color, estado)
VALUES ('TF-1001-AA', 'Renault Kangoo', 'Blanco', 'Disponible'),
       ('TF-2002-BB', 'Mercedes Sprinter', 'Azul', 'Disponible'),
       ('TF-3003-CC', 'Iveco Daily', 'Rojo', 'Disponible'),
       ('TF-4004-DD', 'Scania R450', 'Negro', 'Disponible'),
       ('TF-5005-EE', 'Volvo FH16', 'Gris', 'Disponible'),
       ('TF-6006-FF', 'Volkswagen Crafter', 'Verde', 'Disponible');

-- Datos en PAQUETE
INSERT INTO PAQUETE (descripcion, peso)
VALUES ('Televisor LED 55 pulgadas', 15.00),
       ('Ropa de invierno para niños', 10.50),
       ('Set de muebles de jardin', 80.00),
       ('Juguetes educativos', 12.30),
       ('Decoracion para el hogar', 25.00),
       ('Laptop Ultrabook', 2.50),
       ('Refrigerador 300L', 50.00),
       ('Juego de sabanas premium', 5.00),
       ('Set de herramientas electricas', 18.00),
       ('Cafetera de ultima generacion', 4.50);

-- Datos en CONDUCTOR
INSERT INTO CONDUCTOR (dni, nombre, apellidos, licencia)
VALUES ('12345678A', 'Juan', 'Perez', 'B'),
       ('23456789B', 'Maria', 'Lopez', 'C'),
       ('34567890C', 'Pedro', 'Garcia', 'C+E'),
       ('45678901D', 'Laura', 'Martinez', 'B'),
       ('56789012E', 'Carlos', 'Sanchez', 'C'),
       ('67890123F', 'Ana', 'Gonzalez', 'C+E');

-- Datos en CONDUCE
INSERT INTO CONDUCE (dni, matricula)
VALUES ('12345678A', 'TF-1001-AA'),
       ('23456789B', 'TF-2002-BB'),
       ('34567890C', 'TF-3003-CC'),
       ('45678901D', 'TF-5005-EE'),
       ('56789012E', 'TF-6006-FF');

-- Datos en CONTRATA
INSERT INTO CONTRATA (id_empresa, matricula, fecha_ini, fecha_fin)
VALUES (1, 'TF-1001-AA', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
       (2, 'TF-2002-BB', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
       (3, 'TF-3003-CC', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
       (4, 'TF-4004-DD', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
       (5, 'TF-5005-EE', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'),
       (1, 'TF-6006-FF', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month');
-- Datos en ENVIA
INSERT INTO ENVIA (matricula, id_paquete, id_empresa, destino, fecha)
VALUES ('TF-1001-AA', 1, 1, 'Santa Cruz de Tenerife', CURRENT_DATE + INTERVAL '1 day'),
       ('TF-2002-BB', 2, 2, 'La Laguna', CURRENT_DATE + INTERVAL '2 days'),
       ('TF-3003-CC', 3, 3, 'Puerto de la Cruz', CURRENT_DATE + INTERVAL '3 days'),
       ('TF-4004-DD', 4, 4, 'Arona', CURRENT_DATE + INTERVAL '4 days'),
       ('TF-5005-EE', 5, 5, 'Granadilla', CURRENT_DATE + INTERVAL '5 days'),
       ('TF-1001-AA', 6, 1, 'Adeje', CURRENT_DATE + INTERVAL '6 days'),
       ('TF-2002-BB', 7, 2, 'La Orotava', CURRENT_DATE + INTERVAL '7 days'),
       ('TF-3003-CC', 8, 3, 'Icod de los Vinos', CURRENT_DATE + INTERVAL '8 days'),
       ('TF-4004-DD', 9, 4, 'Los Realejos', CURRENT_DATE + INTERVAL '9 days'),
       ('TF-5005-EE', 10, 5, 'Güímar', CURRENT_DATE + INTERVAL '10 days');

-- Final: Confirmar esquema
COMMENT ON SCHEMA public IS 'Esquema para la gestion de flotas de vehiculos de empresas clientes';