/* ============================================================
   CASO 1: Estrategia de seguridad
   - Crear roles
   - Crear usuarios con cuota
   - Asignar roles y privilegios mínimos
   - IMPORTANTE EJECUTAR ESTE BLOQUE COMO SYSDBA/SYSTEM
============================================================ */
SHOW CON_NAME;
ALTER SESSION SET CONTAINER = XEPDB1;

-- Limpieza (si da error porque no existen)
DROP USER PRY2205_USER1 CASCADE;
DROP USER PRY2205_USER2 CASCADE;
DROP ROLE PRY2205_ROL_D;
DROP ROLE PRY2205_ROL_P;

-- 1) Roles
CREATE ROLE PRY2205_ROL_D;  -- dueño del esquema
CREATE ROLE PRY2205_ROL_P;  -- usuario consultor

-- 2) Privilegios de sistema (mínimos)
GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE TO PRY2205_ROL_D;
GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE TO PRY2205_ROL_P;

-- 3) Usuarios (con quota y tablespaces)
CREATE USER PRY2205_USER1
IDENTIFIED BY PRY2205_USER1
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON USERS;

CREATE USER PRY2205_USER2
IDENTIFIED BY PRY2205_USER2
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON USERS;

-- 4) Asignación de roles
GRANT PRY2205_ROL_D TO PRY2205_USER1;
GRANT PRY2205_ROL_P TO PRY2205_USER2;

-- 5) Privilegios adicionales requeridos 
GRANT CREATE SYNONYM TO PRY2205_USER1;
GRANT CREATE SYNONYM TO PRY2205_USER2;
GRANT CREATE VIEW TO PRY2205_USER1;

/* ============================================================
   - CASO 2:
   - Creacion de PRY2205_USER1
   - Conceder permisos de lectura a USER2 (para que pueda consultar)
   - Crear sinónimos (privados) 
   - Crear Vista VW_DETALLE_MULTAS 
   - Crear índices para optimizar 
   - IMPORTANTE CAMBIAR CONEXIÓN A PRY2205_USER1 Y EJECUTAR DESDE AQUÍ 
============================================================ */

-- GRANTS: permitir que USER2 pueda leer las tablas del esquema
GRANT SELECT ON ESCUELA TO PRY2205_USER2;
GRANT SELECT ON ALUMNO TO PRY2205_USER2;
GRANT SELECT ON CARRERA TO PRY2205_USER2;
GRANT SELECT ON LIBRO TO PRY2205_USER2;
GRANT SELECT ON AUTOR TO PRY2205_USER2;
GRANT SELECT ON PRESTAMO TO PRY2205_USER2;
GRANT SELECT ON DETALLE_PRESTAMO_MENSUAL TO PRY2205_USER2;
GRANT SELECT ON REBAJA_MULTA TO PRY2205_USER2;
GRANT SELECT ON VALOR_MULTA_PRESTAMO TO PRY2205_USER2;
GRANT SELECT ON EJEMPLAR TO PRY2205_USER2;

-- SINÓNIMOS PRIVADOS 
DROP SYNONYM s_alumno;
DROP SYNONYM s_carrera;
DROP SYNONYM s_libro;
DROP SYNONYM s_prestamo;
DROP SYNONYM s_rebaja_multa;

CREATE SYNONYM s_alumno       FOR PRY2205_USER1.ALUMNO;
CREATE SYNONYM s_carrera      FOR PRY2205_USER1.CARRERA;
CREATE SYNONYM s_libro        FOR PRY2205_USER1.LIBRO;
CREATE SYNONYM s_prestamo     FOR PRY2205_USER1.PRESTAMO;
CREATE SYNONYM s_rebaja_multa FOR PRY2205_USER1.REBAJA_MULTA;

-- VISTA VW_DETALLE_MULTAS 
CREATE OR REPLACE VIEW vw_detalle_multas AS
SELECT
    p.prestamoid                                   AS id_prestamo,
    a.nombre || ' ' || a.apaterno || ' ' || a.amaterno
                                                   AS nombre_alumno,
    c.descripcion                                  AS nombre_carrera,
    l.libroid                                      AS id_libro,
    TO_CHAR(l.precio, '$999G999G999')              AS valor_libro,
    p.fecha_termino,
    p.fecha_entrega,
    (p.fecha_entrega - p.fecha_termino)            AS dias_atraso,
    TO_CHAR(
        ROUND((p.fecha_entrega - p.fecha_termino) * (l.precio * 0.03), 0),
        '$999G999G999'
    )                                              AS valor_multa,
    NVL(r.porc_rebaja_multa, 0) / 100               AS porcentaje_rebaja_multa,
    TO_CHAR(
        ROUND(
          (p.fecha_entrega - p.fecha_termino) * (l.precio * 0.03)
          * (1 - NVL(r.porc_rebaja_multa, 0) / 100),
          0
        ),
        '$999G999G999'
    )                                              AS valor_rebajado
FROM s_prestamo p
JOIN s_alumno a       ON p.alumnoid = a.alumnoid
JOIN s_carrera c      ON a.carreraid = c.carreraid
JOIN s_libro l        ON p.libroid = l.libroid
LEFT JOIN s_rebaja_multa r ON c.carreraid = r.carreraid
WHERE p.fecha_entrega > p.fecha_termino
  AND EXTRACT(YEAR FROM p.fecha_termino) = EXTRACT(YEAR FROM SYSDATE) - 2
ORDER BY p.fecha_entrega DESC;

SELECT * FROM vw_detalle_multas;


--ÍNDICE basado en función
CREATE INDEX idx_prestamo_anio_termino
ON PRESTAMO (EXTRACT(YEAR FROM fecha_termino));

-- Evidencia de plan
EXPLAIN PLAN FOR
SELECT * FROM vw_detalle_multas;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

/* ============================================================
   - CASO 3:
   - Creacion de PRY2205_USER2
   - Crear sinónimos (apuntando al esquema de USER1)
   - Crear secuencia SEQ_CONTROL_STOCK
   - Crear tabla CONTROL_STOCK_LIBROS
   - Insertar informe 
   - IMPORTANTE CAMBIAR CONEXIÓN A PRY2205_USER2 Y EJECUTAR DESDE AQUÍ 
============================================================ */

-- SINÓNIMOS (privados) para acceder sin usar el nombre real de tablas
DROP SYNONYM s_libro;
DROP SYNONYM s_prestamo;
DROP SYNONYM s_ejemplar;

CREATE SYNONYM s_libro     FOR PRY2205_USER1.LIBRO;
CREATE SYNONYM s_prestamo  FOR PRY2205_USER1.PRESTAMO;
CREATE SYNONYM s_ejemplar  FOR PRY2205_USER1.EJEMPLAR;

-- Secuencia correlativa 
DROP SEQUENCE seq_control_stock;

CREATE SEQUENCE seq_control_stock
START WITH 1
INCREMENT BY 1;

-- Tabla de control
DROP TABLE control_stock_libros;

CREATE TABLE control_stock_libros (
    id_control           NUMBER,
    libro_id             NUMBER,
    nombre_libro         VARCHAR2(200),
    total_ejemplares     NUMBER,
    en_prestamo          NUMBER,
    disponibles          NUMBER,
    porcentaje_prestamo  NUMBER(5,2),
    stock_critico        CHAR(1)
);

-- Insert del informe 
INSERT INTO control_stock_libros
SELECT
    seq_control_stock.NEXTVAL       AS id_control,
    t.libro_id,
    t.nombre_libro,
    t.total_ejemplares,
    t.en_prestamo,
    t.disponibles,
    t.porcentaje_prestamo,
    t.stock_critico
FROM (
    SELECT
        l.libroid                       AS libro_id,
        l.nombre_libro                  AS nombre_libro,
        COUNT(DISTINCT e.ejemplarid)    AS total_ejemplares,
        COUNT(p.prestamoid)             AS en_prestamo,
        COUNT(DISTINCT e.ejemplarid)
          - COUNT(p.prestamoid)         AS disponibles,
        NVL(
    ROUND(
        (COUNT(p.prestamoid)
        / NULLIF(COUNT(DISTINCT e.ejemplarid), 0)) * 100,
        2
    ),
    0
) AS porcentaje_prestamo,
        CASE
            WHEN (COUNT(DISTINCT e.ejemplarid)
                  - COUNT(p.prestamoid)) > 2
            THEN 'S'
            ELSE 'N'
        END                             AS stock_critico
    FROM s_libro l
    LEFT JOIN s_ejemplar e
           ON l.libroid = e.libroid
    LEFT JOIN s_prestamo p
           ON e.libroid = p.libroid
          AND e.ejemplarid = p.ejemplarid
          AND EXTRACT(YEAR FROM p.fecha_inicio)
              = EXTRACT(YEAR FROM SYSDATE) - 2
          AND p.empleadoid IN (190, 180, 150)
    GROUP BY
        l.libroid,
        l.nombre_libro
) t;

-- Consulta final de verificación (ordenado por id libro)
SELECT *
FROM control_stock_libros
ORDER BY libro_id;


