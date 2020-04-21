--
-- PostgreSQL database dump
--

-- Dumped from database version 12.1
-- Dumped by pg_dump version 12.1

-- Started on 2020-04-21 16:37:43

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 221 (class 1255 OID 24744)
-- Name: check_inventory(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_inventory() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
			counter integer := 0;
	BEGIN
		IF (TG_OP = 'UPDATE') THEN
			IF OLD.status = 'placed' and new.status = 'completed' and old.model_id = new.model_id and new.qty = old.qty THEN
			 RETURN NEW;
			ELSIF old.model_id <> new.model_id OR new.qty <> old.qty THEN
				select i.count into counter from inventory i where i.model_id = NEW.model_id;
			 		IF new.qty > counter THEN
            			RAISE EXCEPTION '% dont have enough quantity in inventory for model', NEW.model_id;
       				 END IF;
			END IF;
		ELSIF (TG_OP = 'INSERT') THEN
        	IF NEW.model_id > 0 and NEW.qty > 0 THEN
            	select i.count into counter from inventory i where i.model_id = NEW.model_id;
			 		IF new.qty > counter THEN
            			RAISE EXCEPTION '% dont have enough quantity in inventory for model', NEW.model_id;
       				 END IF;
			END IF;		 
        END IF;
        RETURN NEW;
    END;
	$$;


ALTER FUNCTION public.check_inventory() OWNER TO postgres;

--
-- TOC entry 234 (class 1255 OID 24734)
-- Name: update_inventory(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_inventory() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
--             update inventory set count = count + OLD.qty where model_id = OLD.model_id;
            RETURN OLD;
        ELSIF (TG_OP = 'UPDATE') THEN
			if(Old.status <> new.status and new.status = 'cancelled') THEN 
				update inventory set count = count + OLD.qty where model_id = OLD.model_id;
			elsif(new.model_id <> old.model_id and new.status <> 'cancelled') THEn
				update inventory set count = count + OLD.qty where model_id = OLD.model_id;
				update inventory set count = count - NEW.qty where model_id = NEW.model_id;
			elsif(new.qty <> old.qty and new.status <> 'cancelled') THEn
				update inventory set count = count + old.qty - NEW.qty where model_id = NEW.model_id;
			elsif(Old.status = 'cancelled' and new.status <> 'cancelled') THEN 
				update inventory set count = count - NEW.qty where model_id = NEW.model_id;
			END IF;	
            RETURN NEW;
        ELSIF (TG_OP = 'INSERT') THEN
          update inventory set count = count - NEW.qty where model_id = NEW.model_id;
            RETURN NEW;
        END IF;
        RETURN NULL; 
    END;
$$;


ALTER FUNCTION public.update_inventory() OWNER TO postgres;

--
-- TOC entry 202 (class 1259 OID 24577)
-- Name: customer_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.customer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.customer_id_seq OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 203 (class 1259 OID 24579)
-- Name: customer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customer (
    id integer DEFAULT nextval('public.customer_id_seq'::regclass) NOT NULL,
    first_name character varying(150),
    last_name character varying(150),
    phone character varying(20),
    email character varying(150),
    address character varying(500)
);


ALTER TABLE public.customer OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 24629)
-- Name: model_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.model_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.model_id_seq OWNER TO postgres;

--
-- TOC entry 210 (class 1259 OID 24631)
-- Name: model; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.model (
    id integer DEFAULT nextval('public.model_id_seq'::regclass) NOT NULL,
    model_number integer,
    buy_price integer,
    name character(100),
    brand character(100),
    description character(100),
    shelf_life integer,
    category character(10)
);


ALTER TABLE public.model OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 24667)
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.orders_id_seq OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 24669)
-- Name: orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orders (
    id integer DEFAULT nextval('public.orders_id_seq'::regclass) NOT NULL,
    customer_id integer NOT NULL,
    employee_id integer NOT NULL,
    order_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    comments character varying(100),
    status character varying(10),
    model_id integer,
    qty integer,
    cost_each integer,
    CONSTRAINT stat_chk CHECK (((status)::text = ANY (ARRAY[('completed'::character varying)::text, ('cancelled'::character varying)::text, ('placed'::character varying)::text])))
);


ALTER TABLE public.orders OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 24709)
-- Name: cust_model_sales; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.cust_model_sales WITH (security_barrier='false') AS
 SELECT c.id,
    c.first_name,
    c.last_name,
    m.name,
    o.qty,
    m.model_number
   FROM ((public.orders o
     JOIN public.customer c ON ((o.customer_id = c.id)))
     JOIN public.model m ON ((o.model_id = m.id)));


ALTER TABLE public.cust_model_sales OWNER TO postgres;

--
-- TOC entry 204 (class 1259 OID 24588)
-- Name: employee_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.employee_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.employee_id_seq OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 24607)
-- Name: employee; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employee (
    first_name character varying(150),
    last_name character varying(150),
    id integer DEFAULT nextval('public.employee_id_seq'::regclass) NOT NULL,
    is_active boolean,
    salary numeric,
    hourly_salaried character varying(10),
    phone character varying(20),
    identity_number character varying(100),
    email character varying(150),
    job_type integer NOT NULL
);


ALTER TABLE public.employee OWNER TO postgres;

--
-- TOC entry 2932 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN employee.identity_number; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.employee.identity_number IS 'ssn';


--
-- TOC entry 220 (class 1259 OID 25111)
-- Name: expense_report; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.expense_report AS
SELECT
    NULL::integer AS empid,
    NULL::character varying(150) AS firstname,
    NULL::character varying(150) AS lastname,
    NULL::numeric AS salary,
    NULL::bigint AS sale,
    NULL::bigint AS partcost;


ALTER TABLE public.expense_report OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 24621)
-- Name: inventory_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inventory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.inventory_id_seq OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 24637)
-- Name: inventory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventory (
    lead_time integer,
    id integer DEFAULT nextval('public.inventory_id_seq'::regclass) NOT NULL,
    count integer,
    model_id integer
);


ALTER TABLE public.inventory OWNER TO postgres;

--
-- TOC entry 205 (class 1259 OID 24599)
-- Name: job_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.job_id_seq OWNER TO postgres;

--
-- TOC entry 206 (class 1259 OID 24601)
-- Name: job; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job (
    id integer DEFAULT nextval('public.job_id_seq'::regclass) NOT NULL,
    name character varying(100),
    is_active boolean
);


ALTER TABLE public.job OWNER TO postgres;

--
-- TOC entry 212 (class 1259 OID 24648)
-- Name: login_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.login_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.login_id_seq OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 24650)
-- Name: login; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.login (
    id integer DEFAULT nextval('public.login_id_seq'::regclass) NOT NULL,
    user_id integer NOT NULL,
    role_id integer NOT NULL,
    login_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    logout_time timestamp with time zone
);


ALTER TABLE public.login OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 24687)
-- Name: order_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.order_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.order_item_id_seq OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 24714)
-- Name: order_part_inventory; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.order_part_inventory WITH (security_barrier='false') AS
 SELECT oi.id AS orderid,
    oi.qty AS orderqty,
    i.count AS inventorycnt
   FROM (public.orders oi
     JOIN public.inventory i ON ((i.model_id = oi.model_id)));


ALTER TABLE public.order_part_inventory OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 24705)
-- Name: sales_emp_cust; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.sales_emp_cust WITH (security_barrier='false') AS
 SELECT o.employee_id,
    o.customer_id,
    sum((o.qty * o.cost_each)) AS sales
   FROM public.orders o
  GROUP BY o.employee_id, o.customer_id;


ALTER TABLE public.sales_emp_cust OWNER TO postgres;

--
-- TOC entry 2909 (class 0 OID 24579)
-- Dependencies: 203
-- Data for Name: customer; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.customer VALUES (1, 'fn1', 'ln1', '9000', 'fn1@iit.com', 'addr1');
INSERT INTO public.customer VALUES (2, 'fn2', 'ln2', '9000', 'fn2@iit.com', 'addr2');
INSERT INTO public.customer VALUES (3, 'fn3', 'ln3', '9000', 'fn3@iit.com', 'addr3');
INSERT INTO public.customer VALUES (4, 'fn5', 'ln5', '9000', 'fn5@iit.com', 'xyz5');


--
-- TOC entry 2913 (class 0 OID 24607)
-- Dependencies: 207
-- Data for Name: employee; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.employee VALUES ('efm3', 'elm3', 3, true, 30000, 'hourly', '9000', 'xyz3', 'efm3@iit.com', 3);
INSERT INTO public.employee VALUES ('efm4', 'elm4', 4, true, 40000, 'hourly', '9000', 'xyz4', 'efm4@iit.com', 4);
INSERT INTO public.employee VALUES ('efm2', 'elm2', 2, true, 30000, 'hourly', '9000', 'xyz2', 'efm2@iit.com', 2);
INSERT INTO public.employee VALUES ('efm1', 'elm1', 1, true, 10000, 'hourly', '9000', 'xyz1', 'efm1@iit.com', 1);


--
-- TOC entry 2917 (class 0 OID 24637)
-- Dependencies: 211
-- Data for Name: inventory; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.inventory VALUES (100, 3, 100, 3);
INSERT INTO public.inventory VALUES (100, 2, 95, 2);
INSERT INTO public.inventory VALUES (100, 5, 99, 5);
INSERT INTO public.inventory VALUES (100, 4, 99, 4);
INSERT INTO public.inventory VALUES (100, 1, 10, 1);


--
-- TOC entry 2912 (class 0 OID 24601)
-- Dependencies: 206
-- Data for Name: job; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.job VALUES (1, 'ADMIN', true);
INSERT INTO public.job VALUES (2, 'SALES', true);
INSERT INTO public.job VALUES (3, 'ENGINEERING', true);
INSERT INTO public.job VALUES (4, 'HR', true);


--
-- TOC entry 2919 (class 0 OID 24650)
-- Dependencies: 213
-- Data for Name: login; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.login VALUES (2, 1, 1, '2020-04-19 13:41:16.756986+05:30', '2020-04-19 13:41:20.788126+05:30');


--
-- TOC entry 2916 (class 0 OID 24631)
-- Dependencies: 210
-- Data for Name: model; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.model VALUES (2, 5548, 55000, 'inspiron                                                                                            ', 'dell                                                                                                ', 'touch screen laptop                                                                                 ', 100, 'el        ');
INSERT INTO public.model VALUES (3, 2020, 150000, 'macbook pro                                                                                         ', 'apple                                                                                               ', 'apple latest mac                                                                                    ', 100, 'el        ');
INSERT INTO public.model VALUES (4, 2019, 100000, 'macbook pro                                                                                         ', 'apple                                                                                               ', 'old macbook pro                                                                                     ', 100, 'el        ');
INSERT INTO public.model VALUES (5, 2020, 200000, 'macbook air                                                                                         ', 'apple                                                                                               ', 'latest macbook air                                                                                  ', 100, 'el        ');
INSERT INTO public.model VALUES (1, 5547, 50000, 'inspiron                                                                                            ', 'Dell                                                                                                ', 'laptop                                                                                              ', 100, 'el        ');


--
-- TOC entry 2921 (class 0 OID 24669)
-- Dependencies: 215
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.orders VALUES (3, 2, 3, '2020-04-18 12:50:06.777659+05:30', 'dell laptop', 'completed', 1, 2, 65000);
INSERT INTO public.orders VALUES (2, 1, 3, '2020-04-18 03:01:10.020545+05:30', 'macbook pro 2020', 'completed', 3, 2, 200000);
INSERT INTO public.orders VALUES (5, 3, 3, '2020-04-18 19:59:07.706318+05:30', 'delivered directly', 'completed', 5, 1, 250000);
INSERT INTO public.orders VALUES (6, 3, 3, '2020-04-18 20:29:35.728833+05:30', 'ee', 'completed', 4, 1, 150000);
INSERT INTO public.orders VALUES (7, 3, 3, '2020-04-18 20:35:02.856543+05:30', 'order completed', 'completed', 1, 90, 65000);
INSERT INTO public.orders VALUES (8, 3, 2, '2020-04-19 15:01:35.137585+05:30', NULL, 'completed', 1, 90, 65000);


--
-- TOC entry 2945 (class 0 OID 0)
-- Dependencies: 202
-- Name: customer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customer_id_seq', 4, true);


--
-- TOC entry 2946 (class 0 OID 0)
-- Dependencies: 204
-- Name: employee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employee_id_seq', 10, true);


--
-- TOC entry 2947 (class 0 OID 0)
-- Dependencies: 208
-- Name: inventory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.inventory_id_seq', 5, true);


--
-- TOC entry 2948 (class 0 OID 0)
-- Dependencies: 205
-- Name: job_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.job_id_seq', 5, true);


--
-- TOC entry 2949 (class 0 OID 0)
-- Dependencies: 212
-- Name: login_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.login_id_seq', 2, true);


--
-- TOC entry 2950 (class 0 OID 0)
-- Dependencies: 209
-- Name: model_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.model_id_seq', 5, true);


--
-- TOC entry 2951 (class 0 OID 0)
-- Dependencies: 216
-- Name: order_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.order_item_id_seq', 1, true);


--
-- TOC entry 2952 (class 0 OID 0)
-- Dependencies: 214
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.orders_id_seq', 8, true);


--
-- TOC entry 2756 (class 2606 OID 24587)
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (id);


--
-- TOC entry 2760 (class 2606 OID 24615)
-- Name: employee employee_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_pkey PRIMARY KEY (id);


--
-- TOC entry 2764 (class 2606 OID 24642)
-- Name: inventory inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_pkey PRIMARY KEY (id);


--
-- TOC entry 2758 (class 2606 OID 24606)
-- Name: job job_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job
    ADD CONSTRAINT job_pkey PRIMARY KEY (id);


--
-- TOC entry 2766 (class 2606 OID 24656)
-- Name: login login_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.login
    ADD CONSTRAINT login_pkey PRIMARY KEY (id);


--
-- TOC entry 2762 (class 2606 OID 24636)
-- Name: model model_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.model
    ADD CONSTRAINT model_pkey PRIMARY KEY (id);


--
-- TOC entry 2768 (class 2606 OID 24676)
-- Name: orders order_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT order_pkey PRIMARY KEY (id);


--
-- TOC entry 2907 (class 2618 OID 25114)
-- Name: expense_report _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.expense_report AS
 SELECT e.id AS empid,
    e.first_name AS firstname,
    e.last_name AS lastname,
    e.salary,
    sum((o.cost_each * o.qty)) AS sale,
    sum((m.buy_price * o.qty)) AS partcost
   FROM ((public.employee e
     JOIN public.orders o ON ((o.employee_id = e.id)))
     JOIN public.model m ON ((o.model_id = m.id)))
  GROUP BY e.id;


--
-- TOC entry 2776 (class 2620 OID 24745)
-- Name: orders check_inventory; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_inventory BEFORE INSERT OR UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.check_inventory();


--
-- TOC entry 2777 (class 2620 OID 24746)
-- Name: orders update_inventory; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_inventory AFTER INSERT OR DELETE OR UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.update_inventory();


--
-- TOC entry 2773 (class 2606 OID 24677)
-- Name: orders customer; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT customer FOREIGN KEY (customer_id) REFERENCES public.customer(id);


--
-- TOC entry 2774 (class 2606 OID 24682)
-- Name: orders emp; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT emp FOREIGN KEY (employee_id) REFERENCES public.employee(id);


--
-- TOC entry 2771 (class 2606 OID 24657)
-- Name: login employee; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.login
    ADD CONSTRAINT employee FOREIGN KEY (user_id) REFERENCES public.employee(id);


--
-- TOC entry 2772 (class 2606 OID 24662)
-- Name: login login_role; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.login
    ADD CONSTRAINT login_role FOREIGN KEY (role_id) REFERENCES public.job(id);


--
-- TOC entry 2775 (class 2606 OID 24727)
-- Name: orders model; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT model FOREIGN KEY (model_id) REFERENCES public.model(id) NOT VALID;


--
-- TOC entry 2770 (class 2606 OID 24643)
-- Name: inventory model_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT model_id FOREIGN KEY (model_id) REFERENCES public.model(id);


--
-- TOC entry 2769 (class 2606 OID 24616)
-- Name: employee role; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT role FOREIGN KEY (job_type) REFERENCES public.job(id);


--
-- TOC entry 2928 (class 0 OID 0)
-- Dependencies: 203
-- Name: TABLE customer; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.customer TO admin;
GRANT SELECT,UPDATE ON TABLE public.customer TO sales;


--
-- TOC entry 2929 (class 0 OID 0)
-- Dependencies: 210
-- Name: TABLE model; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.model TO admin;
GRANT SELECT,UPDATE ON TABLE public.model TO engineer;


--
-- TOC entry 2930 (class 0 OID 0)
-- Dependencies: 215
-- Name: TABLE orders; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.orders TO admin;
GRANT SELECT,INSERT ON TABLE public.orders TO sales;


--
-- TOC entry 2931 (class 0 OID 0)
-- Dependencies: 218
-- Name: TABLE cust_model_sales; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.cust_model_sales TO admin;


--
-- TOC entry 2933 (class 0 OID 0)
-- Dependencies: 207
-- Name: TABLE employee; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.employee TO admin;
GRANT SELECT,UPDATE ON TABLE public.employee TO engineer;


--
-- TOC entry 2934 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN employee.first_name; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(first_name) ON TABLE public.employee TO engineer;


--
-- TOC entry 2935 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN employee.last_name; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(last_name) ON TABLE public.employee TO engineer;


--
-- TOC entry 2936 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN employee.id; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(id) ON TABLE public.employee TO engineer;


--
-- TOC entry 2937 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN employee.is_active; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(is_active) ON TABLE public.employee TO engineer;


--
-- TOC entry 2938 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN employee.email; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(email) ON TABLE public.employee TO engineer;


--
-- TOC entry 2939 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN employee.job_type; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(job_type) ON TABLE public.employee TO engineer;


--
-- TOC entry 2940 (class 0 OID 0)
-- Dependencies: 211
-- Name: TABLE inventory; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.inventory TO admin;
GRANT SELECT,UPDATE ON TABLE public.inventory TO engineer;


--
-- TOC entry 2941 (class 0 OID 0)
-- Dependencies: 206
-- Name: TABLE job; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.job TO admin;


--
-- TOC entry 2942 (class 0 OID 0)
-- Dependencies: 213
-- Name: TABLE login; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.login TO admin;


--
-- TOC entry 2943 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE order_part_inventory; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.order_part_inventory TO admin;


--
-- TOC entry 2944 (class 0 OID 0)
-- Dependencies: 217
-- Name: TABLE sales_emp_cust; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.sales_emp_cust TO admin;
GRANT SELECT ON TABLE public.sales_emp_cust TO sales;
GRANT SELECT ON TABLE public.sales_emp_cust TO hr;


-- Completed on 2020-04-21 16:37:44

--
-- PostgreSQL database dump complete
--

GRANT ALL ON TABLE public.login TO admin;
GRANT ALL ON TABLE public.login TO hr;
GRANT ALL ON TABLE public.login TO sales;
GRANT ALL ON TABLE public.login TO engineer;

GRANT Select, update ON TABLE public.employee TO hr;

GRANT Select ON TABLE public.job TO hr;