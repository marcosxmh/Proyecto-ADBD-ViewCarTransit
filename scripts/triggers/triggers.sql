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

-- Trigger para reasignar una furgoneta cuando se elimina o pasa al taller, en la table ENVIA y CONTRATO
CREATE OR REPLACE FUNCTION reasignar_furgoneta()
RETURNS TRIGGER AS $$
DECLARE
    furgoneta_disponible FURGONETA%ROWTYPE;
BEGIN
    -- Seleccionamos un vehículo disponible que no tenga contrato activo
    SELECT matricula
    INTO furgoneta_disponible
    FROM FURGONETA f
    WHERE f.estado = 'Disponible'
    AND NOT EXISTS (
        SELECT 1
        FROM CONTRATO c
        WHERE c.matricula = f.matricula
        AND f.porton_lateral = OLD.porton_lateral
        AND c.fecha_ini <= CURRENT_DATE
        AND c.fecha_fin >= CURRENT_DATE
    )
    LIMIT 1; -- Se asegura de obtener solo un vehículo

    -- Si encontramos un vehículo disponible sin contrato activo, actualizamos su estado
    IF FOUND THEN
        UPDATE CONTRATO
        SET matricula = furgoneta_disponible.matricula
        WHERE matricula = OLD.matricula;
        UPDATE ENVIA
        SET matricula = furgoneta_disponible.matricula
        WHERE matricula = OLD.matricula;
        
    END IF;

    RETURN NULL; -- No necesitamos hacer nada con la fila eliminada
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_reasignar_furgoneta
AFTER DELETE ON FURGONETA
FOR EACH ROW
EXECUTE FUNCTION reasignar_furgoneta();
CREATE TRIGGER trigger_reasignar_furgoneta_en_taller
AFTER UPDATE OF estado ON FURGONETA
FOR EACH ROW
EXECUTE FUNCTION reasignar_furgoneta();

-- Trigger para reasignar un camion cuando se elimina o pasa al taller, en la table ENVIA y CONTRATO
CREATE OR REPLACE FUNCTION reasignar_camion()
RETURNS TRIGGER AS $$
DECLARE
    camion_disponible CAMION%ROWTYPE;
BEGIN
    -- Seleccionamos un vehículo disponible que no tenga contrato activo
    SELECT matricula
    INTO camion_disponible
    FROM CAMION ca
    WHERE ca.estado = 'Disponible'
    AND NOT EXISTS (
        SELECT 1
        FROM CONTRATO c
        WHERE c.matricula = ca.matricula
        AND ca.tiene_trailer = OLD.tiene_trailer
        AND c.fecha_ini <= CURRENT_DATE
        AND c.fecha_fin >= CURRENT_DATE
    )
    LIMIT 1; -- Se asegura de obtener solo un vehículo

    -- Si encontramos un vehículo disponible sin contrato activo, actualizamos su estado
    IF FOUND THEN
        UPDATE CONTRATO
        SET matricula = camion_disponible.matricula
        WHERE matricula = OLD.matricula;
        UPDATE ENVIA
        SET matricula = camion_disponible.matricula
        WHERE matricula = OLD.matricula;
        
    END IF;

    RETURN NULL; -- No necesitamos hacer nada con la fila eliminada
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_reasignar_camion
AFTER DELETE ON CAMION
FOR EACH ROW
EXECUTE FUNCTION reasignar_camion();
CREATE TRIGGER trigger_reasignar_camion_en_taller
AFTER UPDATE OF estado ON CAMION
FOR EACH ROW
EXECUTE FUNCTION reasignar_camion();

-- Trigger Vehículo solo puede pertenecer a una sede
CREATE OR REPLACE FUNCTION verificar_sede_vehiculo()
RETURNS TRIGGER AS $$
BEGIN
    -- Verificamos si el vehículo ya está asociado a otra sede
    IF EXISTS (
        SELECT 1 
        FROM VEHICULO v 
        WHERE v.matricula = NEW.matricula 
        AND v.id_sede != NEW.id_sede
    ) THEN
        -- Si el vehículo está en otra sede, lanzamos un error
        RAISE EXCEPTION 'El vehículo con matrícula % ya está asociado a otra sede.', NEW.matricula;
    END IF;

    -- Si no, permitimos la operación
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verificar_sede_vehiculo
BEFORE INSERT OR UPDATE ON VEHICULO
FOR EACH ROW
EXECUTE FUNCTION verificar_sede_vehiculo();

-- Trigger para que una empresa no sea gestionada por varias sedes
CREATE OR REPLACE FUNCTION verificar_sede_unica_empresa()
RETURNS TRIGGER AS $$
BEGIN
    -- Verificamos si la empresa ya está asociada a una sede
    IF OLD.id_sede IS DISTINCT FROM NEW.id_sede THEN
        -- Si la empresa ya tiene una sede asignada y se intenta cambiar, lanzamos un error
        RAISE EXCEPTION 'La empresa con id % ya está gestionada por otra sede y no puede ser reasignada.', NEW.id_empresa;
    END IF;

    -- Si no se intenta cambiar la sede, permitimos la operación
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verificar_sede_unica_empresa
BEFORE UPDATE ON EMPRESA
FOR EACH ROW
EXECUTE FUNCTION verificar_sede_unica_empresa();

-- Trigger añadir a vehiculo cuando se añade furgoneta o camion
CREATE OR REPLACE FUNCTION insertar_en_vehiculo()
RETURNS TRIGGER AS $$
BEGIN
    -- Insertamos un nuevo registro en VEHICULO tomando los datos de
    INSERT INTO VEHICULO (matricula, modelo, color, estado, id_sede, id_taller)
    VALUES (NEW.matricula, NEW.modelo, NEW.color, NEW.estado, NEW.id_sede, NEW.id_taller);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_insertar_furgoneta_en_vehiculo
BEFORE INSERT ON FURGONETA
FOR EACH ROW
EXECUTE FUNCTION insertar_en_vehiculo();
CREATE TRIGGER trigger_insertar_camion_en_vehiculo
BEFORE INSERT ON CAMION
FOR EACH ROW
EXECUTE FUNCTION insertar_en_vehiculo();

-- Trigger para eliminar de vehiculo cuando se elimine una furgoneta o camion
CREATE OR REPLACE FUNCTION eliminar_de_vehiculo()
RETURNS TRIGGER AS $$
BEGIN
    -- Eliminamos el registro correspondiente de la tabla VEHICULO
    DELETE FROM VEHICULO WHERE matricula = OLD.matricula;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_eliminar_furgoneta_de_vehiculo
BEFORE DELETE ON FURGONETA
EXECUTE FUNCTION eliminar_de_vehiculo();
CREATE TRIGGER trigger_eliminar_camion_de_vehiculo
BEFORE DELETE ON CAMION
EXECUTE FUNCTION eliminar_de_vehiculo();