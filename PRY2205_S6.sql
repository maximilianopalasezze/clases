/* ============================================================================
   CASO 1: Reporte de profesionales que han realizado asesorías tanto
            en BANCA (sector 3) como en RETAIL (sector 4).

   Objetivo:
   La gerencia quiere identificar a los consultores más versátiles, es decir,
   aquellos que han trabajado en ambos sectores.

   En este reporte calculo:
   - Número de asesorías en Banca y Retail.
   - Monto total de honorarios en cada sector.
   - Totales generales por profesional.
   - Nombre completo del profesional y su ID.
   ============================================================================ */

SELECT
       d.id_profesional                                    AS ID_PROFESIONAL,
       p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre AS NOMBRE_COMPLETO,

       /* Datos del sector Banca */
       SUM(CASE WHEN d.cod_sector = 3 THEN d.cant_asesorias ELSE 0 END)
            AS NRO_ASESORIAS_BANCA,
       SUM(CASE WHEN d.cod_sector = 3 THEN d.monto_honorarios ELSE 0 END)
            AS MONTO_TOTAL_BANCA,

       /* Datos del sector Retail */
       SUM(CASE WHEN d.cod_sector = 4 THEN d.cant_asesorias ELSE 0 END)
            AS NRO_ASESORIAS_RETAIL,
       SUM(CASE WHEN d.cod_sector = 4 THEN d.monto_honorarios ELSE 0 END)
            AS MONTO_TOTAL_RETAIL,

       /* Totales generales */
       SUM(d.cant_asesorias)                               AS TOTAL_ASESORIAS,
       SUM(d.monto_honorarios)                             AS TOTAL_HONORARIOS
FROM (
        /* --------------------------------------------------------------------
           Bloque BANCA: aquí selecciono solo asesorías del sector 3
           y calculo cantidad y montos agrupados por profesional.
           -------------------------------------------------------------------- */
        SELECT a.id_profesional,
               e.cod_sector,
               COUNT(*)            AS cant_asesorias,
               SUM(a.honorario)    AS monto_honorarios
        FROM   asesoria a
               JOIN empresa e ON a.cod_empresa = e.cod_empresa
        WHERE  e.cod_sector = 3
        GROUP BY a.id_profesional, e.cod_sector

        UNION ALL   

/* --------------------------------------------------------------------
        Bloque RETAIL: mismo proceso, pero para sector 4.
   -------------------------------------------------------------------- */
        SELECT a.id_profesional,
               e.cod_sector,
               COUNT(*)            AS cant_asesorias,
               SUM(a.honorario)    AS monto_honorarios
        FROM   asesoria a
               JOIN empresa e ON a.cod_empresa = e.cod_empresa
        WHERE  e.cod_sector = 4
        GROUP BY a.id_profesional, e.cod_sector
     ) d
     JOIN profesional p ON p.id_profesional = d.id_profesional

/* Solo  quienes trabajaron en ambos sectores */
GROUP BY d.id_profesional, p.appaterno, p.apmaterno, p.nombre
HAVING COUNT(DISTINCT d.cod_sector) = 2

ORDER BY ID_PROFESIONAL;

/* ============================================================================
   CASO 2 
   Crea la tabla donde se almacenará el reporte mensual.
   ============================================================================ */

CREATE TABLE REPORTE_MES (
    ID_PROFESIONAL          NUMBER(10),
    NOMBRE_COMPLETO         VARCHAR2(60),
    NOMBRE_PROFESION        VARCHAR2(25),
    NOM_COMUNA              VARCHAR2(20),
    NRO_ASESORIAS           NUMBER(3),
    MONTO_TOTAL_HONORARIOS  NUMBER(12),
    PROMEDIO_HONORARIO      NUMBER(12),
    HONORARIO_MINIMO        NUMBER(12),
    HONORARIO_MAXIMO        NUMBER(12)
);

/* ============================================================================
   Genera el reporte del mes de ABRIL del año pasado.

   Incluye:
   - Nombre completo del profesional.
   - Profesión.
   - Comuna.
   - Conteo de asesorías.
   - Monto total, promedio, mínimo y máximo.
   - Todos los valores redondeados 
   ============================================================================ */

INSERT INTO REPORTE_MES (
    ID_PROFESIONAL,
    NOMBRE_COMPLETO,
    NOMBRE_PROFESION,
    NOM_COMUNA,
    NRO_ASESORIAS,
    MONTO_TOTAL_HONORARIOS,
    PROMEDIO_HONORARIO,
    HONORARIO_MINIMO,
    HONORARIO_MAXIMO
)
SELECT
    p.id_profesional AS ID_PROFESIONAL,
    p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre AS NOMBRE_COMPLETO,
    pr.nombre_profesion AS NOMBRE_PROFESION,
    c.nom_comuna AS NOM_COMUNA,
   COUNT(a.id_profesional) AS NRO_ASESORIAS,
    ROUND(SUM(a.honorario)) AS MONTO_TOTAL_HONORARIOS,
    ROUND(AVG(a.honorario)) AS PROMEDIO_HONORARIO,
    ROUND(MIN(a.honorario)) AS HONORARIO_MINIMO,
    ROUND(MAX(a.honorario)) AS HONORARIO_MAXIMO
FROM profesional p
JOIN profesion pr ON pr.cod_profesion = p.cod_profesion
JOIN comuna c ON c.cod_comuna = p.cod_comuna
JOIN asesoria a ON a.id_profesional = p.id_profesional
WHERE a.fin_asesoria BETWEEN
      ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -9)
  AND LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -9))
GROUP BY
    p.id_profesional,
    p.appaterno,
    p.apmaterno,
    p.nombre,
    pr.nombre_profesion,
    c.nom_comuna;
/* ============================================================================
   Vista de la tabla REPORTE_MES con el formato ordenado por ID.
   ============================================================================ */

SELECT *
FROM   REPORTE_MES
ORDER BY ID_PROFESIONAL;

/* ============================================================================
   CASO 3 
   Reporte previo, donde calcula cuánto ganó cada profesional
   en marzo del año pasado. Aquí solo debo mostrar la situación actual.
   ============================================================================ */

SELECT
       SUM(a.honorario)        AS HONORARIO,
       p.id_profesional        AS ID_PROFESIONAL,
       p.numrun_prof           AS NUMRUM_PROF,
       p.sueldo                AS SUELDO
FROM   profesional p
       JOIN asesoria a ON a.id_profesional = p.id_profesional
WHERE  a.fin_asesoria BETWEEN
          ADD_MONTHS(TRUNC(SYSDATE,'YYYY'), -10)       /* Marzo año pasado */
      AND LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE,'YYYY'), -10))
GROUP BY
       p.id_profesional,
       p.numrun_prof,
       p.sueldo
ORDER BY ID_PROFESIONAL;

/* ============================================================================
   - Aquí actualiza el sueldo de los profesionales según sus honorarios:
   - Si en marzo del año pasado ganó menos de 1.000.000 → +10%
   - Si ganó 1.000.000 o más → +15%
   ============================================================================ */

UPDATE profesional p
SET p.sueldo =
  ROUND(
  CASE
  WHEN (
/* Total de honorarios del profesional en marzo del año pasado */
SELECT SUM(a.honorario)
 FROM asesoria a
 WHERE a.id_profesional = p.id_profesional
      AND a.fin_asesoria BETWEEN
       ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -10)
      AND LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -10))
        ) < 1000000
      THEN p.sueldo * 1.10   -- Aumento del 10%

      ELSE p.sueldo * 1.15   -- Aumento del 15%
END
)
WHERE EXISTS (
        /* Solo actualizar si realmente tuvo asesorías ese mes */
        SELECT 1
        FROM asesoria a
        WHERE a.id_profesional = p.id_profesional
        AND a.fin_asesoria BETWEEN
                ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -10)
        AND LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -10))
);

/* ============================================================================
   -Reporte final que muestra los sueldos ya actualizados, para comparar
   -contra el reporte anterior.
   ============================================================================ */

SELECT
       SUM(a.honorario)        AS HONORARIO,
       p.id_profesional        AS ID_PROFESIONAL,
       p.numrun_prof           AS NUMRUM_PROF,
       p.sueldo                AS SUELDO
FROM   profesional p
       JOIN asesoria a ON a.id_profesional = p.id_profesional
WHERE  a.fin_asesoria BETWEEN
          ADD_MONTHS(TRUNC(SYSDATE,'YYYY'), -10)
      AND LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE,'YYYY'), -10))
GROUP BY
       p.id_profesional,
       p.numrun_prof,
       p.sueldo
ORDER BY ID_PROFESIONAL;

