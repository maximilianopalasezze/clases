SET DEFINE ON;
UNDEFINE RENTA_MINIMA RENTA_MAXIMA SUELDO_PROMEDIO_MINIMO;

--------------------------------------------------------------------
-- CASO 1: Listado de clientes con rango de renta
-- Objetivo: Mostrar clientes cuyo monto de renta esté entre un rango definido
-- por el usuario, con RUT formateado, nombre completo, dirección, celular y
-- tramo de renta. Se filtran solo los que tengan número de celular y se ordenan
-- alfabéticamente por nombre completo.
--------------------------------------------------------------------
SELECT
  TO_CHAR(c.numrut_cli,'FM999G999G999G999','NLS_NUMERIC_CHARACTERS=,.')
    || '-' || c.dvrut_cli AS "RUT Cliente",
  INITCAP(TRIM(c.nombre_cli) || ' ' || TRIM(c.appaterno_cli) || ' ' ||
          TRIM(c.apmaterno_cli)) AS "Nombre Completo Cliente",
  c.direccion_cli AS "Dirección Cliente",
  '$' || TO_CHAR(c.renta_cli,'FM999G999G999','NLS_NUMERIC_CHARACTERS=,.') AS "Renta Cliente",
  SUBSTR(LPAD(TO_CHAR(c.celular_cli),9,'0'),1,2) || '-' ||
  SUBSTR(LPAD(TO_CHAR(c.celular_cli),9,'0'),3,3) || '-' ||
  SUBSTR(LPAD(TO_CHAR(c.celular_cli),9,'0'),6,4) AS "Celular Cliente",
  CASE
    WHEN c.renta_cli > 500000 THEN 'TRAMO 1'
    WHEN c.renta_cli BETWEEN 400000 AND 500000 THEN 'TRAMO 2'
    WHEN c.renta_cli BETWEEN 200000 AND 399999 THEN 'TRAMO 3'
    ELSE 'TRAMO 4'
  END AS "Tramo Renta Cliente"
FROM cliente c
WHERE c.celular_cli IS NOT NULL
  AND c.renta_cli BETWEEN &RENTA_MINIMA AND &RENTA_MAXIMA
ORDER BY "Nombre Completo Cliente";

--------------------------------------------------------------------
-- CASO 2: Sueldo promedio por categoría y sucursal
-- Objetivo: Calcular el promedio de sueldo de los empleados agrupados por
-- categoría y sucursal. Se muestra el código y descripción de la categoría,
-- la sucursal, la cantidad de empleados y el sueldo promedio formateado con signo $.
-- Solo se consideran las categorías con sueldo promedio mayor o igual al valor
-- ingresado por el usuario, y los resultados se ordenan por sueldo promedio descendente.
--------------------------------------------------------------------
SELECT
  ce.id_categoria_emp   AS "CODIGO_CATEGORIA",
  ce.desc_categoria_emp AS "DESCRIPCION_CATEGORIA",
  COUNT(*)              AS "CANTIDAD_EMPLEADOS",
  TO_CHAR(s.id_sucursal) || ' ' || s.desc_sucursal AS "SUCURSAL",
  '$' || TO_CHAR(ROUND(AVG(e.sueldo_emp)),
       'FM999G999G999','NLS_NUMERIC_CHARACTERS=,.') AS "SUELDO_PROMEDIO"
FROM empleado e
JOIN categoria_empleado ce ON ce.id_categoria_emp = e.id_categoria_emp
JOIN sucursal s            ON s.id_sucursal      = e.id_sucursal
GROUP BY
  ce.id_categoria_emp,
  ce.desc_categoria_emp,
  (TO_CHAR(s.id_sucursal) || ' ' || s.desc_sucursal)
HAVING AVG(e.sueldo_emp) >= &SUELDO_PROMEDIO_MINIMO
ORDER BY AVG(e.sueldo_emp) DESC;

--------------------------------------------------------------------
-- CASO 3: Arriendo promedio por tipo de propiedad
-- Objetivo: Mostrar indicadores de arriendo agrupados por tipo de propiedad:
-- total de propiedades, promedio de arriendo, promedio de superficie y valor
-- de arriendo por metro cuadrado. Además, clasifica cada tipo como “Económico”,
-- “Medio” o “Alto” según el promedio de valor por m². Se muestran solo los tipos
-- con valor promedio por m² superior a 1000, ordenados de mayor a menor.
--------------------------------------------------------------------
SELECT
  tp.id_tipo_propiedad   AS "CODIGO_TIPO",
  tp.desc_tipo_propiedad AS "DESCRIPCION_TIPO",
  COUNT(*)               AS "TOTAL_PROPIEDADES",
  '$' || TO_CHAR(ROUND(AVG(p.valor_arriendo)),
       'FM999G999G999','NLS_NUMERIC_CHARACTERS=,.') AS "PROMEDIO_ARRIENDO",
  TO_CHAR(ROUND(AVG(p.superficie)),
       'FM999G999','NLS_NUMERIC_CHARACTERS=,.')     AS "PROMEDIO_SUPERFICIE",
  '$' || TO_CHAR(ROUND(AVG(p.valor_arriendo/NULLIF(p.superficie,0))),
       'FM999G999','NLS_NUMERIC_CHARACTERS=,.')     AS "VALOR_ARRIENDO_M2",
  CASE
    WHEN AVG(p.valor_arriendo/NULLIF(p.superficie,0)) < 5000  THEN 'Económico'
    WHEN AVG(p.valor_arriendo/NULLIF(p.superficie,0)) BETWEEN 5000 AND 10000 THEN 'Medio'
    ELSE 'Alto'
  END AS "CLASIFICACION"
FROM propiedad p
JOIN tipo_propiedad tp ON tp.id_tipo_propiedad = p.id_tipo_propiedad
GROUP BY tp.id_tipo_propiedad, tp.desc_tipo_propiedad
HAVING AVG(p.valor_arriendo/NULLIF(p.superficie,0)) > 1000
ORDER BY AVG(p.valor_arriendo/NULLIF(p.superficie,0)) DESC;