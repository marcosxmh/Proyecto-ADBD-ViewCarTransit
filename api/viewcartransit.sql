--
-- PostgreSQL database dump
--

-- Dumped from database version 14.15 (Ubuntu 14.15-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.15 (Ubuntu 14.15-0ubuntu0.22.04.1)

-- Autores:
-- Ramiro Difonti Domé (alu0101425030)
-- Ruyman García Martín (alu0101408866)
-- Marcos Medinilla Hernandéz (alu0101211206)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE viewcartransit;
--
-- Name: viewcartransit; Type: DATABASE; Schema: -; Owner: -
--

CREATE DATABASE viewcartransit WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'es_ES.UTF-8';


\connect viewcartransit

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: check_vehiculo_disponible(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_vehiculo_disponible() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (SELECT estado FROM VEHICULO WHERE matricula = NEW.matricula LIMIT 1) != 'Disponible' THEN
        RAISE EXCEPTION 'El vehiculo no esta disponible';
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: eliminar_de_vehiculo(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.eliminar_de_vehiculo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Eliminamos el registro correspondiente de la tabla VEHICULO
    DELETE FROM VEHICULO WHERE matricula = OLD.matricula;
    RETURN OLD;
END;
$$;


--
-- Name: insertar_en_vehiculo(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.insertar_en_vehiculo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Insertamos un nuevo registro en VEHICULO tomando los datos de
    INSERT INTO VEHICULO (matricula, modelo, color, estado, id_sede, id_taller)
    VALUES (NEW.matricula, NEW.modelo, NEW.color, NEW.estado, NEW.id_sede, NEW.id_taller);
    RETURN NEW;
END;
$$;


--
-- Name: reasignar_camion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reasignar_camion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: reasignar_furgoneta(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reasignar_furgoneta() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: reasignar_taller_a_vehiculos(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reasignar_taller_a_vehiculos() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: valida_envia_vehiculo(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.valida_envia_vehiculo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: valida_test_conductor(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.valida_test_conductor() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: verificar_sede_unica_empresa(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verificar_sede_unica_empresa() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Verificamos si la empresa ya está asociada a una sede
    IF OLD.id_sede IS DISTINCT FROM NEW.id_sede THEN
        -- Si la empresa ya tiene una sede asignada y se intenta cambiar, lanzamos un error
        RAISE EXCEPTION 'La empresa con id % ya está gestionada por otra sede y no puede ser reasignada.', NEW.id_empresa;
    END IF;

    -- Si no se intenta cambiar la sede, permitimos la operación
    RETURN NEW;
END;
$$;


--
-- Name: verificar_sede_vehiculo(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verificar_sede_vehiculo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: verificar_solapamiento_contrato(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verificar_solapamiento_contrato() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: vehiculo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehiculo (
    matricula character varying(20) NOT NULL,
    modelo character varying(50) NOT NULL,
    color character varying(20),
    estado character varying(10),
    id_sede integer NOT NULL,
    id_taller integer,
    CONSTRAINT vehiculo_estado_check CHECK (((estado)::text = ANY (ARRAY[('Disponible'::character varying)::text, ('En Taller'::character varying)::text])))
);


--
-- Name: camion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.camion (
    tiene_trailer boolean NOT NULL
)
INHERITS (public.vehiculo);


--
-- Name: conduce; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conduce (
    dni character varying(9) NOT NULL,
    matricula character varying(20) NOT NULL
);


--
-- Name: conductor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conductor (
    dni character varying(9) NOT NULL,
    nombre character varying(50) NOT NULL,
    apellidos character varying(50) NOT NULL,
    licencia character varying(50) NOT NULL,
    CONSTRAINT conductor_licencia_check CHECK (((licencia)::text = ANY (ARRAY[('B'::character varying)::text, ('C'::character varying)::text, ('C+E'::character varying)::text])))
);


--
-- Name: contrato; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contrato (
    id_contrato integer NOT NULL,
    id_empresa integer NOT NULL,
    matricula character varying(20) NOT NULL,
    fecha_ini date NOT NULL,
    fecha_fin date NOT NULL,
    CONSTRAINT contrato_check CHECK ((fecha_ini <= fecha_fin)),
    CONSTRAINT contrato_fecha_fin_check CHECK ((fecha_fin > CURRENT_DATE))
);


--
-- Name: contrato_id_contrato_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contrato_id_contrato_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contrato_id_contrato_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contrato_id_contrato_seq OWNED BY public.contrato.id_contrato;


--
-- Name: empresa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.empresa (
    id_empresa integer NOT NULL,
    nombre character varying(50) NOT NULL,
    tipo_empresa character varying(50) NOT NULL,
    telefono character varying(20),
    correo_contacto character varying(50),
    id_sede integer NOT NULL,
    CONSTRAINT empresa_correo_contacto_check CHECK (((correo_contacto)::text ~~ '%@%.%'::text)),
    CONSTRAINT empresa_telefono_check CHECK (((telefono)::text ~ '^\d{3}-\d{3}-\d{3}$'::text))
);


--
-- Name: empresa_id_empresa_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.empresa_id_empresa_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: empresa_id_empresa_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.empresa_id_empresa_seq OWNED BY public.empresa.id_empresa;


--
-- Name: encargado; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.encargado (
    dni character varying(9) NOT NULL,
    nombre character varying(50) NOT NULL,
    apellidos character varying(50) NOT NULL,
    id_sede integer NOT NULL
);


--
-- Name: envia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.envia (
    matricula character varying(20) NOT NULL,
    id_paquete integer NOT NULL,
    id_empresa integer NOT NULL,
    destino character varying(100) NOT NULL,
    fecha date NOT NULL,
    CONSTRAINT envia_fecha_check CHECK ((fecha >= CURRENT_DATE))
);


--
-- Name: furgoneta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.furgoneta (
    porton_lateral boolean NOT NULL
)
INHERITS (public.vehiculo);


--
-- Name: informe; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.informe (
    id_informe integer NOT NULL,
    fecha date NOT NULL,
    nombre character varying(50) NOT NULL,
    apellidos character varying(50) NOT NULL,
    descripcion character varying(255) NOT NULL,
    matricula character varying(20) NOT NULL,
    id_taller integer,
    CONSTRAINT informe_fecha_check CHECK ((fecha <= CURRENT_DATE))
);


--
-- Name: informe_id_informe_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.informe_id_informe_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: informe_id_informe_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.informe_id_informe_seq OWNED BY public.informe.id_informe;


--
-- Name: paquete; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.paquete (
    id_paquete integer NOT NULL,
    descripcion character varying(255),
    peso numeric(10,2) NOT NULL,
    id_empresa integer NOT NULL,
    CONSTRAINT paquete_peso_check CHECK ((peso > (0)::numeric))
);


--
-- Name: paquete_id_paquete_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.paquete_id_paquete_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: paquete_id_paquete_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.paquete_id_paquete_seq OWNED BY public.paquete.id_paquete;


--
-- Name: sede; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sede (
    id_sede integer NOT NULL,
    nombre character varying(50),
    localidad character varying(50),
    calle character varying(50),
    numero character varying(10),
    telefono character varying(20),
    correo_contacto character varying(50),
    CONSTRAINT sede_correo_contacto_check CHECK (((correo_contacto)::text ~~ '%@%.%'::text)),
    CONSTRAINT sede_telefono_check CHECK (((telefono)::text ~ '^\d{3}-\d{3}-\d{3}$'::text))
);


--
-- Name: sede_id_sede_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sede_id_sede_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sede_id_sede_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sede_id_sede_seq OWNED BY public.sede.id_sede;


--
-- Name: taller; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.taller (
    id_taller integer NOT NULL,
    nombre character varying(50) NOT NULL,
    telefono character varying(20),
    localidad character varying(50) NOT NULL,
    calle character varying(50) NOT NULL,
    numero character varying(10) NOT NULL,
    CONSTRAINT taller_telefono_check CHECK (((telefono)::text ~ '^\d{3}-\d{3}-\d{3}$'::text))
);


--
-- Name: taller_id_taller_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.taller_id_taller_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: taller_id_taller_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.taller_id_taller_seq OWNED BY public.taller.id_taller;


--
-- Name: test; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test (
    id_test integer NOT NULL,
    nota numeric(5,2) NOT NULL,
    dni character varying(9) NOT NULL,
    CONSTRAINT test_nota_check CHECK (((nota >= (0)::numeric) AND (nota <= (10)::numeric)))
);


--
-- Name: test_id_test_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.test_id_test_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_id_test_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.test_id_test_seq OWNED BY public.test.id_test;


--
-- Name: contrato id_contrato; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contrato ALTER COLUMN id_contrato SET DEFAULT nextval('public.contrato_id_contrato_seq'::regclass);


--
-- Name: empresa id_empresa; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.empresa ALTER COLUMN id_empresa SET DEFAULT nextval('public.empresa_id_empresa_seq'::regclass);


--
-- Name: informe id_informe; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.informe ALTER COLUMN id_informe SET DEFAULT nextval('public.informe_id_informe_seq'::regclass);


--
-- Name: paquete id_paquete; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paquete ALTER COLUMN id_paquete SET DEFAULT nextval('public.paquete_id_paquete_seq'::regclass);


--
-- Name: sede id_sede; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sede ALTER COLUMN id_sede SET DEFAULT nextval('public.sede_id_sede_seq'::regclass);


--
-- Name: taller id_taller; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taller ALTER COLUMN id_taller SET DEFAULT nextval('public.taller_id_taller_seq'::regclass);


--
-- Name: test id_test; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test ALTER COLUMN id_test SET DEFAULT nextval('public.test_id_test_seq'::regclass);


--
-- Data for Name: camion; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.camion (matricula, modelo, color, estado, id_sede, id_taller, tiene_trailer) FROM stdin;
0000ABF	Nissan NV400	Verde	Disponible	2	11	t
0000ABG	Renault Master	Blanco	Disponible	2	12	f
0000ABH	Mercedes Vito	Azul	Disponible	2	13	t
0000ABI	Volkswagen Transporter	Rojo	Disponible	2	14	f
0000ABJ	Iveco Daily	Negro	Disponible	2	15	t
0000ABK	Ford Transit Custom	Gris	Disponible	2	6	f
0000ABL	Peugeot Expert	Verde	Disponible	2	7	t
0000ABM	Citroen Dispatch	Blanco	Disponible	2	8	f
0000ABN	Fiat Talento	Azul	Disponible	2	9	t
0000ABO	Opel Vivaro	Rojo	Disponible	2	10	f
0000ABP	Nissan NV300	Negro	Disponible	2	11	t
0000ABQ	Renault Trafic	Gris	Disponible	2	12	f
0000ABR	Mercedes Citan	Verde	Disponible	2	13	t
0000ABS	Volkswagen Caddy	Blanco	Disponible	2	14	f
0000ABT	Iveco Eurocargo	Azul	Disponible	2	15	t
0000ABU	Ford Transit	Blanco	Disponible	3	6	f
0000ABV	Peugeot Boxer	Azul	Disponible	3	7	t
0000ABW	Citroen Jumper	Rojo	Disponible	3	8	f
0000ABX	Fiat Ducato	Negro	Disponible	3	9	t
0000ABY	Opel Movano	Gris	Disponible	3	10	f
0000ABZ	Nissan NV400	Verde	Disponible	3	11	t
0000ACA	Renault Master	Blanco	Disponible	3	12	f
0000ACB	Mercedes Vito	Azul	Disponible	3	13	t
0000ACC	Volkswagen Transporter	Rojo	Disponible	3	14	f
0000ACD	Iveco Daily	Negro	Disponible	3	15	t
0000ACE	Ford Transit Custom	Gris	Disponible	3	6	f
0000ACF	Peugeot Expert	Verde	Disponible	3	7	t
0000ACG	Citroen Dispatch	Blanco	Disponible	3	8	f
0000ACH	Fiat Talento	Azul	Disponible	3	9	t
0000ACI	Opel Vivaro	Rojo	Disponible	3	10	f
0000ACJ	Nissan NV300	Negro	Disponible	3	11	t
0000ACK	Renault Trafic	Gris	Disponible	3	12	f
0000ACL	Mercedes Citan	Verde	Disponible	3	13	t
0000ACM	Volkswagen Caddy	Blanco	Disponible	3	14	f
0000ACN	Iveco Eurocargo	Azul	Disponible	3	15	t
\.


--
-- Data for Name: conduce; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.conduce (dni, matricula) FROM stdin;
12345678A	0000AAA
12345678A	0000AAB
23456789B	0000AAC
23456789B	0000AAD
34567890C	0000AAE
34567890C	0000AAF
45678901D	0000AAG
45678901D	0000AAH
56789012E	0000AAI
56789012E	0000AAJ
67890123F	0000AAK
67890123F	0000AAL
12345678A	0000AAM
23456789B	0000AAN
34567890C	0000AAO
\.


--
-- Data for Name: conductor; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.conductor (dni, nombre, apellidos, licencia) FROM stdin;
12345678A	Juan	Perez	B
23456789B	Maria	Lopez	C
34567890C	Pedro	Garcia	C+E
45678901D	Laura	Martinez	B
56789012E	Carlos	Sanchez	C
67890123F	Ana	Gonzalez	C+E
\.


--
-- Data for Name: contrato; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.contrato (id_contrato, id_empresa, matricula, fecha_ini, fecha_fin) FROM stdin;
1	1	0000AAA	2024-12-20	2025-01-20
2	2	0000AAB	2024-12-20	2025-01-20
3	3	0000AAC	2024-12-20	2025-01-20
4	4	0000AAD	2024-12-20	2025-01-20
5	5	0000AAE	2024-12-20	2025-01-20
6	1	0000AAF	2024-12-20	2025-01-20
7	2	0000AAG	2024-12-20	2025-01-20
8	3	0000AAH	2024-12-20	2025-01-20
9	4	0000AAI	2024-12-20	2025-01-20
10	5	0000AAJ	2024-12-20	2025-01-20
11	1	0000AAK	2024-12-20	2025-01-20
12	2	0000AAL	2024-12-20	2025-01-20
13	3	0000AAM	2024-12-20	2025-01-20
14	4	0000AAN	2024-12-20	2025-01-20
15	5	0000AAO	2024-12-20	2025-01-20
16	1	0000AAP	2024-12-20	2025-01-20
17	2	0000AAQ	2024-12-20	2025-01-20
18	3	0000AAR	2024-12-20	2025-01-20
19	4	0000AAS	2024-12-20	2025-01-20
20	5	0000AAT	2024-12-20	2025-01-20
21	4	0000AAD	2025-01-21	2025-02-20
22	5	0000AAE	2025-01-21	2025-02-20
23	1	0000AAF	2025-01-21	2025-02-20
24	2	0000AAG	2025-01-21	2025-02-20
25	3	0000AAH	2025-01-21	2025-02-20
26	3	0000ACK	2025-01-21	2025-02-20
27	1	0000ACM	2025-01-21	2025-02-20
28	2	0000ACN	2025-01-21	2025-02-20
\.


--
-- Data for Name: empresa; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.empresa (id_empresa, nombre, tipo_empresa, telefono, correo_contacto, id_sede) FROM stdin;
1	Supermercado La Colmena	Venta al por menor	922-111-222	contacto@lacolmena.com	1
2	Tienda ElectroMax	Venta al por menor	922-222-333	info@electromax.com	1
3	Moda y Complementos SRL	Venta al por menor	922-333-444	ventas@modaycomplementos.com	2
4	Jugueteria HappyKids	Venta al por menor	922-444-555	contacto@happykids.com	2
5	Hogar Decoracion	Venta al por menor	922-555-666	info@hogardecoracion.com	3
\.


--
-- Data for Name: encargado; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.encargado (dni, nombre, apellidos, id_sede) FROM stdin;
12345678A	Juan	Perez	1
23456789B	Maria	Lopez	2
34567890C	Pedro	Garcia	3
\.


--
-- Data for Name: envia; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.envia (matricula, id_paquete, id_empresa, destino, fecha) FROM stdin;
0000AAA	1	1	Santa Cruz de Tenerife	2024-12-21
0000AAB	2	2	La Laguna	2024-12-22
0000AAC	3	3	Puerto de la Cruz	2024-12-23
0000AAD	4	4	Arona	2024-12-24
0000AAE	5	5	Granadilla	2024-12-25
0000AAF	6	1	Adeje	2024-12-26
0000AAG	7	2	La Orotava	2024-12-27
0000AAH	8	3	Icod de los Vinos	2024-12-28
0000AAI	9	4	Los Realejos	2024-12-29
0000AAJ	10	5	Güímar	2024-12-30
0000AAK	11	1	Santa Cruz de Tenerife	2024-12-31
0000AAL	12	2	La Laguna	2025-01-01
0000AAM	13	3	Puerto de la Cruz	2025-01-02
0000AAN	14	4	Arona	2025-01-03
0000AAO	15	5	Granadilla	2025-01-04
0000AAP	16	1	Adeje	2025-01-05
0000AAQ	17	2	La Orotava	2025-01-06
0000AAR	18	3	Icod de los Vinos	2025-01-07
0000AAS	19	4	Los Realejos	2025-01-08
0000AAT	20	5	Güímar	2025-01-09
0000ACM	21	1	Santa Cruz de Tenerife	2025-02-10
0000ACN	22	2	La Laguna	2025-02-11
0000ACK	23	3	Puerto de la Cruz	2025-02-12
0000AAD	24	4	Arona	2025-02-13
0000AAE	25	5	Granadilla	2025-02-14
0000ACM	26	1	Adeje	2025-02-15
0000ACN	27	2	La Orotava	2025-02-16
0000ACK	28	3	Icod de los Vinos	2025-02-17
0000AAD	29	4	Los Realejos	2025-02-18
0000AAE	30	5	Güímar	2025-02-19
\.


--
-- Data for Name: furgoneta; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.furgoneta (matricula, modelo, color, estado, id_sede, id_taller, porton_lateral) FROM stdin;
0000AAA	Renault Kangoo	Blanco	Disponible	1	1	t
0000AAB	Mercedes Sprinter	Azul	Disponible	1	2	f
0000AAC	Iveco Daily	Rojo	Disponible	1	2	t
0000AAD	Scania R450	Negro	Disponible	1	4	f
0000AAE	Volvo FH16	Gris	Disponible	1	5	t
0000AAF	Volkswagen Crafter	Verde	Disponible	2	2	f
0000AAG	Ford Transit	Blanco	Disponible	1	1	t
0000AAH	Peugeot Boxer	Azul	Disponible	1	2	f
0000AAI	Citroen Jumper	Rojo	Disponible	1	2	t
0000AAJ	Fiat Ducato	Negro	Disponible	1	4	f
0000AAK	Opel Movano	Gris	Disponible	1	5	t
0000AAL	Nissan NV400	Verde	Disponible	1	1	f
0000AAM	Renault Master	Blanco	Disponible	1	2	t
0000AAN	Mercedes Vito	Azul	Disponible	1	2	f
0000AAO	Volkswagen Transporter	Rojo	Disponible	1	4	t
0000AAP	Iveco Daily	Negro	Disponible	1	5	f
0000AAQ	Ford Transit Custom	Gris	Disponible	1	1	t
0000AAR	Peugeot Expert	Verde	Disponible	1	2	f
0000AAS	Citroen Dispatch	Blanco	Disponible	1	2	t
0000AAT	Fiat Talento	Azul	Disponible	1	4	f
0000AAU	Opel Vivaro	Rojo	Disponible	1	5	t
0000AAV	Nissan NV300	Negro	Disponible	1	1	f
0000AAW	Renault Trafic	Gris	Disponible	1	2	t
0000AAX	Mercedes Citan	Verde	Disponible	1	2	f
0000AAY	Volkswagen Caddy	Blanco	Disponible	1	4	t
0000AAZ	Iveco Eurocargo	Azul	Disponible	1	5	f
0000ABA	Ford Transit	Blanco	Disponible	2	6	t
0000ABB	Peugeot Boxer	Azul	Disponible	2	7	f
0000ABC	Citroen Jumper	Rojo	Disponible	2	8	t
0000ABD	Fiat Ducato	Negro	Disponible	2	9	f
0000ABE	Opel Movano	Gris	Disponible	2	10	t
\.


--
-- Data for Name: informe; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.informe (id_informe, fecha, nombre, apellidos, descripcion, matricula, id_taller) FROM stdin;
1	2024-12-20	Juan	Perez	El vehiculo presenta un fallo en el motor	0000AAA	1
2	2024-12-20	Maria	Lopez	El vehiculo presenta un fallo en el sistema de frenos	0000AAB	2
3	2024-12-20	Pedro	Garcia	El vehiculo presenta un fallo en el sistema de direccion	0000AAC	3
4	2024-12-20	Laura	Martinez	El vehiculo presenta un fallo en el sistema de luces	0000AAD	4
5	2024-12-20	Carlos	Sanchez	El vehiculo presenta un fallo en el sistema de climatizacion	0000AAE	5
6	2024-12-20	Ana	Gonzalez	El vehiculo presenta un fallo en el sistema de suspension	0000AAF	6
\.


--
-- Data for Name: paquete; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.paquete (id_paquete, descripcion, peso, id_empresa) FROM stdin;
1	Televisor LED 55 pulgadas	15.00	1
2	Ropa de invierno para niños	10.50	2
3	Set de muebles de jardin	80.00	3
4	Juguetes educativos	12.30	4
5	Decoracion para el hogar	25.00	5
6	Laptop Ultrabook	2.50	1
7	Refrigerador 300L	50.00	2
8	Juego de sabanas premium	5.00	3
9	Set de herramientas electricas	18.00	4
10	Cafetera de ultima generacion	4.50	5
11	Aspiradora robot	3.00	1
12	Bicicleta de montaña	12.00	2
13	Consola de videojuegos	4.00	3
14	Cámara fotográfica	1.50	4
15	Smartphone de última generación	0.20	5
16	Tablet 10 pulgadas	0.50	1
17	Impresora multifunción	8.00	2
18	Microondas	12.00	3
19	Lavadora	60.00	4
20	Secadora	55.00	5
21	Televisor LED 55 pulgadas	15.00	1
22	Ropa de invierno para niños	10.50	2
23	Set de muebles de jardin	80.00	3
24	Juguetes educativos	12.30	4
25	Decoracion para el hogar	25.00	5
26	Laptop Ultrabook	2.50	1
27	Refrigerador 300L	50.00	2
28	Juego de sabanas premium	5.00	3
29	Set de herramientas electricas	18.00	4
30	Cafetera de ultima generacion	4.50	5
31	Aspiradora robot	3.00	1
32	Bicicleta de montaña	12.00	2
33	Consola de videojuegos	4.00	3
34	Cámara fotográfica	1.50	4
35	Smartphone de última generación	0.20	5
36	Tablet 10 pulgadas	0.50	1
37	Impresora multifunción	8.00	2
38	Microondas	12.00	3
39	Lavadora	60.00	4
40	Secadora	55.00	5
\.


--
-- Data for Name: sede; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sede (id_sede, nombre, localidad, calle, numero, telefono, correo_contacto) FROM stdin;
1	Sede Central Tenerife	Tenerife	Los Majuelos	100	922-123-456	central@viewcartransit.com
2	Sede Sur Tenerife	Adeje	Sur	200	922-456-789	sur@viewcartransit.com
3	Sede Norte Tenerife	La Orotava	Norte	300	922-789-123	norte@viewcartransit.com
\.


--
-- Data for Name: taller; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.taller (id_taller, nombre, telefono, localidad, calle, numero) FROM stdin;
1	Taller Central	922-123-456	Los Majuelos	Central	100
2	Taller Sur	922-456-789	Adeje	Sur	200
3	Taller Norte	922-789-123	La Orotava	Norte	300
4	Taller Este	922-123-456	Santa Cruz de Tenerife	Este	400
5	Taller Oeste	922-456-789	Los Realejos	Oeste	500
6	Taller Paco	922-111-111	Localidad 1	Calle 1	101
7	Taller Juan	922-222-222	Localidad 2	Calle 2	102
8	Taller Maria	922-333-333	Localidad 3	Calle 3	103
9	Taller Luis	922-444-444	Localidad 4	Calle 4	104
10	Taller Ana	922-555-555	Localidad 5	Calle 5	105
11	Taller Pedro	922-666-666	Localidad 6	Calle 6	106
12	Taller Carmen	922-777-777	Localidad 7	Calle 7	107
13	Taller Jose	922-888-888	Localidad 8	Calle 8	108
14	Taller Laura	922-999-999	Localidad 9	Calle 9	109
15	Taller Miguel	922-000-000	Localidad 10	Calle 10	110
16	Taller Lucia	922-111-222	Localidad 11	Calle 11	111
17	Taller Antonio	922-222-333	Localidad 12	Calle 12	112
18	Taller Isabel	922-333-444	Localidad 13	Calle 13	113
19	Taller Francisco	922-444-555	Localidad 14	Calle 14	114
20	Taller Sofia	922-555-666	Localidad 15	Calle 15	115
\.


--
-- Data for Name: test; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.test (id_test, nota, dni) FROM stdin;
1	8.50	12345678A
2	7.00	23456789B
3	9.00	34567890C
4	6.50	45678901D
5	8.00	56789012E
6	5.50	67890123F
\.


--
-- Data for Name: vehiculo; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vehiculo (matricula, modelo, color, estado, id_sede, id_taller) FROM stdin;
0000AAA	Renault Kangoo	Blanco	Disponible	1	1
0000AAB	Mercedes Sprinter	Azul	Disponible	1	2
0000AAC	Iveco Daily	Rojo	Disponible	1	2
0000AAD	Scania R450	Negro	Disponible	1	4
0000AAE	Volvo FH16	Gris	Disponible	1	5
0000AAF	Volkswagen Crafter	Verde	Disponible	2	2
0000AAG	Ford Transit	Blanco	Disponible	1	1
0000AAH	Peugeot Boxer	Azul	Disponible	1	2
0000AAI	Citroen Jumper	Rojo	Disponible	1	2
0000AAJ	Fiat Ducato	Negro	Disponible	1	4
0000AAK	Opel Movano	Gris	Disponible	1	5
0000AAL	Nissan NV400	Verde	Disponible	1	1
0000AAM	Renault Master	Blanco	Disponible	1	2
0000AAN	Mercedes Vito	Azul	Disponible	1	2
0000AAO	Volkswagen Transporter	Rojo	Disponible	1	4
0000AAP	Iveco Daily	Negro	Disponible	1	5
0000AAQ	Ford Transit Custom	Gris	Disponible	1	1
0000AAR	Peugeot Expert	Verde	Disponible	1	2
0000AAS	Citroen Dispatch	Blanco	Disponible	1	2
0000AAT	Fiat Talento	Azul	Disponible	1	4
0000AAU	Opel Vivaro	Rojo	Disponible	1	5
0000AAV	Nissan NV300	Negro	Disponible	1	1
0000AAW	Renault Trafic	Gris	Disponible	1	2
0000AAX	Mercedes Citan	Verde	Disponible	1	2
0000AAY	Volkswagen Caddy	Blanco	Disponible	1	4
0000AAZ	Iveco Eurocargo	Azul	Disponible	1	5
0000ABA	Ford Transit	Blanco	Disponible	2	6
0000ABB	Peugeot Boxer	Azul	Disponible	2	7
0000ABC	Citroen Jumper	Rojo	Disponible	2	8
0000ABD	Fiat Ducato	Negro	Disponible	2	9
0000ABE	Opel Movano	Gris	Disponible	2	10
0000ABF	Nissan NV400	Verde	Disponible	2	11
0000ABG	Renault Master	Blanco	Disponible	2	12
0000ABH	Mercedes Vito	Azul	Disponible	2	13
0000ABI	Volkswagen Transporter	Rojo	Disponible	2	14
0000ABJ	Iveco Daily	Negro	Disponible	2	15
0000ABK	Ford Transit Custom	Gris	Disponible	2	6
0000ABL	Peugeot Expert	Verde	Disponible	2	7
0000ABM	Citroen Dispatch	Blanco	Disponible	2	8
0000ABN	Fiat Talento	Azul	Disponible	2	9
0000ABO	Opel Vivaro	Rojo	Disponible	2	10
0000ABP	Nissan NV300	Negro	Disponible	2	11
0000ABQ	Renault Trafic	Gris	Disponible	2	12
0000ABR	Mercedes Citan	Verde	Disponible	2	13
0000ABS	Volkswagen Caddy	Blanco	Disponible	2	14
0000ABT	Iveco Eurocargo	Azul	Disponible	2	15
0000ABU	Ford Transit	Blanco	Disponible	3	6
0000ABV	Peugeot Boxer	Azul	Disponible	3	7
0000ABW	Citroen Jumper	Rojo	Disponible	3	8
0000ABX	Fiat Ducato	Negro	Disponible	3	9
0000ABY	Opel Movano	Gris	Disponible	3	10
0000ABZ	Nissan NV400	Verde	Disponible	3	11
0000ACA	Renault Master	Blanco	Disponible	3	12
0000ACB	Mercedes Vito	Azul	Disponible	3	13
0000ACC	Volkswagen Transporter	Rojo	Disponible	3	14
0000ACD	Iveco Daily	Negro	Disponible	3	15
0000ACE	Ford Transit Custom	Gris	Disponible	3	6
0000ACF	Peugeot Expert	Verde	Disponible	3	7
0000ACG	Citroen Dispatch	Blanco	Disponible	3	8
0000ACH	Fiat Talento	Azul	Disponible	3	9
0000ACI	Opel Vivaro	Rojo	Disponible	3	10
0000ACJ	Nissan NV300	Negro	Disponible	3	11
0000ACK	Renault Trafic	Gris	Disponible	3	12
0000ACL	Mercedes Citan	Verde	Disponible	3	13
0000ACM	Volkswagen Caddy	Blanco	Disponible	3	14
0000ACN	Iveco Eurocargo	Azul	Disponible	3	15
\.


--
-- Name: contrato_id_contrato_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.contrato_id_contrato_seq', 28, true);


--
-- Name: empresa_id_empresa_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.empresa_id_empresa_seq', 5, true);


--
-- Name: informe_id_informe_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.informe_id_informe_seq', 6, true);


--
-- Name: paquete_id_paquete_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.paquete_id_paquete_seq', 40, true);


--
-- Name: sede_id_sede_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sede_id_sede_seq', 3, true);


--
-- Name: taller_id_taller_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.taller_id_taller_seq', 20, true);


--
-- Name: test_id_test_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.test_id_test_seq', 6, true);


--
-- Name: conduce conduce_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conduce
    ADD CONSTRAINT conduce_pkey PRIMARY KEY (dni, matricula);


--
-- Name: conductor conductor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conductor
    ADD CONSTRAINT conductor_pkey PRIMARY KEY (dni);


--
-- Name: contrato contrato_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contrato
    ADD CONSTRAINT contrato_pkey PRIMARY KEY (id_contrato);


--
-- Name: empresa empresa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.empresa
    ADD CONSTRAINT empresa_pkey PRIMARY KEY (id_empresa);


--
-- Name: encargado encargado_id_sede_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encargado
    ADD CONSTRAINT encargado_id_sede_key UNIQUE (id_sede);


--
-- Name: encargado encargado_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encargado
    ADD CONSTRAINT encargado_pkey PRIMARY KEY (dni);


--
-- Name: envia envia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envia
    ADD CONSTRAINT envia_pkey PRIMARY KEY (id_paquete);


--
-- Name: informe informe_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.informe
    ADD CONSTRAINT informe_pkey PRIMARY KEY (id_informe);


--
-- Name: paquete paquete_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paquete
    ADD CONSTRAINT paquete_pkey PRIMARY KEY (id_paquete);


--
-- Name: sede sede_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sede
    ADD CONSTRAINT sede_pkey PRIMARY KEY (id_sede);


--
-- Name: taller taller_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taller
    ADD CONSTRAINT taller_pkey PRIMARY KEY (id_taller);


--
-- Name: test test_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test
    ADD CONSTRAINT test_pkey PRIMARY KEY (id_test);


--
-- Name: vehiculo vehiculo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehiculo
    ADD CONSTRAINT vehiculo_pkey PRIMARY KEY (matricula);


--
-- Name: contrato trg_check_vehiculo_disponible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_check_vehiculo_disponible BEFORE INSERT ON public.contrato FOR EACH ROW EXECUTE FUNCTION public.check_vehiculo_disponible();


--
-- Name: contrato trg_verificar_solapamiento_contrato; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_verificar_solapamiento_contrato BEFORE INSERT ON public.contrato FOR EACH ROW EXECUTE FUNCTION public.verificar_solapamiento_contrato();


--
-- Name: camion trigger_eliminar_camion_de_vehiculo; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_eliminar_camion_de_vehiculo BEFORE DELETE ON public.camion FOR EACH STATEMENT EXECUTE FUNCTION public.eliminar_de_vehiculo();


--
-- Name: furgoneta trigger_eliminar_furgoneta_de_vehiculo; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_eliminar_furgoneta_de_vehiculo BEFORE DELETE ON public.furgoneta FOR EACH STATEMENT EXECUTE FUNCTION public.eliminar_de_vehiculo();


--
-- Name: camion trigger_insertar_camion_en_vehiculo; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_insertar_camion_en_vehiculo BEFORE INSERT ON public.camion FOR EACH ROW EXECUTE FUNCTION public.insertar_en_vehiculo();


--
-- Name: furgoneta trigger_insertar_furgoneta_en_vehiculo; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_insertar_furgoneta_en_vehiculo BEFORE INSERT ON public.furgoneta FOR EACH ROW EXECUTE FUNCTION public.insertar_en_vehiculo();


--
-- Name: camion trigger_reasignar_camion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_reasignar_camion AFTER DELETE ON public.camion FOR EACH ROW EXECUTE FUNCTION public.reasignar_camion();


--
-- Name: camion trigger_reasignar_camion_en_taller; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_reasignar_camion_en_taller AFTER UPDATE OF estado ON public.camion FOR EACH ROW EXECUTE FUNCTION public.reasignar_camion();


--
-- Name: furgoneta trigger_reasignar_furgoneta; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_reasignar_furgoneta AFTER DELETE ON public.furgoneta FOR EACH ROW EXECUTE FUNCTION public.reasignar_furgoneta();


--
-- Name: furgoneta trigger_reasignar_furgoneta_en_taller; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_reasignar_furgoneta_en_taller AFTER UPDATE OF estado ON public.furgoneta FOR EACH ROW EXECUTE FUNCTION public.reasignar_furgoneta();


--
-- Name: taller trigger_reasignar_taller; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_reasignar_taller BEFORE DELETE ON public.taller FOR EACH ROW EXECUTE FUNCTION public.reasignar_taller_a_vehiculos();


--
-- Name: empresa trigger_verificar_sede_unica_empresa; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_verificar_sede_unica_empresa BEFORE UPDATE ON public.empresa FOR EACH ROW EXECUTE FUNCTION public.verificar_sede_unica_empresa();


--
-- Name: vehiculo trigger_verificar_sede_vehiculo; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_verificar_sede_vehiculo BEFORE INSERT OR UPDATE ON public.vehiculo FOR EACH ROW EXECUTE FUNCTION public.verificar_sede_vehiculo();


--
-- Name: envia verifica_contrato; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER verifica_contrato BEFORE INSERT OR UPDATE ON public.envia FOR EACH ROW EXECUTE FUNCTION public.valida_envia_vehiculo();


--
-- Name: conduce verifica_test; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER verifica_test BEFORE INSERT OR UPDATE ON public.conduce FOR EACH ROW EXECUTE FUNCTION public.valida_test_conductor();


--
-- Name: conduce conduce_dni_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conduce
    ADD CONSTRAINT conduce_dni_fkey FOREIGN KEY (dni) REFERENCES public.conductor(dni) ON DELETE CASCADE;


--
-- Name: conduce conduce_matricula_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conduce
    ADD CONSTRAINT conduce_matricula_fkey FOREIGN KEY (matricula) REFERENCES public.vehiculo(matricula) ON DELETE CASCADE;


--
-- Name: contrato contrato_id_empresa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contrato
    ADD CONSTRAINT contrato_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES public.empresa(id_empresa) ON DELETE CASCADE;


--
-- Name: contrato contrato_matricula_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contrato
    ADD CONSTRAINT contrato_matricula_fkey FOREIGN KEY (matricula) REFERENCES public.vehiculo(matricula);


--
-- Name: empresa empresa_id_sede_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.empresa
    ADD CONSTRAINT empresa_id_sede_fkey FOREIGN KEY (id_sede) REFERENCES public.sede(id_sede) ON DELETE CASCADE;


--
-- Name: encargado encargado_id_sede_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encargado
    ADD CONSTRAINT encargado_id_sede_fkey FOREIGN KEY (id_sede) REFERENCES public.sede(id_sede) ON DELETE CASCADE;


--
-- Name: envia envia_id_empresa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envia
    ADD CONSTRAINT envia_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES public.empresa(id_empresa) ON DELETE CASCADE;


--
-- Name: envia envia_id_paquete_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envia
    ADD CONSTRAINT envia_id_paquete_fkey FOREIGN KEY (id_paquete) REFERENCES public.paquete(id_paquete) ON DELETE CASCADE;


--
-- Name: envia envia_matricula_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envia
    ADD CONSTRAINT envia_matricula_fkey FOREIGN KEY (matricula) REFERENCES public.vehiculo(matricula);


--
-- Name: informe informe_id_taller_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.informe
    ADD CONSTRAINT informe_id_taller_fkey FOREIGN KEY (id_taller) REFERENCES public.taller(id_taller) ON DELETE SET NULL;


--
-- Name: informe informe_matricula_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.informe
    ADD CONSTRAINT informe_matricula_fkey FOREIGN KEY (matricula) REFERENCES public.vehiculo(matricula);


--
-- Name: paquete paquete_id_empresa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paquete
    ADD CONSTRAINT paquete_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES public.empresa(id_empresa) ON DELETE CASCADE;


--
-- Name: test test_dni_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test
    ADD CONSTRAINT test_dni_fkey FOREIGN KEY (dni) REFERENCES public.conductor(dni) ON DELETE CASCADE;


--
-- Name: vehiculo vehiculo_id_sede_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehiculo
    ADD CONSTRAINT vehiculo_id_sede_fkey FOREIGN KEY (id_sede) REFERENCES public.sede(id_sede);


--
-- Name: vehiculo vehiculo_id_taller_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehiculo
    ADD CONSTRAINT vehiculo_id_taller_fkey FOREIGN KEY (id_taller) REFERENCES public.taller(id_taller);


--
-- PostgreSQL database dump complete
--

