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
    (3, '0000AAH', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '1 day', CURRENT_DATE + INTERVAL '2 months'),
    (3, '0000ACK', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '1 day', CURRENT_DATE + INTERVAL '2 months'),
    (1, '0000ACM', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '1 day', CURRENT_DATE + INTERVAL '2 months'),
    (2, '0000ACN', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '1 day', CURRENT_DATE + INTERVAL '2 months');

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
    ('0000ACM', 21, 1, 'Santa Cruz de Tenerife', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '21 days'),
    ('0000ACN', 22, 2, 'La Laguna', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '22 days'),
    ('0000ACK', 23, 3, 'Puerto de la Cruz', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '23 days'),
    ('0000AAD', 24, 4, 'Arona', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '24 days'),
    ('0000AAE', 25, 5, 'Granadilla', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '25 days'),
    ('0000ACM', 26, 1, 'Adeje', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '26 days'),
    ('0000ACN', 27, 2, 'La Orotava', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '27 days'),
    ('0000ACK', 28, 3, 'Icod de los Vinos', CURRENT_DATE + INTERVAL '1 month' + INTERVAL '28 days'),
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
INSERT INTO INFORME (fecha, nombre, apellidos, id_taller, descripcion, matricula)
VALUES (CURRENT_DATE, 'Juan', 'Perez', 1, 'El vehiculo presenta un fallo en el motor', '0000AAA'),
    (CURRENT_DATE, 'Maria', 'Lopez', 2, 'El vehiculo presenta un fallo en el sistema de frenos', '0000AAB'),
    (CURRENT_DATE, 'Pedro', 'Garcia', 3, 'El vehiculo presenta un fallo en el sistema de direccion', '0000AAC'),
    (CURRENT_DATE, 'Laura', 'Martinez', 4, 'El vehiculo presenta un fallo en el sistema de luces', '0000AAD'),
    (CURRENT_DATE, 'Carlos', 'Sanchez', 5, 'El vehiculo presenta un fallo en el sistema de climatizacion', '0000AAE'),
    (CURRENT_DATE, 'Ana', 'Gonzalez', 6, 'El vehiculo presenta un fallo en el sistema de suspension', '0000AAF');

-- Final: Confirmar esquema
COMMENT ON SCHEMA public IS 'Esquema para la gestion de flotas de vehiculos de empresas clientes';