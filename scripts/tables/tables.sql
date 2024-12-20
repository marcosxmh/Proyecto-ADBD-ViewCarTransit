-- Tabla SEDE
CREATE TABLE SEDE (
    id_sede SERIAL PRIMARY KEY,
    nombre VARCHAR(50),
    localidad VARCHAR(50),
    calle VARCHAR(50),
    numero VARCHAR(10),
    telefono VARCHAR(20) CHECK (telefono ~ '^\d{3}-\d{3}-\d{3}$'),
    correo_contacto VARCHAR(50) CHECK (correo_contacto LIKE '%@%.%')
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
    correo_contacto VARCHAR(50) CHECK (correo_contacto LIKE '%@%.%'),
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
    estado VARCHAR(10) CHECK (estado IN ('Disponible', 'En Taller')),
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
    descripcion VARCHAR(255) NOT NULL,
    matricula VARCHAR(20) NOT NULL REFERENCES VEHICULO(matricula),
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