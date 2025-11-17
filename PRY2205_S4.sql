--CASO 1
SELECT
    INITCAP(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno) 
        AS "Nombre Completo Trabajador",

    t.numrut || '-' || t.dvrut AS "RUT Trabajador",

    INITCAP(tt.desc_categoria) AS "Tipo Trabajador",

    INITCAP(c.nombre_ciudad) AS "Ciudad Trabajador",

    TO_CHAR(t.sueldo_base, '$9G999G999') AS "Sueldo Base"

FROM trabajador t
JOIN tipo_trabajador tt 
    ON t.id_categoria_t = tt.id_categoria
JOIN comuna_ciudad c 
    ON t.id_ciudad = c.id_ciudad

WHERE t.sueldo_base BETWEEN 650000 AND 3000000

ORDER BY 
    c.nombre_ciudad DESC,
    t.sueldo_base ASC;
    
    --CASO 2
    SELECT
    t.numrut || '-' || t.dvrut AS "RUT Trabajador",

    INITCAP(t.nombre || ' ' || t.appaterno) AS "Nombre Trabajador",

    COUNT(tc.nro_ticket) AS "Total Tickets",

    TO_CHAR(SUM(tc.monto_ticket), '$9G999G999') AS "Total Vendido",

    TO_CHAR(SUM(ct.valor_comision), '$9G999G999') AS "Comisión Total",

    INITCAP(c.nombre_ciudad) AS "Ciudad Trabajador",

    INITCAP(tt.desc_categoria) AS "Tipo Trabajador"

FROM trabajador t
JOIN tipo_trabajador tt 
    ON t.id_categoria_t = tt.id_categoria
JOIN tickets_concierto tc
    ON t.numrut = tc.numrut_t
JOIN comisiones_ticket ct
    ON tc.nro_ticket = ct.nro_ticket
JOIN comuna_ciudad c
    ON t.id_ciudad = c.id_ciudad

WHERE UPPER(tt.desc_categoria) = 'CAJERO'

GROUP BY 
    t.numrut, t.dvrut, t.nombre, t.appaterno,
    c.nombre_ciudad, tt.desc_categoria

HAVING SUM(tc.monto_ticket) > 50000

ORDER BY SUM(tc.monto_ticket) DESC;

--CASO 3
SELECT
    t.numrut || '-' || t.dvrut AS "RUT Trabajador",

    INITCAP(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno)
        AS "Trabajador Nombre",

    EXTRACT(YEAR FROM t.fecing) AS "Año Ingreso",

    (EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM t.fecing)) 
        AS "Años Antigüedad",

    NVL((SELECT COUNT(*) 
         FROM asignacion_familiar af 
         WHERE af.numrut_t = t.numrut), 0) 
        AS "Num. Cargas Familiares",

    INITCAP(i.nombre_isapre) AS "Nombre Isapre",

    TO_CHAR(t.sueldo_base, '$9G999G999') AS "Sueldo Base",

    /* Bono Fonasa 1% */
    CASE 
        WHEN UPPER(i.nombre_isapre) = 'FONASA' 
             THEN TO_CHAR(ROUND(t.sueldo_base * 0.01), '$9G999G999')
        ELSE '$0'
    END AS "Bono Fonasa",

    /* Bono Antigüedad */
    TO_CHAR(
        CASE 
            WHEN (EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM t.fecing)) <= 10 
                THEN ROUND(t.sueldo_base * 0.10)
            ELSE ROUND(t.sueldo_base * 0.15)
        END,
        '$9G999G999'
    ) AS "Bono Antiguedad",

    INITCAP(ec.desc_estcivil) AS "Estado Civil"

FROM trabajador t
JOIN isapre i 
    ON t.cod_isapre = i.cod_isapre
JOIN est_civil est 
    ON t.numrut = est.numrut_t
JOIN estado_civil ec
    ON ec.id_estcivil = est.id_estcivil_est

WHERE (est.fecter_estcivil IS NULL 
       OR est.fecter_estcivil > SYSDATE)

ORDER BY t.numrut ASC;