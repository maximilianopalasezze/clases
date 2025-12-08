/* 
   CASO 1 – Simulación de Bonificaciones
   -------------------------------------
   Insertamos en DETALLE_BONIFICACIONES_TRABAJADOR los valores simulados
   para bonificación por ticket y antigüedad. Este proceso sirve para que 
   Finanzas proyecte el impacto presupuestario antes de aplicar aumentos reales.

   Detalles clave:
   - Reglas de negocio aplicadas según monto del ticket.
   - Antigüedad calculada por MONTHS_BETWEEN usando Non-Equi Join.
   - Uso de sinónimos para mantener independencia del esquema.
   - Filtro: trabajadores con descuento de salud > 4% y menos de 50 años.
*/
-- SINÓNIMOS PRIVADOS
CREATE SYNONYM s_bono_antiguedad   FOR bono_antiguedad;
CREATE SYNONYM s_tickets_concierto FOR tickets_concierto;


INSERT INTO detalle_bonificaciones_trabajador (
       num,
       rut,
       nombre_trabajador,
       sueldo_base,
       num_ticket,
       direccion,
       sistema_salud,
       monto,
       bonif_x_ticket,
       simulacion_x_ticket,
       simulacion_antiguedad
)
SELECT
       seq_det_bonif.NEXTVAL AS num,
       LTRIM(TO_CHAR(t.numrut, '99G999G999G9',
             'NLS_NUMERIC_CHARACTERS = ",."')) || '-' || t.dvrut AS rut,
       t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno       AS nombre_trabajador,
       TO_CHAR(t.sueldo_base,
               'FM$999G999G999',
               'NLS_NUMERIC_CHARACTERS = ",."')                   AS sueldo_base,
       NVL(TO_CHAR(tc.nro_ticket), 'No hay info')                 AS num_ticket,
       t.direccion                                                AS direccion,
       i.nombre_isapre                                            AS sistema_salud,
       TO_CHAR(NVL(tc.monto_ticket, 0),
               'FM$999G999G999',
               'NLS_NUMERIC_CHARACTERS = ",."')                   AS monto,
       TO_CHAR(
         CASE
           WHEN tc.monto_ticket IS NULL OR tc.monto_ticket <= 50000
                THEN 0
           WHEN tc.monto_ticket > 50000 AND tc.monto_ticket <= 100000
                THEN ROUND(tc.monto_ticket * 0.05)
           WHEN tc.monto_ticket > 100000
                THEN ROUND(tc.monto_ticket * 0.07)
         END,
         'FM$999G999G999',
         'NLS_NUMERIC_CHARACTERS = ",."')                         AS bonif_x_ticket,
       TO_CHAR(
         t.sueldo_base +
         CASE
           WHEN tc.monto_ticket IS NULL OR tc.monto_ticket <= 50000
                THEN 0
           WHEN tc.monto_ticket > 50000 AND tc.monto_ticket <= 100000
                THEN ROUND(tc.monto_ticket * 0.05)
           WHEN tc.monto_ticket > 100000
                THEN ROUND(tc.monto_ticket * 0.07)
         END,
         'FM$999G999G999',
         'NLS_NUMERIC_CHARACTERS = ",."')                         AS simulacion_x_ticket,
       TO_CHAR(
         t.sueldo_base * (1 + ba.porcentaje),
         'FM$999G999G999',
         'NLS_NUMERIC_CHARACTERS = ",."')                         AS simulacion_antiguedad
FROM   s_trabajador        t
       JOIN isapre         i  ON i.cod_isapre = t.cod_isapre
       JOIN s_bono_antiguedad ba
            ON TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecing) / 12)
               BETWEEN ba.limite_inferior AND ba.limite_superior
       LEFT JOIN s_tickets_concierto tc
            ON tc.numrut_t = t.numrut
WHERE  i.porc_descto_isapre > 4
AND    TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecnac) / 12) < 50;

/* 
   CASO 2 – Vista V_AUMENTOS_ESTUDIOS
   Vista que calcula el aumento de sueldo según nivel de estudios.
   Incluye trabajadores CAJEROS o con 1–2 cargas familiares.
*/

CREATE OR REPLACE SYNONYM s_trabajador FOR trabajador;
CREATE OR REPLACE SYNONYM s_bono_escolar FOR bono_escolar;

CREATE OR REPLACE VIEW v_aumentos_estudios AS
SELECT
       -- RUT con formato
       LTRIM(TO_CHAR(t.numrut, '99G999G999G9',
             'NLS_NUMERIC_CHARACTERS = ",."')) || '-' || t.dvrut 
             AS rut_trabajador,

       -- Nombre completo
       t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno AS trabajador,

       -- Nombre del nivel de estudios 
       be.descrip AS descrip,

       -- Porcentaje 
       TO_CHAR(be.porc_bono, 'FM0000000') AS pct_estudios,

       -- Sueldo actual
       t.sueldo_base AS sueldo_actual,

       -- Aumento calculado
       ROUND(t.sueldo_base * (be.porc_bono / 100)) AS aumento,

       -- Sueldo aumentado
       ROUND(t.sueldo_base * (1 + (be.porc_bono / 100))) AS sueldo_aumentado

FROM   s_trabajador t
       JOIN s_bono_escolar be
            ON t.id_escolaridad_t = be.id_escolar

WHERE  
       -- Cajeros
       t.id_categoria_t IN (
           SELECT id_categoria_t
           FROM tipo_trabajador
           WHERE UPPER(descrip) = 'CAJERO'
       )

       OR

       -- 1 o 2 cargas familiares
       (SELECT COUNT(*)
        FROM asignacion_familiar af
        WHERE af.numrut_t = t.numrut) BETWEEN 1 AND 2

ORDER BY
       be.porc_bono ASC,
       t.nombre ASC, t.appaterno ASC, t.apmaterno ASC;
       
-- CASO 3: OPTIMIZACIÓN DE CONSULTAS (Filtrar por apellido materno)
-- Se incluyen:
-- 1) Consulta original (Figura 6)
-- 2) Consulta usando UPPER (Figura 7)
-- 3) Creación de índice B-Tree
-- 4) Creación de índice Function-Based
       
       /* Consulta base: filtra trabajadores cuyo apellido materno es CASTILLO */
SELECT  t.numrut      AS rut_trabajador,
        t.fecnac      AS fecha_nacimiento,
        t.nombre      AS nombre,
        t.appaterno   AS apellido_paterno,
        t.apmaterno   AS apellido_materno
FROM trabajador t
     JOIN isapre i ON i.cod_isapre = t.cod_isapre
WHERE t.apmaterno = 'CASTILLO'
ORDER BY 3;

/* Consulta usando UPPER para filtrar por apellido materno */
SELECT  t.numrut      AS rut_trabajador,
        t.fecnac      AS fecha_nacimiento,
        t.nombre      AS nombre,
        t.appaterno   AS apellido_paterno,
        t.apmaterno   AS apellido_materno
FROM trabajador t
     JOIN isapre i ON i.cod_isapre = t.cod_isapre
WHERE UPPER(t.apmaterno) = 'CASTILLO'
ORDER BY 3;

/* Index B-Tree para optimizar el filtro por apellido materno */
CREATE INDEX idx_trabajador_apm
    ON trabajador (apmaterno);
    
/* Index function-based para optimizar el filtro usando UPPER */
CREATE INDEX idx_trabajador_apm_upper
    ON trabajador (UPPER(apmaterno));