
-- CASO 1: 
-- Listado de Clientes Trabajadores Dependientes con profesión Contador o Vendedor
-- Se listan solo aquellos cuyo año de inscripción es mayor al promedio redondeado
-- Este promedio se obtiene mediante una SUBCONSULTA
-- Se aplican alias, funciones de formato, filtros y ordenamiento por RUT
SELECT 
    c.numrun || '-' || c.dvrun AS RUT,
    INITCAP(c.pnombre) AS "Primer_Nombre",
    INITCAP(NVL(c.snombre,' ')) AS "Segundo_Nombre",
    INITCAP(c.appaterno) AS "Apellido_Paterno",
    INITCAP(c.apmaterno) AS "Apellido_Materno",
    INITCAP(po.nombre_prof_ofic) AS Profesion,
    TO_CHAR(c.fecha_inscripcion, 'DD-MON-YYYY') AS Fecha_Inscripcion
FROM cliente c
JOIN profesion_oficio po 
    ON c.cod_prof_ofic = po.cod_prof_ofic
WHERE 
    c.cod_tipo_cliente = 10
    AND UPPER(po.nombre_prof_ofic) IN ('CONTADOR','VENDEDOR')
    AND EXTRACT(YEAR FROM c.fecha_inscripcion) >
        (SELECT ROUND(AVG(EXTRACT(YEAR FROM fecha_inscripcion)))
         FROM cliente)
ORDER BY c.numrun ASC;

-- CASO 2: 
-- Clientes con cupo disponible mayor o igual al máximo cupo del año anterior
-- Se calcula la edad del cliente y se muestran RUT, edad y cupo disponible
-- Luego se almacena el resultado en la tabla CLIENTES_CUPOS_COMPRA

CREATE TABLE CLIENTES_CUPOS_COMPRA AS
SELECT 
    c.numrun || '-' || c.dvrun AS RUT,
    (EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM c.fecha_nacimiento)) AS Edad,
    tc.cupo_disp_compra AS Cupo_Disponible
FROM cliente c
JOIN tarjeta_cliente tc
    ON c.numrun = tc.numrun
WHERE tc.cupo_disp_compra >=
      (SELECT MAX(tc2.cupo_disp_compra) --SUBCONSULTA: obtiene el máximo cupo disponible del año anterior al actual
       FROM tarjeta_cliente tc2
       WHERE EXTRACT(YEAR FROM tc2.fecha_solic_tarjeta) = 
             EXTRACT(YEAR FROM SYSDATE)-1)
ORDER BY Edad ASC;
