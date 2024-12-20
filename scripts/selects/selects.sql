-- Mostrar las sedes y las empresas que tienen.
SELECT sede.nombre nombre_sede, empresa.nombre empresa
FROM SEDE sede
JOIN EMPRESA empresa ON sede.id_sede = empresa.id_sede;

-- Mostrar sede y encargado de la sede
SELECT sede.nombre nombre_sede, encargado.nombre nombre_encargado
FROM SEDE sede
JOIN ENCARGADO encargado ON sede.id_sede = encargado.id_sede;

-- Mostrar sede y vehículos que tiene
SELECT sede.nombre nombre_sede, vehiculo.matricula matricula_vehiculo
FROM SEDE sede
JOIN VEHICULO vehiculo ON sede.id_sede = vehiculo.id_sede;

-- Mostrar los contratos que tienen las empresas actualmente y el vehiculo que tienen contratado
SELECT empresa.nombre nombre_empresa, vehiculo.modelo, contrato.fecha_ini fecha_inicio, contrato.fecha_fin fecha_fin
FROM EMPRESA empresa
JOIN CONTRATO contrato ON empresa.id_empresa = contrato.id_empresa
JOIN VEHICULO vehiculo ON contrato.matricula = vehiculo.matricula;

-- Mostrar los paquetes que se han enviado desde una furgoneta
SELECT paquete.descripcion paquete, empresa.nombre nombre_empresa, furgoneta.modelo coche
FROM ENVIA envia
JOIN PAQUETE paquete ON envia.id_paquete = paquete.id_paquete
JOIN EMPRESA empresa ON envia.id_empresa = empresa.id_empresa
JOIN FURGONETA furgoneta ON envia.matricula = furgoneta.matricula;

-- Mostrar los paquetes que se han enviado desde un camion
SELECT paquete.descripcion paquete, empresa.nombre nombre_empresa, camion.modelo coche
FROM ENVIA envia
JOIN PAQUETE paquete ON envia.id_paquete = paquete.id_paquete
JOIN EMPRESA empresa ON envia.id_empresa = empresa.id_empresa
JOIN CAMION camion ON envia.matricula = camion.matricula;

-- Informe de un taller y el vehiculo que ha sido reparado
SELECT taller.nombre nombre_taller, informe.descripcion, vehiculo.modelo modelo_vehiculo, informe.fecha fecha_reparacion
FROM INFORME informe
JOIN TALLER taller ON informe.id_taller = taller.id_taller
JOIN ONLY VEHICULO vehiculo ON informe.matricula = vehiculo.matricula;

-- Mostrar los conductores aptos para nuestra empresa y la nota que sacaron en su test
SELECT conductor.nombre nombre_conductor, conductor.apellidos apellidos_conductor, test.nota nota_conductor
FROM CONDUCTOR conductor
JOIN TEST test ON conductor.dni = test.dni
WHERE test.nota >= 5;

-- Insertar un vehiculo en una sede
INSERT INTO CAMION (matricula, modelo, color, estado, id_sede, id_taller, tiene_trailer)
VALUES ('1000AAA', 'Mercedes Gama Actros', 'Gris', 'Disponible', 1, 1, FALSE);

-- Añadir un contrato a una empresa
INSERT INTO CONTRATO (id_empresa, matricula, fecha_ini, fecha_fin)
VALUES (1, '1000AAA', CURRENT_DATE + INTERVAL '3 month', CURRENT_DATE + INTERVAL '4 month');

-- Añadir un nuevo envio
INSERT INTO ENVIA (matricula, id_paquete, id_empresa, destino, fecha)
VALUES ('1000AAA', 31, 1, 'Santa Cruz de Tenerife', CURRENT_DATE + INTERVAL '100 day');

-- Mostrar nuevo envio y contrato
SELECT paquete.descripcion paquete, empresa.nombre nombre_empresa, camion.modelo coche, camion.matricula
FROM ENVIA envia
JOIN PAQUETE paquete ON envia.id_paquete = paquete.id_paquete
JOIN EMPRESA empresa ON envia.id_empresa = empresa.id_empresa
JOIN CAMION camion ON envia.matricula = camion.matricula
WHERE paquete.id_paquete = 31;
SELECT contrato.id_empresa, contrato.matricula, contrato.fecha_ini, contrato.fecha_fin
FROM CONTRATO contrato
WHERE contrato.id_empresa = 1;

-- Eliminar vehiculo
DELETE FROM CAMION WHERE matricula = '1000AAA';

-- Observar como se ha reasignado en el contrato y en el envio
SELECT paquete.descripcion paquete, empresa.nombre nombre_empresa, camion.modelo coche, camion.matricula
FROM ENVIA envia
JOIN PAQUETE paquete ON envia.id_paquete = paquete.id_paquete
JOIN EMPRESA empresa ON envia.id_empresa = empresa.id_empresa
JOIN CAMION camion ON envia.matricula = camion.matricula
WHERE paquete.id_paquete = 31;

SELECT contrato.id_empresa, contrato.matricula, contrato.fecha_ini, contrato.fecha_fin
FROM CONTRATO contrato
WHERE contrato.id_empresa = 1;
