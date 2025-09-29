BEGIN
  FOR t IN (SELECT table_name FROM user_tables
            WHERE table_name IN ('TITULACION','DOMINIO','PERSONAL',
                                 'TITULO','GENERO','ESTADO_CIVIL',
                                 'COMPANIA','COMUNA','REGION','IDIOMA')) LOOP
  EXECUTE IMMEDIATE 'DROP TABLE '||t.table_name||' CASCADE CONSTRAINTS PURGE';
  END LOOP;
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  FOR s IN (SELECT sequence_name FROM user_sequences
  WHERE sequence_name IN ('SEQ_COMUNA','SEQ_COMPANIA')) LOOP
  EXECUTE IMMEDIATE 'DROP SEQUENCE '||s.sequence_name;
  END LOOP;
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
/* =========================================================
   1)CREACIÓN DE TABLAS
   ========================================================= */
-- REGION
CREATE TABLE REGION (
  id_region      NUMBER(2)
  GENERATED ALWAYS AS IDENTITY (START WITH 7 INCREMENT BY 2),
  nombre_region  VARCHAR2(25) NOT NULL,
  CONSTRAINT PK_REGION PRIMARY KEY (id_region)
);

-- COMUNA (FK -> REGION)
CREATE TABLE COMUNA (
  id_comuna     NUMBER(5)    NOT NULL,
  comuna_nombre VARCHAR2(25) NOT NULL,
  cod_region    NUMBER(2)    NOT NULL,
  CONSTRAINT PK_COMUNA PRIMARY KEY (id_comuna),
  CONSTRAINT FK_COMUNA_REGION FOREIGN KEY (cod_region)
  REFERENCES REGION(id_region)
);
-- COMPANIA (FK -> COMUNA, REGION)
CREATE TABLE COMPANIA (
  id_empresa      NUMBER(2)     NOT NULL,
  nombre_empresa  VARCHAR2(25)  NOT NULL,
  calle           VARCHAR2(50)  NOT NULL,
  numeracion      NUMBER(5)     NOT NULL,
  renta_promedio  NUMBER(10)    NOT NULL,
  pct_aumento     NUMBER(4,3),             
  cod_comuna      NUMBER(5)     NOT NULL,
  cod_region      NUMBER(2)     NOT NULL,
  CONSTRAINT PK_COMPANIA PRIMARY KEY (id_empresa),
  CONSTRAINT UQ_COMPANIA_NOMBRE UNIQUE (nombre_empresa),
  CONSTRAINT FK_COMPANIA_COMUNA FOREIGN KEY (cod_comuna)
  REFERENCES COMUNA(id_comuna),
  CONSTRAINT FK_COMPANIA_REGION FOREIGN KEY (cod_region)
  REFERENCES REGION(id_region)
);

-- ESTADO_CIVIL
CREATE TABLE ESTADO_CIVIL (
  id_estado_civil       VARCHAR2(2)  NOT NULL,
  descripcion_est_civil VARCHAR2(25) NOT NULL,
  CONSTRAINT PK_ESTADO_CIVIL PRIMARY KEY (id_estado_civil)
);
-- GENERO
CREATE TABLE GENERO (
  id_genero           VARCHAR2(3)  NOT NULL,
  descripcion_genero  VARCHAR2(25) NOT NULL,
  CONSTRAINT PK_GENERO PRIMARY KEY (id_genero)
);
-- TITULO
CREATE TABLE TITULO (
  id_titulo           VARCHAR2(3)  NOT NULL,
  descripcion_titulo  VARCHAR2(60) NOT NULL,
  CONSTRAINT PK_TITULO PRIMARY KEY (id_titulo)
);
-- PERSONAL (FK -> COMPANIA, COMUNA, REGION, ESTADO_CIVIL, GENERO, self FK)
CREATE TABLE PERSONAL (
  rut_persona        NUMBER(8)     NOT NULL,
  dv_persona         CHAR(1)       NOT NULL,
  primer_nombre      VARCHAR2(25)  NOT NULL,
  segundo_nombre     VARCHAR2(25),
  primer_apellido    VARCHAR2(25)  NOT NULL,
  segundo_apellido   VARCHAR2(25),
  fecha_contratacion DATE,
  fecha_nacimiento   DATE,
  email              VARCHAR2(100),
  calle              VARCHAR2(50)  NOT NULL,
  numeracion         NUMBER(5)     NOT NULL,
  sueldo             NUMBER(10)    NOT NULL,
  cod_comuna         NUMBER(5)     NOT NULL,
  cod_region         NUMBER(2)     NOT NULL,
  cod_genero         VARCHAR2(3)   NOT NULL,
  cod_estado_civil   VARCHAR2(2)   NOT NULL,
  cod_empresa        NUMBER(2)     NOT NULL,
  encargado_rut      NUMBER(8),
  CONSTRAINT PK_PERSONAL PRIMARY KEY (rut_persona),
  CONSTRAINT FK_PERS_COMPANIA  FOREIGN KEY (cod_empresa)
    REFERENCES COMPANIA(id_empresa),
  CONSTRAINT FK_PERS_COMUNA    FOREIGN KEY (cod_comuna)
    REFERENCES COMUNA(id_comuna),
  CONSTRAINT FK_PERS_REGION    FOREIGN KEY (cod_region)
    REFERENCES REGION(id_region),
  CONSTRAINT FK_PERS_GENERO    FOREIGN KEY (cod_genero)
    REFERENCES GENERO(id_genero),
  CONSTRAINT FK_PERS_ESTCIVIL  FOREIGN KEY (cod_estado_civil)
    REFERENCES ESTADO_CIVIL(id_estado_civil),
  CONSTRAINT FK_PERS_ENCARGADO FOREIGN KEY (encargado_rut)
    REFERENCES PERSONAL(rut_persona)
);
-- IDIOMA
CREATE TABLE IDIOMA (
  id_idioma     NUMBER(3)
    GENERATED ALWAYS AS IDENTITY (START WITH 25 INCREMENT BY 3),
  nombre_idioma VARCHAR2(30) NOT NULL,
  CONSTRAINT PK_IDIOMA PRIMARY KEY (id_idioma)
);
-- DOMINIO (PF: id_idioma + persona_rut)
CREATE TABLE DOMINIO (
  id_idioma   NUMBER(3)  NOT NULL,
  persona_rut NUMBER(8)  NOT NULL,
  nivel       VARCHAR2(25),
  CONSTRAINT PK_DOMINIO PRIMARY KEY (id_idioma, persona_rut),
  CONSTRAINT FK_DOMINIO_IDIOMA   FOREIGN KEY (id_idioma)
    REFERENCES IDIOMA(id_idioma),
  CONSTRAINT FK_DOMINIO_PERSONAL FOREIGN KEY (persona_rut)
    REFERENCES PERSONAL(rut_persona)
);
-- TITULACION (PF: cod_titulo + persona_rut)
CREATE TABLE TITULACION (
  cod_titulo       VARCHAR2(3) NOT NULL,
  persona_rut      NUMBER(8)   NOT NULL,
  fecha_titulacion DATE,
  CONSTRAINT PK_TITULACION PRIMARY KEY (cod_titulo, persona_rut),
  CONSTRAINT FK_TITULACION_TITULO   FOREIGN KEY (cod_titulo)
    REFERENCES TITULO(id_titulo),
  CONSTRAINT FK_TITULACION_PERSONAL FOREIGN KEY (persona_rut)
    REFERENCES PERSONAL(rut_persona)
);
/* =========================================================
   2) CASO 2  REGLAS EXTRA (ALTER TABLE)
   ========================================================= */
ALTER TABLE PERSONAL
  ADD CONSTRAINT UQ_PERSONAL_EMAIL UNIQUE (email);

ALTER TABLE PERSONAL
  ADD CONSTRAINT CK_PERSONAL_DV
  CHECK (UPPER(dv_persona) IN ('0','1','2','3','4','5','6','7','8','9','K'));

ALTER TABLE PERSONAL
  ADD CONSTRAINT CK_PERSONAL_SUELDO_MIN CHECK (sueldo >= 450000);

 
/* =========================================================
   3) CASO 3  SECUENCIAS Y POBLAMIENTO
   ========================================================= */

-- SECUENCIAS: COMUNA 
CREATE SEQUENCE SEQ_COMUNA   START WITH 1101 INCREMENT BY 6 NOCACHE;
CREATE SEQUENCE SEQ_COMPANIA START WITH 10   INCREMENT BY 5 NOCACHE;

-- REGION 
INSERT INTO REGION (nombre_region) VALUES ('ARICA Y PARINACOTA');
INSERT INTO REGION (nombre_region) VALUES ('METROPOLITANA');
INSERT INTO REGION (nombre_region) VALUES ('LA ARAUCANIA');

-- COMUNA 
INSERT INTO COMUNA (id_comuna, comuna_nombre, cod_region)
VALUES (SEQ_COMUNA.NEXTVAL, 'Arica',     7);   -- 1101
INSERT INTO COMUNA (id_comuna, comuna_nombre, cod_region)
VALUES (SEQ_COMUNA.NEXTVAL, 'Santiago',  9);   -- 1107
INSERT INTO COMUNA (id_comuna, comuna_nombre, cod_region)
VALUES (SEQ_COMUNA.NEXTVAL, 'Temuco',   11);   -- 1113

-- IDIOMA 
INSERT INTO IDIOMA (nombre_idioma) VALUES ('Ingles');
INSERT INTO IDIOMA (nombre_idioma) VALUES ('Chino');
INSERT INTO IDIOMA (nombre_idioma) VALUES ('Aleman');
INSERT INTO IDIOMA (nombre_idioma) VALUES ('Espanol');
INSERT INTO IDIOMA (nombre_idioma) VALUES ('Frances');

-- COMPANIA 
INSERT INTO COMPANIA (id_empresa,nombre_empresa,calle,numeracion,renta_promedio,pct_aumento,cod_comuna,cod_region)
VALUES (SEQ_COMPANIA.NEXTVAL,'CCyRojas','Amapolas',506,1857000,0.500,1101,7);

INSERT INTO COMPANIA (id_empresa,nombre_empresa,calle,numeracion,renta_promedio,pct_aumento,cod_comuna,cod_region)
VALUES (SEQ_COMPANIA.NEXTVAL,'SenTTy','Los Alamos',3490,897000,0.025,1107,9);

INSERT INTO COMPANIA (id_empresa,nombre_empresa,calle,numeracion,renta_promedio,pct_aumento,cod_comuna,cod_region)
VALUES (SEQ_COMPANIA.NEXTVAL,'Praxia LTDA','Las Camelias',11098,2157000,0.035,1107,9);

INSERT INTO COMPANIA (id_empresa,nombre_empresa,calle,numeracion,renta_promedio,pct_aumento,cod_comuna,cod_region)
VALUES (SEQ_COMPANIA.NEXTVAL,'TIC spa','FLORES S.A.',4357,857000,NULL,1107,9);

INSERT INTO COMPANIA (id_empresa,nombre_empresa,calle,numeracion,renta_promedio,pct_aumento,cod_comuna,cod_region)
VALUES (SEQ_COMPANIA.NEXTVAL,'SANTANA LTDA','AVDA VIC. MACKENA',106,757000,0.015,1101,7);

INSERT INTO COMPANIA (id_empresa,nombre_empresa,calle,numeracion,renta_promedio,pct_aumento,cod_comuna,cod_region)
VALUES (SEQ_COMPANIA.NEXTVAL,'FLORES Y ASOCIADOS','PEDRO LATORRE',557,589000,0.015,1107,9);

INSERT INTO COMPANIA (id_empresa,nombre_empresa,calle,numeracion,renta_promedio,pct_aumento,cod_comuna,cod_region)
VALUES (SEQ_COMPANIA.NEXTVAL,'J.A. HOFFMAN','LATINA D.32',509,1857000,0.025,1113,11);

INSERT INTO COMPANIA (id_empresa,nombre_empresa,calle,numeracion,renta_promedio,pct_aumento,cod_comuna,cod_region)
VALUES (SEQ_COMPANIA.NEXTVAL,'CAGLIARI D.','ALAMEDA',206,1857000,NULL,1107,9);

INSERT INTO COMPANIA (id_empresa,nombre_empresa,calle,numeracion,renta_promedio,pct_aumento,cod_comuna,cod_region)
VALUES (SEQ_COMPANIA.NEXTVAL,'Rojas HNOS LTDA','SUCRE',106,957000,0.005,1113,11);

INSERT INTO COMPANIA (id_empresa,nombre_empresa,calle,numeracion,renta_promedio,pct_aumento,cod_comuna,cod_region)
VALUES (SEQ_COMPANIA.NEXTVAL,'FRIENDS P. S.A','SUECIA',506,857000,0.015,1113,11);

COMMIT;
/* =========================================================
   4) REPORTES (SELECT)
   ========================================================= */

-- INFORME 1: Nombre, Dirección, Renta, Simulación
-- Orden: Renta DESC, luego Nombre ASC
SELECT
  c.nombre_empresa                   AS "Nombre Empresa",
  c.calle || ' ' || c.numeracion     AS "Dirección",
  c.renta_promedio                   AS "Renta Promedio",
  CASE WHEN c.pct_aumento IS NULL THEN NULL
       ELSE ROUND(c.renta_promedio * (1 + c.pct_aumento)) END
                                      AS "Simulación de Renta"
FROM COMPANIA c
ORDER BY c.nombre_empresa ASC, c.renta_promedio DESC;

-- INFORME 2: +15% a pct; renta_aumentada
-- Orden: renta ASC, luego nombre DESC
SELECT
  c.id_empresa                       AS "CODIGO",
  c.nombre_empresa                   AS "EMPRESA",
  c.renta_promedio                   AS "PROM RENTA ACTUAL",
  CASE WHEN c.pct_aumento IS NULL THEN NULL
       ELSE ROUND(c.pct_aumento + 0.15, 3) END
                                      AS "PCT AUMENTADO EN 15%",
  CASE WHEN c.pct_aumento IS NULL THEN NULL
       ELSE ROUND(c.renta_promedio * (c.pct_aumento + 0.15)) END
                                      AS "RENTA AUMENTADA"
FROM COMPANIA c
ORDER BY c.id_empresa ASC, c.renta_promedio ASC, c.nombre_empresa DESC;
