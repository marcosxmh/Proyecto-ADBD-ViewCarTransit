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