------------------------------------------------------
-- ELIMINACIÓN PREVIA (Tablas y Secuencias)
------------------------------------------------------
DROP TABLE DETALLE_VENTA CASCADE CONSTRAINTS;
DROP TABLE VENTA CASCADE CONSTRAINTS;
DROP TABLE PRODUCTO CASCADE CONSTRAINTS;
DROP TABLE MARCA CASCADE CONSTRAINTS;
DROP TABLE CATEGORIA CASCADE CONSTRAINTS;
DROP TABLE PROVEEDOR CASCADE CONSTRAINTS;
DROP TABLE EMPLEADO CASCADE CONSTRAINTS;
DROP TABLE VENDEDOR CASCADE CONSTRAINTS;
DROP TABLE AFP CASCADE CONSTRAINTS;
DROP TABLE SALUD CASCADE CONSTRAINTS;
DROP TABLE MEDIO_PAGO CASCADE CONSTRAINTS;
DROP TABLE REGION CASCADE CONSTRAINTS;

DROP SEQUENCE seq_salud;
DROP SEQUENCE seq_empleado;

------------------------------------------------------
-- CREACIÓN DE TABLAS
------------------------------------------------------
CREATE TABLE REGION (
    id_region NUMBER,
    nombre    VARCHAR2(100) NOT NULL,
    CONSTRAINT region_pk PRIMARY KEY (id_region)
);

CREATE TABLE PROVEEDOR (
    id_proveedor NUMBER,
    nombre       VARCHAR2(100) NOT NULL,
    correo       VARCHAR2(100),
    telefono     VARCHAR2(20),
    direccion    VARCHAR2(150),
    id_region    NUMBER,
  CONSTRAINT proveedor_pk PRIMARY KEY (id_proveedor),
  CONSTRAINT proveedor_region_fk FOREIGN KEY (id_region) REFERENCES REGION(id_region),
  CONSTRAINT proveedor_correo_un UNIQUE (correo)
);

CREATE TABLE AFP (
    id_afp NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 210 INCREMENT BY 6),
    nombre VARCHAR2(100) NOT NULL,
    CONSTRAINT afp_pk PRIMARY KEY (id_afp)
);

CREATE TABLE SALUD (
    id_salud NUMBER,
    nombre   VARCHAR2(100) NOT NULL,
    CONSTRAINT salud_pk PRIMARY KEY (id_salud)
);

CREATE TABLE MEDIO_PAGO (
    id_mediopago NUMBER,
    nombre       VARCHAR2(50) NOT NULL,
    CONSTRAINT medio_pago_pk PRIMARY KEY (id_mediopago)
);

CREATE TABLE EMPLEADO (
    id_empleado  NUMBER,
    nombre       VARCHAR2(50) NOT NULL,
    apellido_pat VARCHAR2(50) NOT NULL,
    apellido_mat VARCHAR2(50),
    sueldo_base  NUMBER NOT NULL,
    bono_jefatura NUMBER,
    activo       CHAR(1) CHECK (activo IN ('S','N')),
    id_afp       NUMBER,
    id_salud     NUMBER,
    CONSTRAINT empleado_pk PRIMARY KEY (id_empleado),
    CONSTRAINT fk_empleado_afp FOREIGN KEY (id_afp) REFERENCES AFP(id_afp),
    CONSTRAINT fk_empleado_salud FOREIGN KEY (id_salud) REFERENCES SALUD(id_salud)
);

CREATE TABLE VENDEDOR (
    id_vendedor  NUMBER,
    id_empleado  NUMBER UNIQUE,
    comision     NUMBER(4,2),
    CONSTRAINT vendedor_pk PRIMARY KEY (id_vendedor),
    CONSTRAINT vendedor_empleado_fk FOREIGN KEY (id_empleado) REFERENCES EMPLEADO(id_empleado),
    CONSTRAINT vendedor_ck_comision CHECK (comision BETWEEN 0 AND 0.25)
    
);

CREATE TABLE MARCA (
    id_marca NUMBER,
    nombre   VARCHAR2(50) NOT NULL,
    CONSTRAINT marca_pk PRIMARY KEY (id_marca),
    CONSTRAINT marca_nombre_un UNIQUE (nombre)
);

CREATE TABLE CATEGORIA (
    id_categoria NUMBER,
    nombre       VARCHAR2(50) NOT NULL,
    CONSTRAINT categoria_pk PRIMARY KEY (id_categoria)
);

CREATE TABLE PRODUCTO (
    id_producto NUMBER,
    nombre      VARCHAR2(100) NOT NULL,
    stock       NUMBER NOT NULL, 
    id_marca    NUMBER,
    id_categoria NUMBER,
  CONSTRAINT producto_pk PRIMARY KEY (id_producto),
  CONSTRAINT producto_marca_fk FOREIGN KEY (id_marca) REFERENCES MARCA(id_marca),
  CONSTRAINT producto_categoria_fk FOREIGN KEY (id_categoria) REFERENCES CATEGORIA(id_categoria),
  CONSTRAINT producto_ck_stock CHECK (stock >= 3)
);

CREATE TABLE VENTA (
    id_venta NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 5050 INCREMENT BY 3),
    fecha    DATE DEFAULT SYSDATE,
    id_vendedor NUMBER,
    id_mediopago NUMBER,
    CONSTRAINT venta_pk PRIMARY KEY (id_venta),
    CONSTRAINT fk_venta_vendedor FOREIGN KEY (id_vendedor) REFERENCES VENDEDOR(id_vendedor),
    CONSTRAINT fk_venta_pago FOREIGN KEY (id_mediopago) REFERENCES MEDIO_PAGO(id_mediopago)
);

CREATE TABLE DETALLE_VENTA (
    id_detalle   NUMBER,
    id_venta     NUMBER,
    id_producto  NUMBER,
    cantidad     NUMBER NOT NULL,
    CONSTRAINT detalle_venta_pk PRIMARY KEY (id_detalle),
    CONSTRAINT detalle_venta_venta_fk FOREIGN KEY (id_venta) REFERENCES VENTA(id_venta),
    CONSTRAINT detalle_venta_producto_fk FOREIGN KEY (id_producto) REFERENCES PRODUCTO(id_producto),
    CONSTRAINT detalle_venta_ck_cantidad CHECK (cantidad > 0)
);

------------------------------------------------------
-- RESTRICCIONES ADICIONALES
------------------------------------------------------
ALTER TABLE EMPLEADO ADD CONSTRAINT ck_sueldo_minimo CHECK (sueldo_base >= 400000);
ALTER TABLE EMPLEADO MODIFY activo CHAR(1) DEFAULT 'S' NOT NULL;
------------------------------------------------------
-- SECUENCIAS
------------------------------------------------------
CREATE SEQUENCE seq_salud START WITH 2050 INCREMENT BY 10;
CREATE SEQUENCE seq_empleado START WITH 750 INCREMENT BY 3;

------------------------------------------------------
-- POBLAMIENTO DE DATOS
------------------------------------------------------
-- REGIONES
INSERT INTO REGION VALUES (1, 'Metropolitana');
INSERT INTO REGION VALUES (2, 'Valparaíso');
INSERT INTO REGION VALUES (3, 'Biobío');

-- PROVEEDORES
INSERT INTO PROVEEDOR (id_proveedor, nombre, correo, telefono, direccion, id_region)
VALUES (1, 'Distribuidora Sur', 'sur@mail.com', '987654321', 'Av. Central 123', 1);

INSERT INTO PROVEEDOR (id_proveedor, nombre, correo, telefono, direccion, id_region)
VALUES (2, 'Proveedor Andes', 'andes@mail.com', '923456789', 'Los Olmos 456', 2);

-- AFP
INSERT INTO AFP (nombre) VALUES ('Provida');   -- ID = 210
INSERT INTO AFP (nombre) VALUES ('Habitat');   -- ID = 216
INSERT INTO AFP (nombre) VALUES ('Modelo');    -- ID = 222

-- SALUD
INSERT INTO SALUD VALUES (seq_salud.NEXTVAL, 'Fonasa');      -- ID = 2050
INSERT INTO SALUD VALUES (seq_salud.NEXTVAL, 'Colmena');     -- ID = 2060
INSERT INTO SALUD VALUES (seq_salud.NEXTVAL, 'Cruz Blanca'); -- ID = 2070

-- MEDIOS DE PAGO
INSERT INTO MEDIO_PAGO VALUES (1, 'Efectivo');
INSERT INTO MEDIO_PAGO VALUES (2, 'Tarjeta Débito');
INSERT INTO MEDIO_PAGO VALUES (3, 'Tarjeta Crédito');
INSERT INTO MEDIO_PAGO VALUES (4, 'Transferencia');

-- EMPLEADOS (referenciando AFP y SALUD válidos)
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Juan',       'Pérez',      'Gómez',     500000, 50000,  'S', 210, 2050);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Ana',        'López',      'Martínez',  800000, NULL,    'S', 216, 2060);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Pedro',      'Soto',       'Castro',    450000, NULL,    'S', 222, 2070);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'María',      'Ramírez',    'Araya',     600000, 30000,   'S', 210, 2050);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Luis',       'Fernández',  'López',     750000, NULL,    'N', 216, 2060);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Camila',     'Rojas',      'Muñoz',     520000, NULL,    'S', 222, 2050);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Diego',      'Morales',    'Herrera',   480000, NULL,    'S', 210, 2060);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Valentina',  'Díaz',       'Pardo',     900000, 80000,   'S', 216, 2070);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Sebastián',  'Vega',       'Carrasco',  620000, NULL,    'S', 222, 2050);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Daniela',    'Torres',     'Salas',     550000, NULL,    'S', 210, 2060);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Nicolás',    'Navarro',    'Reyes',     700000, 20000,   'S', 216, 2070);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Florencia',  'Pizarro',    'León',      460000, NULL,    'S', 222, 2050);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Tomás',      'Espinoza',   'Fuentes',   810000, 50000,   'S', 210, 2060);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Javiera',    'Peña',       'Godoy',     530000, NULL,    'S', 216, 2070);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Matías',     'Arancibia',  'Bravo',     580000, NULL,    'S', 222, 2050);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Fernanda',   'Herrera',    'Campos',    640000, 25000,   'S', 210, 2060);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Alejandro',  'Castillo',   'Silva',     720000, NULL,    'S', 216, 2070);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Sofía',      'Molina',     'Valdés',    470000, NULL,    'S', 222, 2050);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Cristian',   'Pérez',      'Alarcón',   690000, NULL,    'S', 210, 2060);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Paula',      'Soto',       'Riquelme',  560000, NULL,    'S', 216, 2070);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Rodrigo',    'Contreras',  'Hidalgo',   610000, 15000,   'S', 222, 2050);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Catalina',   'Saavedra',   'Figueroa',  580000, NULL,    'S', 210, 2060);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Felipe',     'Tapia',      'Bustos',    740000, 30000,   'S', 216, 2070);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Karla',      'Muñoz',      'Araya',     500000, NULL,    'S', 222, 2050);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Ignacio',    'Fuenzalida', 'Pinto',     830000, 60000,   'S', 210, 2060);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Antonia',    'Valenzuela', 'Pino',      470000, NULL,    'S', 216, 2070);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'José',       'Lagos',      'Miranda',   540000, NULL,    'S', 222, 2050);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Andrea',     'Cárdenas',   'Soto',      600000, 20000,   'S', 210, 2060);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Gabriel',    'Orellana',   'Palma',     760000, NULL,    'S', 216, 2070);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Camila',     'Salazar',    'Ríos',      490000, NULL,    'S', 222, 2050);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Benjamín',   'Araya',      'Candia',    520000, NULL,    'S', 210, 2060);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Isidora',    'Reyes',      'López',     570000, NULL,    'S', 216, 2070);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Franco',     'Mella',      'Donoso',    680000, 15000,   'S', 222, 2050);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Martina',    'Riquelme',   'Sáez',      610000, NULL,    'S', 210, 2060);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Alonso',     'Cornejo',    'Vega',      590000, NULL,    'S', 216, 2070);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Valeria',    'Abarca',     'Quinteros', 900000, 90000,   'S', 222, 2050);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Mauricio',   'Figueroa',   'Tapia',     450000, NULL,    'S', 210, 2060);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Camilo',     'Paredes',    'Toro',      560000, NULL,    'S', 216, 2070);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Trinidad',   'Godoy',      'Núñez',     620000, 20000,   'S', 222, 2050);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Pablo',      'Bustamante', 'Díaz',      700000, NULL,    'S', 210, 2060);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Bastián',    'Herrera',    'Muñoz',     480000, NULL,    'S', 216, 2070);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Constanza',  'Leiva',      'Álvarez',   530000, NULL,    'S', 222, 2050);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Hernán',     'Silva',      'Rojas',     840000, 70000,   'S', 210, 2060);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Romina',     'Cáceres',    'Flores',    610000, NULL,    'S', 216, 2070);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Patricio',   'Vergara',    'Campos',    580000, NULL,    'S', 222, 2050);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Francisca',  'Aguilera',   'Luna',      750000, 25000,   'S', 210, 2060);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Matilde',    'Sepúlveda',  'Arcos',     560000, NULL,    'S', 216, 2070);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Óscar',      'Garrido',    'Beltrán',   460000, NULL,    'S', 222, 2050);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Elisa',      'Farías',     'Caneo',     520000, NULL,    'S', 210, 2060);
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Ricardo',    'Medina',     'Pavez',     780000, 30000,   'S', 216, 2070);

-- VENDEDORES (usamos IDs de empleados generados por secuencia: 750, 753, 756…)
INSERT INTO VENDEDOR VALUES (1, 750, 0.10);  
INSERT INTO VENDEDOR VALUES (2, 759, 0.15);  

-- MARCAS
INSERT INTO MARCA VALUES (1, 'Colun');
INSERT INTO MARCA VALUES (2, 'Soprole');
INSERT INTO MARCA VALUES (3, 'Coca-Cola');
INSERT INTO MARCA VALUES (4, 'Ideal');

-- CATEGORIAS
INSERT INTO CATEGORIA VALUES (1, 'Lácteos');
INSERT INTO CATEGORIA VALUES (2, 'Bebidas');
INSERT INTO CATEGORIA VALUES (3, 'Panadería');
INSERT INTO CATEGORIA VALUES (4, 'Aseo');

-- PRODUCTOS
INSERT INTO PRODUCTO VALUES (1, 'Leche Entera 1L', 20, 1, 1);
INSERT INTO PRODUCTO VALUES (2, 'Yoghurt Natural', 15, 2, 1);
INSERT INTO PRODUCTO VALUES (3, 'Coca-Cola 1.5L', 30, 3, 2);
INSERT INTO PRODUCTO VALUES (4, 'Pan de Molde Blanco', 25, 4, 3);
INSERT INTO PRODUCTO VALUES (5, 'Detergente 1kg', 12, NULL, 4);

-- VENTAS
INSERT INTO VENTA (id_vendedor, id_mediopago) VALUES (1, 1);
INSERT INTO VENTA (id_vendedor, id_mediopago) VALUES (2, 2);

-- DETALLE DE VENTAS
INSERT INTO DETALLE_VENTA VALUES (1, 5050, 1, 2); -- 2 Leches
INSERT INTO DETALLE_VENTA VALUES (2, 5050, 3, 1); -- 1 Coca-Cola
INSERT INTO DETALLE_VENTA VALUES (3, 5053, 2, 3); -- 3 Yoghurts
INSERT INTO DETALLE_VENTA VALUES (4, 5053, 4, 1); -- 1 Pan

------------------------------------------------------
-- INFORMES
------------------------------------------------------
-- INFORME 1: Sueldo total con bono
SELECT e.id_empleado AS IDENTIFICADOR,
       e.nombre || ' ' || e.apellido_pat || ' ' || e.apellido_mat AS "NOMBRE COMPLETO",
       e.sueldo_base AS SALARIO,
       e.bono_jefatura AS BONIFICACION,
       (e.sueldo_base + e.bono_jefatura) AS "SALARIO SIMULADO"
FROM EMPLEADO e
WHERE e.activo = 'S'
  AND e.bono_jefatura IS NOT NULL
ORDER BY "SALARIO SIMULADO" DESC, e.apellido_pat DESC;

-- INFORME 2: Empleados con sueldo entre 550.000 y 800.000
SELECT e.nombre || ' ' || e.apellido_pat || ' ' || e.apellido_mat AS EMPLEADO,
       e.sueldo_base AS SUELDO,
       (e.sueldo_base * 0.08) AS "POSIBLE AUMENTO",
       (e.sueldo_base * 1.08) AS "SALARIO SIMULADO"
FROM EMPLEADO e
WHERE e.sueldo_base BETWEEN 550000 AND 800000
ORDER BY e.sueldo_base ASC;
/*------------------------------------------------------
-- VALIDACIONES EXTRAS
--------------------------------------------------------
-- Ver todas las ventas
SELECT v.id_venta,
       v.fecha,
       e.nombre || ' ' || e.apellido_pat || ' ' || e.apellido_mat AS VENDEDOR,
       mp.nombre AS MEDIO_PAGO
FROM VENTA v
JOIN VENDEDOR ve ON v.id_vendedor = ve.id_vendedor
JOIN EMPLEADO e ON ve.id_empleado = e.id_empleado
JOIN MEDIO_PAGO mp ON v.id_mediopago = mp.id_mediopago
ORDER BY v.id_venta;

-- Ver detalle de ventas
SELECT d.id_detalle,
       v.id_venta,
       p.nombre AS PRODUCTO,
       d.cantidad
FROM DETALLE_VENTA d
JOIN PRODUCTO p ON d.id_producto = p.id_producto
JOIN VENTA v ON d.id_venta = v.id_venta
ORDER BY d.id_detalle;

-- Ver todos los empleados registrados
SELECT * FROM EMPLEADO;

-- Ver todos los vendedores
SELECT * FROM VENDEDOR;

-- Ver todos los productos
SELECT * FROM PRODUCTO;


-- Ver AFP
SELECT * FROM AFP;

-- Ver instituciones de salud
SELECT * FROM SALUD;

-- Ver medios de pago
SELECT * FROM MEDIO_PAGO;

-- Ver regiones
SELECT * FROM REGION;

-- Ver proveedores
SELECT * FROM PROVEEDOR;
-------------------------------------------------*/
