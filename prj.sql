-- Created the DATABASE
-- Author : Sai Krishna Akula
-- CREATE DATABASE ERP;

-- Create script for tables
-- Author : Sai Krishna Akula


CREATE SEQUENCE customer_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

    CREATE SEQUENCE employee_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

    CREATE SEQUENCE inventory_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

    CREATE SEQUENCE job_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

    CREATE SEQUENCE login_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

    CREATE SEQUENCE model_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

    CREATE SEQUENCE orders_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

    CREATE SEQUENCE order_item_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

CREATE TABLE customer
(
    id integer NOT NULL DEFAULT nextval('customer_id_seq'::regclass),
    first_name character varying(150) COLLATE pg_catalog."default",
    last_name character varying(150) COLLATE pg_catalog."default",
    phone character varying(20) COLLATE pg_catalog."default",
    email character varying(150) COLLATE pg_catalog."default",
    address character varying(500) COLLATE pg_catalog."default",
    CONSTRAINT customer_pkey PRIMARY KEY (id)
);

INSERT INTO customer VALUES (1, 'fn1', 'ln1', '9000', 'fn1@iit.com', 'addr1');
INSERT INTO customer VALUES (2, 'fn2', 'ln2', '9000', 'fn2@iit.com', 'addr2');
INSERT INTO customer VALUES (3, 'fn3', 'ln3', '9000', 'fn3@iit.com', 'addr3');
INSERT INTO customer VALUES (4, 'cfn5', 'cln5', '9000', 'cfn5@iit.com', 'xyz5');

CREATE TABLE job
(
    id integer NOT NULL DEFAULT nextval('job_id_seq'::regclass),
    name character varying(100) COLLATE pg_catalog."default",
    is_active boolean,
    CONSTRAINT job_pkey PRIMARY KEY (id)
);

INSERT INTO job VALUES (1, 'ADMIN', true);
INSERT INTO job VALUES (2, 'SALES', true);
INSERT INTO job VALUES (3, 'ENGINEERING', true);
INSERT INTO job VALUES (4, 'HR', true);


CREATE TABLE employee
(
    first_name character varying(150) COLLATE pg_catalog."default",
    last_name character varying(150) COLLATE pg_catalog."default",
    id integer NOT NULL DEFAULT nextval('employee_id_seq'::regclass),
    is_active boolean,
    salary numeric,
    hourly_salaried character varying(10) COLLATE pg_catalog."default",
    phone character varying(20) COLLATE pg_catalog."default",
    identity_number character varying(100) COLLATE pg_catalog."default",
    email character varying(150) COLLATE pg_catalog."default",
    job_type integer NOT NULL,
    CONSTRAINT employee_pkey PRIMARY KEY (id),
    CONSTRAINT role FOREIGN KEY (job_type)
        REFERENCES job (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

INSERT INTO employee VALUES ('efm1', 'elm1', 1, true, 10000, 'hourly', '9000', 'xyz1', 'efm1@iit.com', 1);
INSERT INTO employee VALUES ('efm3', 'elm3', 3, true, 30000, 'hourly', '9000', 'xyz3', 'efm3@iit.com', 3);
INSERT INTO employee VALUES ('efm4', 'elm4', 4, true, 40000, 'hourly', '9000', 'xyz4', 'efm4@iit.com', 4);
INSERT INTO employee VALUES ('efm2', 'elm2', 2, true, 30000, 'hourly', '9000', 'xyz2', 'efm2@iit.com', 2);



CREATE TABLE model
(
    id integer NOT NULL DEFAULT nextval('model_id_seq'::regclass),
    model_number integer,
    buy_price integer,
    name character(100) COLLATE pg_catalog."default",
    vendor character(100) COLLATE pg_catalog."default",
    brand character(100) COLLATE pg_catalog."default",
    description character(100) COLLATE pg_catalog."default",
    shelf_life integer,
    category character(10) COLLATE pg_catalog."default",
    CONSTRAINT model_pkey PRIMARY KEY (id)
);

INSERT INTO model VALUES (1, 5547, 50000, 'inspiron', 'Dell', 'Dell', 'laptop', 0, 'el');
INSERT INTO model VALUES (2, 5548, 55000, 'inspiron', 'dell', 'dell', 'touch screen laptop', 100, 'el');
INSERT INTO model VALUES (3, 2020, 150000, 'macbook pro', 'apple', 'apple', 'apple latest mac', 100, 'el');
INSERT INTO model VALUES (4, 2019, 100000, 'macbook pro', 'apple', 'apple', 'old macbook pro', 100, 'el');
INSERT INTO model VALUES (5, 2020, 200000, 'macbook air', 'apple', 'apple', 'latest macbook air', 100, 'el');

CREATE TABLE inventory
(
    lead_time integer,
    id integer NOT NULL DEFAULT nextval('inventory_id_seq'::regclass),
    count integer,
    model_id integer,
    CONSTRAINT inventory_pkey PRIMARY KEY (id),
    CONSTRAINT model_id FOREIGN KEY (model_id)
        REFERENCES model (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

INSERT INTO inventory VALUES (10, 1, 100, 1);
INSERT INTO inventory VALUES (100, 2, 100, 2);
INSERT INTO inventory VALUES (100, 3, 100, 3);
INSERT INTO inventory VALUES (100, 4, 100, 4);
INSERT INTO inventory VALUES (100, 5, 100, 5);


CREATE TABLE login
(
    id integer NOT NULL DEFAULT nextval('login_id_seq'::regclass),
    user_id integer NOT NULL,
    role_id integer NOT NULL,
    login_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    logout_time timestamp with time zone,
    CONSTRAINT login_pkey PRIMARY KEY (id),
    CONSTRAINT employee FOREIGN KEY (user_id)
        REFERENCES employee (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    CONSTRAINT login_role FOREIGN KEY (role_id)
        REFERENCES job (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);


CREATE TABLE orders
(
    id integer NOT NULL DEFAULT nextval('orders_id_seq'::regclass),
    customer_id integer NOT NULL,
    employee_id integer NOT NULL,
    order_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    comments character varying(100) COLLATE pg_catalog."default",
    status character varying(10) COLLATE pg_catalog."default",
    model_id integer NOT NULL,
    qty integer,
    cost_each integer,
    CONSTRAINT order_pkey PRIMARY KEY (id),
    CONSTRAINT customer FOREIGN KEY (customer_id)
        REFERENCES customer (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
        CONSTRAINT model_id FOREIGN KEY (model_id)
        REFERENCES model (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT emp FOREIGN KEY (employee_id)
        REFERENCES employee (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    CONSTRAINT stat_chk CHECK (status::text = ANY (ARRAY['completed'::character varying, 'cancelled'::character varying, 'placed'::character varying]::text[])) NOT VALID
);

INSERT INTO orders VALUES (2, 1, 3, '2020-04-18 03:01:10.020545+05:30', 'macbook pro 2020', 'completed');




INSERT INTO order_item VALUES (1, 2, 3, 1, 200000);


-- reset counters 
SELECT pg_catalog.setval('login_id_seq', 1, true);
SELECT pg_catalog.setval('model_id_seq', 5, true);
SELECT pg_catalog.setval('order_item_id_seq', 1, true);
SELECT pg_catalog.setval('orders_id_seq', 2, true);


--


-- Create scripts for views
-- Author : Sai Krishna Akula

CREATE OR REPLACE VIEW sales_emp_cust
 AS
 SELECT o.employee_id,
    o.customer_id,
    sum(oi.qty * oi.cost_each) AS sales
   FROM orders o
     FULL JOIN order_item oi ON oi.order_id = o.id
  GROUP BY o.employee_id, o.customer_id;


CREATE OR REPLACE VIEW cust_model_sales
 AS
 SELECT c.id,
    c.first_name,
    c.last_name,
    m.name,
    oi.qty
   FROM orders o
     FULL JOIN order_item oi ON oi.order_id = o.id
     JOIN customer c ON o.customer_id = c.id
     JOIN model m ON oi.model_id = m.id;

CREATE OR REPLACE VIEW order_part_inventory
 AS
 SELECT oi.order_id AS orderid,
    oi.qty AS orderqty,
    i.count AS inventorycnt
   FROM order_item oi
     JOIN inventory i ON i.model_id = oi.model_id;




-- Create script for roles and privileges
-- Author : Sai Krishna Akula

CREATE ROLE admin;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO GROUP admin;


CREATE ROLE sales;

GRANT SELECT, UPDATE  ON TABLE customer TO GROUP sales;

GRANT SELECT, INSERT ON TABLE orders TO GROUP sales;

GRANT SELECT, INSERT ON TABLE order_item TO GROUP sales;

GRANT SELECT ON sales_emp_cust TO GROUP sales;


CREATE ROLE engineer;

GRANT SELECT, UPDATE  ON TABLE model TO GROUP engineer;

GRANT SELECT, UPDATE  ON TABLE inventory TO GROUP engineer;

GRANT  SELECT  ( first_name,
    last_name,
    id ,
    is_active ,
    email ,
    job_type  )
    ON TABLE employee TO GROUP engineer;


CREATE ROLE hr;

GRANT  SELECT, UPDATE ON TABLE employee TO GROUP hr;

GRANT SELECT ON sales_emp_cust TO GROUP hr;


---created users
CREATE USER admin_1 WITH PASSWORD 'jw8s0F41' IN GROUP admin;
CREATE USER sales_1 WITH PASSWORD 'jw8s0F42' IN GROUP sales;
CREATE USER engg_1 WITH PASSWORD 'jw8s0F43' IN GROUP engineer;
CREATE USER hr_1 WITH PASSWORD 'jw8s0F44' IN GROUP hr;
