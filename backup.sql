--
-- PostgreSQL database dump
--

-- Dumped from database version 13.16 (Debian 13.16-1.pgdg120+1)
-- Dumped by pg_dump version 13.16 (Debian 13.16-1.pgdg120+1)

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
-- Name: area_data_tvp; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.area_data_tvp AS (
	region character varying(100),
	county character varying(100),
	constituency character varying(100),
	area character varying(100),
	countycode character varying(100)
);


ALTER TYPE public.area_data_tvp OWNER TO postgres;

--
-- Name: geo; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.geo AS (
	lat double precision,
	long double precision
);


ALTER TYPE public.geo OWNER TO postgres;

--
-- Name: fetchareadetails(text, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fetchareadetails(p_area_name text DEFAULT NULL::text, p_constituency_name text DEFAULT NULL::text, p_county_name text DEFAULT NULL::text, p_area_id integer DEFAULT NULL::integer) RETURNS json
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN (
        SELECT json_agg(row_to_json(t))
        FROM (
            SELECT
                a.name::text AS area,
                c.name::text AS constituency,
                co.name::text AS county,
                r.name::text AS region,
                a.area_id,
                (a.geoLocation).lat,
                (a.geoLocation).long
            FROM
                PUBLIC.tbl_area a
                JOIN PUBLIC.tbl_constituency c ON a.cst_id = c.cst_id
                JOIN PUBLIC.tbl_county co ON c.cty_id = co.cty_id
                JOIN PUBLIC.tbl_region r ON co.reg_id = r.reg_id
            WHERE
                (p_area_name IS NULL OR LOWER(a.name) = LOWER(p_area_name))
                AND (p_area_id IS NULL OR a.area_id = p_area_id)
                AND (p_constituency_name IS NULL OR LOWER(c.name) = LOWER(p_constituency_name))
                AND (p_county_name IS NULL OR LOWER(co.name) = LOWER(p_county_name))
        ) t
    );
END $$;


ALTER FUNCTION public.fetchareadetails(p_area_name text, p_constituency_name text, p_county_name text, p_area_id integer) OWNER TO postgres;

--
-- Name: insertareadata(jsonb); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.insertareadata(areadata jsonb)
    LANGUAGE plpgsql
    AS $$
DECLARE
    record jsonb;
    region text;
    county text;
    constituency text;
    area text;
    countyCode text;
BEGIN
    -- Iterate over each item in the JSON array
    FOR record IN SELECT * FROM jsonb_array_elements(AreaData)
    LOOP
        -- Extract fields from the current JSON object
        region := record->>'region';
        county := record->>'county';
        constituency := record->>'constituency';
        area := record->>'area';
        countyCode := record->>'countyCode';

        -- Insert Region
        IF NOT EXISTS (SELECT 1 FROM public.tbl_region WHERE name = region) THEN
            INSERT INTO public.tbl_region (name) VALUES (region);
        END IF;

        -- Insert County
        IF NOT EXISTS (SELECT 1 FROM public.tbl_county WHERE name = county) THEN
            INSERT INTO public.tbl_county (reg_id, name, code)
            SELECT reg_id, county, countyCode FROM public.tbl_region WHERE name = region;
        END IF;

        -- Insert Constituency
        IF NOT EXISTS (SELECT 1 FROM public.tbl_constituency WHERE name = constituency) THEN
            INSERT INTO public.tbl_constituency (cty_id, name)
            SELECT cty_id, constituency FROM public.tbl_county WHERE name = county;
        END IF;

        -- Insert Area
        IF NOT EXISTS (SELECT 1 FROM public.tbl_area WHERE name = area) THEN
            INSERT INTO public.tbl_area (cst_id, cty_id, name)
            SELECT cst_id, cty_id, area FROM public.tbl_constituency WHERE name = constituency;
        END IF;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error occurred: %', SQLERRM;
END;
$$;


ALTER PROCEDURE public.insertareadata(areadata jsonb) OWNER TO postgres;

--
-- Name: updatearealocation(integer, double precision, double precision); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.updatearealocation(p_area_id integer, p_lat double precision, p_long double precision)
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE public.tbl_area
    SET geoLocation = ROW(p_lat, p_long)::public.geo
    WHERE area_id = p_area_id;
END $$;


ALTER PROCEDURE public.updatearealocation(p_area_id integer, p_lat double precision, p_long double precision) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: schemaversion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schemaversion (
    scriptname character varying(255),
    scripthash character varying(64),
    applied timestamp without time zone
);


ALTER TABLE public.schemaversion OWNER TO postgres;

--
-- Name: tbl_area; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tbl_area (
    area_id bigint NOT NULL,
    cst_id bigint,
    name text,
    long text,
    lat text,
    date_created timestamp with time zone,
    last_update timestamp with time zone
);


ALTER TABLE public.tbl_area OWNER TO postgres;

--
-- Name: tbl_area_area_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tbl_area_area_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.tbl_area_area_id_seq OWNER TO postgres;

--
-- Name: tbl_area_area_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tbl_area_area_id_seq OWNED BY public.tbl_area.area_id;




--
-- Name: tbl_constituency; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tbl_constituency (
    cst_id integer NOT NULL,
    cty_id integer NOT NULL,
    name character varying NOT NULL,
    date_created timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_update timestamp without time zone
);


ALTER TABLE public.tbl_constituency OWNER TO postgres;

--
-- Name: tbl_constituency_cst_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tbl_constituency_cst_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.tbl_constituency_cst_id_seq OWNER TO postgres;

--
-- Name: tbl_constituency_cst_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tbl_constituency_cst_id_seq OWNED BY public.tbl_constituency.cst_id;


--
-- Name: tbl_contact; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tbl_contact (
    cnt_id bigint NOT NULL,
    area_id bigint,
    cat_id bigint,
    msisdn text,
    first_name text,
    last_name text,
    username text,
    password text,
    email text,
    auth_token text,
    date_created timestamp with time zone,
    last_update timestamp with time zone
);


ALTER TABLE public.tbl_contact OWNER TO postgres;

--
-- Name: tbl_contact_cnt_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tbl_contact_cnt_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tbl_contact_cnt_id_seq OWNER TO postgres;

--
-- Name: tbl_contact_cnt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tbl_contact_cnt_id_seq OWNED BY public.tbl_contact.cnt_id;


--
-- Name: tbl_county; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tbl_county (
    cty_id integer NOT NULL,
    reg_id integer NOT NULL,
    code character varying(100) NOT NULL,
    name character varying(4000) NOT NULL,
    date_created timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_update timestamp without time zone
);


ALTER TABLE public.tbl_county OWNER TO postgres;

--
-- Name: tbl_county_cty_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tbl_county_cty_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.tbl_county_cty_id_seq OWNER TO postgres;

--
-- Name: tbl_county_cty_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tbl_county_cty_id_seq OWNED BY public.tbl_county.cty_id;


--
-- Name: tbl_region; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tbl_region (
    reg_id integer NOT NULL,
    name text,
    date_created timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_update timestamp without time zone
);


ALTER TABLE public.tbl_region OWNER TO postgres;

--
-- Name: tbl_region_reg_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tbl_region_reg_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.tbl_region_reg_id_seq OWNER TO postgres;

--
-- Name: tbl_region_reg_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tbl_region_reg_id_seq OWNED BY public.tbl_region.reg_id;


--
-- Name: tbl_category; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tbl_category (
    cat_id bigint NOT NULL,
    parent_id bigint NOT NULL DEFAULT 0,
    name character varying NOT NULL,
    description character varying NOT NULL,
    amount bigint NOT NULL,
    date_created timestamp with time zone DEFAULT '2024-08-11 23:24:06.708823+03'::timestamp with time zone NOT NULL,
    last_update timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tbl_category OWNER TO postgres;

--
-- Name: tbl_category_cat_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tbl_category_cat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tbl_category_cat_id_seq OWNER TO postgres;

--
-- Name: tbl_category_cat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tbl_category_cat_id_seq OWNED BY public.tbl_category.cat_id;


--
-- Name: tbl_ussd_sesions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tbl_ussd_sesions (
    session_id text NOT NULL,
    msisdn text NOT NULL,
    plan_payload text,
    region_payload text,
    county_payload text,
    constituency_payload text,
    area_payload text,
    completed text DEFAULT 'No'::text,
    date_created timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_update timestamp with time zone NOT NULL
);


ALTER TABLE public.tbl_ussd_sesions OWNER TO postgres;

--
-- Name: tbl_constituency cst_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbl_constituency ALTER COLUMN cst_id SET DEFAULT nextval('public.tbl_constituency_cst_id_seq'::regclass);


--
-- Name: tbl_contact cnt_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbl_contact ALTER COLUMN cnt_id SET DEFAULT nextval('public.tbl_contact_cnt_id_seq'::regclass);


--
-- Name: tbl_county cty_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbl_county ALTER COLUMN cty_id SET DEFAULT nextval('public.tbl_county_cty_id_seq'::regclass);



--
-- Name: tbl_region reg_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbl_region ALTER COLUMN reg_id SET DEFAULT nextval('public.tbl_region_reg_id_seq'::regclass);


--
-- Name: tbl_category cat_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbl_category ALTER COLUMN cat_id SET DEFAULT nextval('public.tbl_category_cat_id_seq'::regclass);


--
-- Data for Name: schemaversion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schemaversion (scriptname, scripthash, applied) FROM stdin;
150-public.sql	66c97c441343f075ed166a37d7b5ff98b301230a16dbce1ba1d5e4a8845d4418	2024-08-02 15:05:32.907592
200-public.tbl_area_area_id_seq.sql	52d19fdc8b56194c55a979ec661d05cd749d3fca32d75356b35cdad9995f545c	2024-08-02 15:05:32.907592
200-public.tbl_campaign_cmp_id_seq.sql	2204b126e39dd53c47deacaf598e90ec12c1e50ffce982661fa203598f11b1a0	2024-08-02 15:05:32.907592
200-public.tbl_constituency_cst_id_seq.sql	efb6204ddb7bae2c81dd3ddc116c1739c892d5a59d33930b4d71fb7bfb48916d	2024-08-02 15:05:32.907592
200-public.tbl_contacts_cnt_id_seq.sql	de9515cf4ff5957597db30251172fa9b4bbf8bec0bd5b057e19a817af2c942a3	2024-08-02 15:05:32.907592
200-public.tbl_county_cty_id_seq.sql	18a45af1e8f96721586db3489807ae17c0ef61112f36bc825404497f5ca2b950	2024-08-02 15:05:32.907592
200-public.tbl_outage_area_oct_id_seq.sql	fc357c4d34ded20ebcc8d767bbfbe2df5d8550c9c735e5faebf0a7e58057e6e6	2024-08-02 15:05:32.907592
200-public.tbl_outage_sms_ots_id_seq.sql	c98d08fa360bef93ce08380b6d5e1501968e7a78a600a721185dd61a0db1715b	2024-08-02 15:05:32.907592
200-public.tbl_region_reg_id_seq.sql	6e0b6b85862b08f820d957e98cba3e0bd303692424b1b75bc95719bf4a18ee7a	2024-08-02 15:05:32.907592
300-public.geo.sql	90169efa84cd6a07520f64606a6f4616b42714970a8391e62fabf8d9bdf6e19b	2024-08-02 15:05:32.907592
350-public.tbl_area.sql	7aec5e420c85f84ed684494b72c4b7be8e4bcd65c82aceb79a05745a5377f84f	2024-08-02 15:05:32.907592
350-public.tbl_campaign.sql	0ad0fb5dc926d92f0f0b2b8557421753548fb9335fdcdf5d4bf11e62383dbc89	2024-08-02 15:05:32.907592
350-public.tbl_constituency.sql	038c185a65657b68d16dceeb66780e3918fe5685bb8fc48aca492875005a2549	2024-08-02 15:05:32.907592
350-public.tbl_contact.sql	ca660bd990f2210c95376c5a0fb5e360119b802d19ad84a409a9368a6ba807fe	2024-08-02 15:05:32.907592
350-public.tbl_county.sql	3859b2e2bae3099f95a3f8973f7ef81826d9e1df0207e5a0f081fc2288b349e5	2024-08-02 15:05:32.907592
350-public.tbl_outage.sql	4843f6a40f86ff1c397ad254fd3d07b2ba8343acf4e31937767e9880b0ce842d	2024-08-02 15:05:32.907592
350-public.tbl_outage_area.sql	70dab5131239544b6b6b9837f073d745c77fda6c98aacb6cdf9021251c4f6f46	2024-08-02 15:05:32.907592
350-public.tbl_outage_message.sql	eadd3da4da05146e6aa723acd04357aa3dbfe1586b62843be49ee35739a1cc57	2024-08-02 15:05:32.907592
350-public.tbl_region.sql	113427eb885a6109ff95cc2f57d55c38a2b1fa257c3c6557158d8a32b2d4f9f8	2024-08-02 15:05:32.907592
350-public.tbl_category.sql	eae95448744b83d24cdf1e70db04f16381ca5ef54461afbfc4df463bfa4f73ad	2024-08-02 15:05:32.907592
350-public.tbl_user_category.sql	1acc9556325becdf3e097f1732673b64fe11102b90a37bbdaa3c968fdbd63773	2024-08-02 15:05:32.907592
390-alterTable.sql	c29bcb4eeca54089591b92586a102857218ede8887293ebeb08294188def1da4	2024-08-02 15:05:32.907592
400-public.area_data_tvp.sql	a449b7073211402bf05602a36d66b2d4181b5a334001da52aea7b612c362675b	2024-08-02 15:05:32.907592
650-public.area_data_add.sql	4523864a3b78220d19296c08c3292fc0e38ab59a51b6ff8fe4cc3cd69303aa63	2024-08-02 15:05:32.907592
650-public.area_data_fetch.sql	dd119cd5fb7393dd0e865364ef1bde8f5230b71588f1f5bd0e7597e97946ab1c	2024-08-02 15:05:32.907592
650-public.area_update_location.sql	e2d7a20cdfcb0ace4b85966bef0fbbbc6743904dbc750a39a980577af5efa59a	2024-08-02 15:05:32.907592
800-table_indexes.sql	6225ffc1903434235d2fbb593617b698225ca7bc975b56381e2bcbc5f182e277	2024-08-02 15:05:32.907592
850.public.seed_area_data.js	fbefaf3e91be17ea61bb7a1aac97d0d8f70eae9cc24081e96fba6f0d492c91ea	2024-08-02 15:09:07.187413
350-public.tbl_outage_message.sql	a0e415d6b593b3177de61b8856ef41b3d4912adc096adcb34599d96b25fcdd3d	2024-08-02 15:15:51.011602
\.


--
-- Data for Name: tbl_area; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tbl_area (area_id, cst_id, name, long, lat, date_created, last_update) FROM stdin;
1	1	Jomvu Kuu	\N	\N	2024-08-02 15:09:07.187413+03	\N
2	1	Miritini	\N	\N	2024-08-02 15:09:07.187413+03	\N
3	1	Mikindani	\N	\N	2024-08-02 15:09:07.187413+03	\N
4	2	Chaani	\N	\N	2024-08-02 15:09:07.187413+03	\N
5	3	Kadzandani	\N	\N	2024-08-02 15:09:07.187413+03	\N
6	4	Magogoni	\N	\N	2024-08-02 15:09:07.187413+03	\N
7	4	Shanzu	\N	\N	2024-08-02 15:09:07.187413+03	\N
8	5	Kayole Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
9	5	Kayole South	\N	\N	2024-08-02 15:09:07.187413+03	\N
10	5	Komarock	\N	\N	2024-08-02 15:09:07.187413+03	\N
11	5	Matopeni	\N	\N	2024-08-02 15:09:07.187413+03	\N
12	6	Kaloleni	\N	\N	2024-08-02 15:09:07.187413+03	\N
13	6	Marungu	\N	\N	2024-08-02 15:09:07.187413+03	\N
14	6	Kasigau	\N	\N	2024-08-02 15:09:07.187413+03	\N
15	6	Ngolia	\N	\N	2024-08-02 15:09:07.187413+03	\N
16	7	Liboi	\N	\N	2024-08-02 15:09:07.187413+03	\N
17	7	Abakaile	\N	\N	2024-08-02 15:09:07.187413+03	\N
18	8	Godoma	\N	\N	2024-08-02 15:09:07.187413+03	\N
19	9	Sericho	\N	\N	2024-08-02 15:09:07.187413+03	\N
20	10	Ntima East	\N	\N	2024-08-02 15:09:07.187413+03	\N
21	10	Ntima West	\N	\N	2024-08-02 15:09:07.187413+03	\N
22	10	Nyaki West	\N	\N	2024-08-02 15:09:07.187413+03	\N
23	10	Nyaki East	\N	\N	2024-08-02 15:09:07.187413+03	\N
24	11	Bukembe West	\N	\N	2024-08-02 15:09:07.187413+03	\N
25	11	Bukembe East	\N	\N	2024-08-02 15:09:07.187413+03	\N
26	11	Township	\N	\N	2024-08-02 15:09:07.187413+03	\N
27	11	Khalaba	\N	\N	2024-08-02 15:09:07.187413+03	\N
28	11	Musikoma	\N	\N	2024-08-02 15:09:07.187413+03	\N
29	11	East Sangalo	\N	\N	2024-08-02 15:09:07.187413+03	\N
30	11	Marakaru/Tuuti	\N	\N	2024-08-02 15:09:07.187413+03	\N
31	11	Sangalo West	\N	\N	2024-08-02 15:09:07.187413+03	\N
32	12	Mosiro	\N	\N	2024-08-02 15:09:07.187413+03	\N
33	12	Ildamat	\N	\N	2024-08-02 15:09:07.187413+03	\N
34	12	Keekonyokie	\N	\N	2024-08-02 15:09:07.187413+03	\N
35	12	Suswa	\N	\N	2024-08-02 15:09:07.187413+03	\N
36	13	Engineer	\N	\N	2024-08-02 15:09:07.187413+03	\N
37	13	Gathara	\N	\N	2024-08-02 15:09:07.187413+03	\N
38	13	North Kinangop	\N	\N	2024-08-02 15:09:07.187413+03	\N
39	13	Murungaru	\N	\N	2024-08-02 15:09:07.187413+03	\N
40	13	Njabini\\\\Kiburu	\N	\N	2024-08-02 15:09:07.187413+03	\N
41	13	Nyakio	\N	\N	2024-08-02 15:09:07.187413+03	\N
42	13	Githabai	\N	\N	2024-08-02 15:09:07.187413+03	\N
43	13	Magumu	\N	\N	2024-08-02 15:09:07.187413+03	\N
44	14	Lodokejek	\N	\N	2024-08-02 15:09:07.187413+03	\N
45	14	Suguta Marmar	\N	\N	2024-08-02 15:09:07.187413+03	\N
46	14	Maralal	\N	\N	2024-08-02 15:09:07.187413+03	\N
47	14	Loosuk	\N	\N	2024-08-02 15:09:07.187413+03	\N
48	14	Poro	\N	\N	2024-08-02 15:09:07.187413+03	\N
49	15	Chepkumia	\N	\N	2024-08-02 15:09:07.187413+03	\N
50	15	Kapkangani	\N	\N	2024-08-02 15:09:07.187413+03	\N
51	15	Kapsabet	\N	\N	2024-08-02 15:09:07.187413+03	\N
52	15	Kilibwoni	\N	\N	2024-08-02 15:09:07.187413+03	\N
53	16	Huruma	\N	\N	2024-08-02 15:09:07.187413+03	\N
54	17	Wiga	\N	\N	2024-08-02 15:09:07.187413+03	\N
55	17	Wasweta Ii	\N	\N	2024-08-02 15:09:07.187413+03	\N
56	17	Ragana-Oruba	\N	\N	2024-08-02 15:09:07.187413+03	\N
57	17	Wasimbete	\N	\N	2024-08-02 15:09:07.187413+03	\N
58	18	Chekalini	\N	\N	2024-08-02 15:09:07.187413+03	\N
59	18	Chevaywa	\N	\N	2024-08-02 15:09:07.187413+03	\N
60	18	Lwandeti	\N	\N	2024-08-02 15:09:07.187413+03	\N
61	19	Kiptuya	\N	\N	2024-08-02 15:09:07.187413+03	\N
62	20	Olorropil	\N	\N	2024-08-02 15:09:07.187413+03	\N
63	20	Melili	\N	\N	2024-08-02 15:09:07.187413+03	\N
64	21	Muruka	\N	\N	2024-08-02 15:09:07.187413+03	\N
65	21	Kagundu-Ini	\N	\N	2024-08-02 15:09:07.187413+03	\N
66	21	Gaichanjiru	\N	\N	2024-08-02 15:09:07.187413+03	\N
67	21	Ithiru	\N	\N	2024-08-02 15:09:07.187413+03	\N
68	21	Ruchu	\N	\N	2024-08-02 15:09:07.187413+03	\N
69	22	Nyabasi West	\N	\N	2024-08-02 15:09:07.187413+03	\N
70	23	Gaturi	\N	\N	2024-08-02 15:09:07.187413+03	\N
71	24	South East Alego	\N	\N	2024-08-02 15:09:07.187413+03	\N
72	25	Kuinet/Kapsuswa	\N	\N	2024-08-02 15:09:07.187413+03	\N
73	26	Mwiki	\N	\N	2024-08-02 15:09:07.187413+03	\N
74	26	Mwihoko	\N	\N	2024-08-02 15:09:07.187413+03	\N
75	27	Sameta/Mokwerero	\N	\N	2024-08-02 15:09:07.187413+03	\N
76	27	Bobasi Boitangare	\N	\N	2024-08-02 15:09:07.187413+03	\N
77	28	South Kabras	\N	\N	2024-08-02 15:09:07.187413+03	\N
78	29	Mekenene	\N	\N	2024-08-02 15:09:07.187413+03	\N
79	2	Port Reitz	\N	\N	2024-08-02 15:09:07.187413+03	\N
80	2	Kipevu	\N	\N	2024-08-02 15:09:07.187413+03	\N
81	2	Airport	\N	\N	2024-08-02 15:09:07.187413+03	\N
82	2	Changamwe	\N	\N	2024-08-02 15:09:07.187413+03	\N
83	3	Frere Town	\N	\N	2024-08-02 15:09:07.187413+03	\N
84	3	Ziwa La Ngombe	\N	\N	2024-08-02 15:09:07.187413+03	\N
85	3	Mkomani	\N	\N	2024-08-02 15:09:07.187413+03	\N
86	3	Kongowea	\N	\N	2024-08-02 15:09:07.187413+03	\N
87	30	Mtongwe	\N	\N	2024-08-02 15:09:07.187413+03	\N
88	30	Shika Adabu	\N	\N	2024-08-02 15:09:07.187413+03	\N
89	30	Bofu	\N	\N	2024-08-02 15:09:07.187413+03	\N
90	30	Likoni	\N	\N	2024-08-02 15:09:07.187413+03	\N
91	30	Timbwani	\N	\N	2024-08-02 15:09:07.187413+03	\N
92	31	Mji Wa Kale/Makadara	\N	\N	2024-08-02 15:09:07.187413+03	\N
93	31	Tudor	\N	\N	2024-08-02 15:09:07.187413+03	\N
94	31	Tononoka	\N	\N	2024-08-02 15:09:07.187413+03	\N
95	31	Shimanzi/Ganjoni	\N	\N	2024-08-02 15:09:07.187413+03	\N
96	31	Majengo	\N	\N	2024-08-02 15:09:07.187413+03	\N
97	4	Mjambere	\N	\N	2024-08-02 15:09:07.187413+03	\N
98	4	Junda	\N	\N	2024-08-02 15:09:07.187413+03	\N
99	4	Bamburi	\N	\N	2024-08-02 15:09:07.187413+03	\N
100	4	Mwakirunge	\N	\N	2024-08-02 15:09:07.187413+03	\N
101	4	Mtopanga	\N	\N	2024-08-02 15:09:07.187413+03	\N
102	32	Pongwekikoneni	\N	\N	2024-08-02 15:09:07.187413+03	\N
103	32	Dzombo	\N	\N	2024-08-02 15:09:07.187413+03	\N
104	32	Mwereni	\N	\N	2024-08-02 15:09:07.187413+03	\N
105	32	Vanga	\N	\N	2024-08-02 15:09:07.187413+03	\N
106	33	Nadavaya	\N	\N	2024-08-02 15:09:07.187413+03	\N
107	33	Puma	\N	\N	2024-08-02 15:09:07.187413+03	\N
108	33	Kinango	\N	\N	2024-08-02 15:09:07.187413+03	\N
109	33	Mackinnon-Road	\N	\N	2024-08-02 15:09:07.187413+03	\N
110	33	Chengoni/Samburu	\N	\N	2024-08-02 15:09:07.187413+03	\N
111	33	Mwavumbo	\N	\N	2024-08-02 15:09:07.187413+03	\N
112	33	Kasemeni	\N	\N	2024-08-02 15:09:07.187413+03	\N
113	34	Tsimba Golini	\N	\N	2024-08-02 15:09:07.187413+03	\N
114	34	Waa	\N	\N	2024-08-02 15:09:07.187413+03	\N
115	34	Tiwi	\N	\N	2024-08-02 15:09:07.187413+03	\N
116	34	Kubo South	\N	\N	2024-08-02 15:09:07.187413+03	\N
117	34	Mkongani	\N	\N	2024-08-02 15:09:07.187413+03	\N
118	35	Gombatobongwe	\N	\N	2024-08-02 15:09:07.187413+03	\N
119	35	Ukunda	\N	\N	2024-08-02 15:09:07.187413+03	\N
120	35	Kinondo	\N	\N	2024-08-02 15:09:07.187413+03	\N
121	35	Ramisi	\N	\N	2024-08-02 15:09:07.187413+03	\N
122	36	Tezo	\N	\N	2024-08-02 15:09:07.187413+03	\N
123	36	Sokoni	\N	\N	2024-08-02 15:09:07.187413+03	\N
124	36	Kibarani	\N	\N	2024-08-02 15:09:07.187413+03	\N
125	36	Dabaso	\N	\N	2024-08-02 15:09:07.187413+03	\N
126	36	Matsangoni	\N	\N	2024-08-02 15:09:07.187413+03	\N
127	36	Watamu	\N	\N	2024-08-02 15:09:07.187413+03	\N
128	36	Mnarani	\N	\N	2024-08-02 15:09:07.187413+03	\N
129	37	Junju	\N	\N	2024-08-02 15:09:07.187413+03	\N
130	37	Mwarakaya	\N	\N	2024-08-02 15:09:07.187413+03	\N
131	37	Shimo La Tewa	\N	\N	2024-08-02 15:09:07.187413+03	\N
132	37	Chasimba	\N	\N	2024-08-02 15:09:07.187413+03	\N
133	37	Mtepeni	\N	\N	2024-08-02 15:09:07.187413+03	\N
134	38	Mwawesa	\N	\N	2024-08-02 15:09:07.187413+03	\N
135	38	Ruruma	\N	\N	2024-08-02 15:09:07.187413+03	\N
136	38	Kambe/Ribe	\N	\N	2024-08-02 15:09:07.187413+03	\N
137	38	Rabai/Kisurutini	\N	\N	2024-08-02 15:09:07.187413+03	\N
138	39	Ganze	\N	\N	2024-08-02 15:09:07.187413+03	\N
139	39	Bamba	\N	\N	2024-08-02 15:09:07.187413+03	\N
140	39	Jaribuni	\N	\N	2024-08-02 15:09:07.187413+03	\N
141	39	Sokoke	\N	\N	2024-08-02 15:09:07.187413+03	\N
142	40	Jilore	\N	\N	2024-08-02 15:09:07.187413+03	\N
143	40	Kakuyuni	\N	\N	2024-08-02 15:09:07.187413+03	\N
144	40	Ganda	\N	\N	2024-08-02 15:09:07.187413+03	\N
145	40	Malindi Town	\N	\N	2024-08-02 15:09:07.187413+03	\N
146	40	Shella	\N	\N	2024-08-02 15:09:07.187413+03	\N
147	41	Mariakani	\N	\N	2024-08-02 15:09:07.187413+03	\N
148	41	Kayafungo	\N	\N	2024-08-02 15:09:07.187413+03	\N
149	41	Mwanamwinga	\N	\N	2024-08-02 15:09:07.187413+03	\N
150	42	Marafa	\N	\N	2024-08-02 15:09:07.187413+03	\N
151	42	Magarini	\N	\N	2024-08-02 15:09:07.187413+03	\N
152	42	Gongoni	\N	\N	2024-08-02 15:09:07.187413+03	\N
153	42	Adu	\N	\N	2024-08-02 15:09:07.187413+03	\N
154	42	Garashi	\N	\N	2024-08-02 15:09:07.187413+03	\N
155	42	Sabaki	\N	\N	2024-08-02 15:09:07.187413+03	\N
156	43	Chewele	\N	\N	2024-08-02 15:09:07.187413+03	\N
157	43	Bura	\N	\N	2024-08-02 15:09:07.187413+03	\N
158	43	Bangale	\N	\N	2024-08-02 15:09:07.187413+03	\N
159	43	Sala	\N	\N	2024-08-02 15:09:07.187413+03	\N
160	43	Madogo	\N	\N	2024-08-02 15:09:07.187413+03	\N
161	44	Kipini East	\N	\N	2024-08-02 15:09:07.187413+03	\N
162	44	Garsen South	\N	\N	2024-08-02 15:09:07.187413+03	\N
163	44	Kipini West	\N	\N	2024-08-02 15:09:07.187413+03	\N
164	44	Garsen Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
165	44	Garsen West	\N	\N	2024-08-02 15:09:07.187413+03	\N
166	44	Garsen North	\N	\N	2024-08-02 15:09:07.187413+03	\N
167	45	Kinakomba	\N	\N	2024-08-02 15:09:07.187413+03	\N
168	45	Mikinduni	\N	\N	2024-08-02 15:09:07.187413+03	\N
169	45	Chewani	\N	\N	2024-08-02 15:09:07.187413+03	\N
170	45	Wayu	\N	\N	2024-08-02 15:09:07.187413+03	\N
171	46	Faza	\N	\N	2024-08-02 15:09:07.187413+03	\N
172	46	Kiunga	\N	\N	2024-08-02 15:09:07.187413+03	\N
173	46	Basuba	\N	\N	2024-08-02 15:09:07.187413+03	\N
174	47	Hindi	\N	\N	2024-08-02 15:09:07.187413+03	\N
175	47	Mkunumbi	\N	\N	2024-08-02 15:09:07.187413+03	\N
176	47	Hongwe	\N	\N	2024-08-02 15:09:07.187413+03	\N
177	47	Witu	\N	\N	2024-08-02 15:09:07.187413+03	\N
178	47	Bahari	\N	\N	2024-08-02 15:09:07.187413+03	\N
179	48	Wundanyi/Mbale	\N	\N	2024-08-02 15:09:07.187413+03	\N
180	48	Werugha	\N	\N	2024-08-02 15:09:07.187413+03	\N
181	48	Wumingu/Kishushe	\N	\N	2024-08-02 15:09:07.187413+03	\N
182	48	Mwanda/Mgange	\N	\N	2024-08-02 15:09:07.187413+03	\N
183	49	Ronge	\N	\N	2024-08-02 15:09:07.187413+03	\N
184	49	Mwatate	\N	\N	2024-08-02 15:09:07.187413+03	\N
185	49	Chawia	\N	\N	2024-08-02 15:09:07.187413+03	\N
186	49	Wusi/Kishamba	\N	\N	2024-08-02 15:09:07.187413+03	\N
187	6	Mbololo	\N	\N	2024-08-02 15:09:07.187413+03	\N
188	6	Sagalla	\N	\N	2024-08-02 15:09:07.187413+03	\N
189	50	Chala	\N	\N	2024-08-02 15:09:07.187413+03	\N
190	50	Mahoo	\N	\N	2024-08-02 15:09:07.187413+03	\N
191	50	Bomeni	\N	\N	2024-08-02 15:09:07.187413+03	\N
192	50	Mboghoni	\N	\N	2024-08-02 15:09:07.187413+03	\N
193	50	Mata	\N	\N	2024-08-02 15:09:07.187413+03	\N
194	51	Waberi	\N	\N	2024-08-02 15:09:07.187413+03	\N
195	51	Galbet	\N	\N	2024-08-02 15:09:07.187413+03	\N
196	51	Iftin	\N	\N	2024-08-02 15:09:07.187413+03	\N
197	52	Hulugho	\N	\N	2024-08-02 15:09:07.187413+03	\N
198	52	Sangailu	\N	\N	2024-08-02 15:09:07.187413+03	\N
199	52	Ijara	\N	\N	2024-08-02 15:09:07.187413+03	\N
200	52	Masalani	\N	\N	2024-08-02 15:09:07.187413+03	\N
201	7	Dertu	\N	\N	2024-08-02 15:09:07.187413+03	\N
202	7	Dadaab	\N	\N	2024-08-02 15:09:07.187413+03	\N
203	7	Labasigale	\N	\N	2024-08-02 15:09:07.187413+03	\N
204	7	Damajale	\N	\N	2024-08-02 15:09:07.187413+03	\N
205	53	Modogashe	\N	\N	2024-08-02 15:09:07.187413+03	\N
206	53	Benane	\N	\N	2024-08-02 15:09:07.187413+03	\N
207	53	Goreale	\N	\N	2024-08-02 15:09:07.187413+03	\N
208	53	Maalimin	\N	\N	2024-08-02 15:09:07.187413+03	\N
209	53	Sabena	\N	\N	2024-08-02 15:09:07.187413+03	\N
210	53	Baraki	\N	\N	2024-08-02 15:09:07.187413+03	\N
211	54	Dekaharia	\N	\N	2024-08-02 15:09:07.187413+03	\N
212	54	Jarajila	\N	\N	2024-08-02 15:09:07.187413+03	\N
213	54	Fafi	\N	\N	2024-08-02 15:09:07.187413+03	\N
214	54	Nanighi	\N	\N	2024-08-02 15:09:07.187413+03	\N
215	55	Balambala	\N	\N	2024-08-02 15:09:07.187413+03	\N
216	55	Danyere	\N	\N	2024-08-02 15:09:07.187413+03	\N
217	55	Jara Jara	\N	\N	2024-08-02 15:09:07.187413+03	\N
218	55	Saka	\N	\N	2024-08-02 15:09:07.187413+03	\N
219	55	Sankuri	\N	\N	2024-08-02 15:09:07.187413+03	\N
220	8	Gurar	\N	\N	2024-08-02 15:09:07.187413+03	\N
221	8	Bute	\N	\N	2024-08-02 15:09:07.187413+03	\N
222	8	Korondile	\N	\N	2024-08-02 15:09:07.187413+03	\N
223	8	Malkagufu	\N	\N	2024-08-02 15:09:07.187413+03	\N
224	8	Batalu	\N	\N	2024-08-02 15:09:07.187413+03	\N
225	8	Danaba	\N	\N	2024-08-02 15:09:07.187413+03	\N
226	56	Eldas	\N	\N	2024-08-02 15:09:07.187413+03	\N
227	56	Della	\N	\N	2024-08-02 15:09:07.187413+03	\N
228	56	Lakoley South/Basir	\N	\N	2024-08-02 15:09:07.187413+03	\N
229	56	Elnur/Tula Tula	\N	\N	2024-08-02 15:09:07.187413+03	\N
230	57	Elben	\N	\N	2024-08-02 15:09:07.187413+03	\N
231	57	Sarman	\N	\N	2024-08-02 15:09:07.187413+03	\N
232	57	Tarbaj	\N	\N	2024-08-02 15:09:07.187413+03	\N
233	57	Wargadud	\N	\N	2024-08-02 15:09:07.187413+03	\N
234	58	Arbajahan	\N	\N	2024-08-02 15:09:07.187413+03	\N
235	58	Hadado/Athibohol	\N	\N	2024-08-02 15:09:07.187413+03	\N
236	58	Ademasajide	\N	\N	2024-08-02 15:09:07.187413+03	\N
237	58	Wagalla/Ganyure	\N	\N	2024-08-02 15:09:07.187413+03	\N
238	59	Burder	\N	\N	2024-08-02 15:09:07.187413+03	\N
239	59	Dadaja Bulla	\N	\N	2024-08-02 15:09:07.187413+03	\N
240	59	Habasswein	\N	\N	2024-08-02 15:09:07.187413+03	\N
241	59	Lagboghol South	\N	\N	2024-08-02 15:09:07.187413+03	\N
242	59	Ibrahim Ure	\N	\N	2024-08-02 15:09:07.187413+03	\N
243	59	Diif	\N	\N	2024-08-02 15:09:07.187413+03	\N
244	60	Wagberi	\N	\N	2024-08-02 15:09:07.187413+03	\N
245	60	Barwago	\N	\N	2024-08-02 15:09:07.187413+03	\N
246	60	Khorof/Harar	\N	\N	2024-08-02 15:09:07.187413+03	\N
247	61	Ashabito	\N	\N	2024-08-02 15:09:07.187413+03	\N
248	61	Guticha	\N	\N	2024-08-02 15:09:07.187413+03	\N
249	61	Morothile	\N	\N	2024-08-02 15:09:07.187413+03	\N
250	61	Rhamu	\N	\N	2024-08-02 15:09:07.187413+03	\N
251	61	Rhamu-Dimtu	\N	\N	2024-08-02 15:09:07.187413+03	\N
252	62	Wargudud	\N	\N	2024-08-02 15:09:07.187413+03	\N
253	62	Kutulo	\N	\N	2024-08-02 15:09:07.187413+03	\N
254	62	Elwak South	\N	\N	2024-08-02 15:09:07.187413+03	\N
255	62	Elwak North	\N	\N	2024-08-02 15:09:07.187413+03	\N
256	62	Shimbir Fatuma	\N	\N	2024-08-02 15:09:07.187413+03	\N
257	63	Arabia	\N	\N	2024-08-02 15:09:07.187413+03	\N
258	63	Bulla Mpya	\N	\N	2024-08-02 15:09:07.187413+03	\N
259	63	Khalalio	\N	\N	2024-08-02 15:09:07.187413+03	\N
260	63	Neboi	\N	\N	2024-08-02 15:09:07.187413+03	\N
261	64	Takaba South	\N	\N	2024-08-02 15:09:07.187413+03	\N
262	64	Takaba	\N	\N	2024-08-02 15:09:07.187413+03	\N
263	64	Lag Sure	\N	\N	2024-08-02 15:09:07.187413+03	\N
264	64	Dandu	\N	\N	2024-08-02 15:09:07.187413+03	\N
265	64	Gither	\N	\N	2024-08-02 15:09:07.187413+03	\N
266	65	Banissa	\N	\N	2024-08-02 15:09:07.187413+03	\N
267	65	Derkhale	\N	\N	2024-08-02 15:09:07.187413+03	\N
268	65	Guba	\N	\N	2024-08-02 15:09:07.187413+03	\N
269	65	Malkamari	\N	\N	2024-08-02 15:09:07.187413+03	\N
270	65	Kiliwehiri	\N	\N	2024-08-02 15:09:07.187413+03	\N
271	66	Libehia	\N	\N	2024-08-02 15:09:07.187413+03	\N
272	66	Fino	\N	\N	2024-08-02 15:09:07.187413+03	\N
273	66	Lafey	\N	\N	2024-08-02 15:09:07.187413+03	\N
274	66	Warankara	\N	\N	2024-08-02 15:09:07.187413+03	\N
275	66	Alungo Gof	\N	\N	2024-08-02 15:09:07.187413+03	\N
276	67	Butiye	\N	\N	2024-08-02 15:09:07.187413+03	\N
277	67	Sololo	\N	\N	2024-08-02 15:09:07.187413+03	\N
278	67	Heilu-Manyatta	\N	\N	2024-08-02 15:09:07.187413+03	\N
279	67	Golbo	\N	\N	2024-08-02 15:09:07.187413+03	\N
280	67	Moyale Township	\N	\N	2024-08-02 15:09:07.187413+03	\N
281	67	Uran	\N	\N	2024-08-02 15:09:07.187413+03	\N
282	67	Obbu	\N	\N	2024-08-02 15:09:07.187413+03	\N
283	68	Sagante/Jaldesa	\N	\N	2024-08-02 15:09:07.187413+03	\N
284	68	Karare	\N	\N	2024-08-02 15:09:07.187413+03	\N
285	68	Marsabit Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
286	69	Illeret	\N	\N	2024-08-02 15:09:07.187413+03	\N
287	69	North Horr	\N	\N	2024-08-02 15:09:07.187413+03	\N
288	69	Dukana	\N	\N	2024-08-02 15:09:07.187413+03	\N
289	69	Maikona	\N	\N	2024-08-02 15:09:07.187413+03	\N
290	69	Turbi	\N	\N	2024-08-02 15:09:07.187413+03	\N
291	70	Loiyangalani	\N	\N	2024-08-02 15:09:07.187413+03	\N
292	70	Kargi/South Horr	\N	\N	2024-08-02 15:09:07.187413+03	\N
293	70	Korr/Ngurunit	\N	\N	2024-08-02 15:09:07.187413+03	\N
294	70	Log Logo	\N	\N	2024-08-02 15:09:07.187413+03	\N
295	70	Laisamis	\N	\N	2024-08-02 15:09:07.187413+03	\N
296	71	Wabera	\N	\N	2024-08-02 15:09:07.187413+03	\N
297	71	Bulla Pesa	\N	\N	2024-08-02 15:09:07.187413+03	\N
298	71	Chari	\N	\N	2024-08-02 15:09:07.187413+03	\N
299	71	Cherab	\N	\N	2024-08-02 15:09:07.187413+03	\N
300	71	Ngare Mara	\N	\N	2024-08-02 15:09:07.187413+03	\N
301	71	Burat	\N	\N	2024-08-02 15:09:07.187413+03	\N
302	71	Oldonyiro	\N	\N	2024-08-02 15:09:07.187413+03	\N
303	9	Garbatulla	\N	\N	2024-08-02 15:09:07.187413+03	\N
304	9	Kinna	\N	\N	2024-08-02 15:09:07.187413+03	\N
305	10	Municipality	\N	\N	2024-08-02 15:09:07.187413+03	\N
306	72	Maua	\N	\N	2024-08-02 15:09:07.187413+03	\N
307	72	Kiegoi/Antubochiu	\N	\N	2024-08-02 15:09:07.187413+03	\N
308	72	Athiru Gaiti	\N	\N	2024-08-02 15:09:07.187413+03	\N
309	72	Akachiu	\N	\N	2024-08-02 15:09:07.187413+03	\N
310	72	Kanuni	\N	\N	2024-08-02 15:09:07.187413+03	\N
311	73	Mitunguu	\N	\N	2024-08-02 15:09:07.187413+03	\N
312	73	Igoji East	\N	\N	2024-08-02 15:09:07.187413+03	\N
313	73	Igoji West	\N	\N	2024-08-02 15:09:07.187413+03	\N
314	73	Abogeta East	\N	\N	2024-08-02 15:09:07.187413+03	\N
315	73	Abogeta West	\N	\N	2024-08-02 15:09:07.187413+03	\N
316	73	Nkuene	\N	\N	2024-08-02 15:09:07.187413+03	\N
317	74	Mwanganthia	\N	\N	2024-08-02 15:09:07.187413+03	\N
318	74	Abothuguchi Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
319	74	Abothuguchi West	\N	\N	2024-08-02 15:09:07.187413+03	\N
320	74	Kiagu	\N	\N	2024-08-02 15:09:07.187413+03	\N
321	75	Antuambui	\N	\N	2024-08-02 15:09:07.187413+03	\N
322	75	Ntunene	\N	\N	2024-08-02 15:09:07.187413+03	\N
323	75	Antubetwe Kiongo	\N	\N	2024-08-02 15:09:07.187413+03	\N
324	75	Naathu	\N	\N	2024-08-02 15:09:07.187413+03	\N
325	75	Amwathi	\N	\N	2024-08-02 15:09:07.187413+03	\N
326	76	Athwana	\N	\N	2024-08-02 15:09:07.187413+03	\N
327	76	Akithii	\N	\N	2024-08-02 15:09:07.187413+03	\N
328	76	Kianjai	\N	\N	2024-08-02 15:09:07.187413+03	\N
329	76	Nkomo	\N	\N	2024-08-02 15:09:07.187413+03	\N
330	76	Mbeu	\N	\N	2024-08-02 15:09:07.187413+03	\N
331	77	Timau	\N	\N	2024-08-02 15:09:07.187413+03	\N
332	77	Kisima	\N	\N	2024-08-02 15:09:07.187413+03	\N
333	77	Kiirua/Naari	\N	\N	2024-08-02 15:09:07.187413+03	\N
334	77	Ruiri/Rwarera	\N	\N	2024-08-02 15:09:07.187413+03	\N
335	77	Kibirichia	\N	\N	2024-08-02 15:09:07.187413+03	\N
336	78	Akirangondu	\N	\N	2024-08-02 15:09:07.187413+03	\N
337	78	Athiru Ruujine	\N	\N	2024-08-02 15:09:07.187413+03	\N
338	78	Igembe East	\N	\N	2024-08-02 15:09:07.187413+03	\N
339	78	Njia	\N	\N	2024-08-02 15:09:07.187413+03	\N
340	78	Kangeta	\N	\N	2024-08-02 15:09:07.187413+03	\N
341	79	Thangatha	\N	\N	2024-08-02 15:09:07.187413+03	\N
342	79	Mikinduri	\N	\N	2024-08-02 15:09:07.187413+03	\N
343	79	Kiguchwa	\N	\N	2024-08-02 15:09:07.187413+03	\N
344	79	Muthara	\N	\N	2024-08-02 15:09:07.187413+03	\N
345	79	Karama	\N	\N	2024-08-02 15:09:07.187413+03	\N
346	80	Gatunga	\N	\N	2024-08-02 15:09:07.187413+03	\N
347	80	Mukothima	\N	\N	2024-08-02 15:09:07.187413+03	\N
348	80	Nkondi	\N	\N	2024-08-02 15:09:07.187413+03	\N
349	80	Chiakariga	\N	\N	2024-08-02 15:09:07.187413+03	\N
350	80	Marimanti	\N	\N	2024-08-02 15:09:07.187413+03	\N
351	81	Mariani	\N	\N	2024-08-02 15:09:07.187413+03	\N
352	81	Karingani	\N	\N	2024-08-02 15:09:07.187413+03	\N
353	81	Magumoni	\N	\N	2024-08-02 15:09:07.187413+03	\N
354	81	Mugwe	\N	\N	2024-08-02 15:09:07.187413+03	\N
355	81	Igambangombe	\N	\N	2024-08-02 15:09:07.187413+03	\N
356	82	Gaturi North	\N	\N	2024-08-02 15:09:07.187413+03	\N
357	82	Kagaari South	\N	\N	2024-08-02 15:09:07.187413+03	\N
358	82	Central  Ward	\N	\N	2024-08-02 15:09:07.187413+03	\N
359	82	Kagaari North	\N	\N	2024-08-02 15:09:07.187413+03	\N
360	82	Kyeni North	\N	\N	2024-08-02 15:09:07.187413+03	\N
361	82	Kyeni South	\N	\N	2024-08-02 15:09:07.187413+03	\N
362	83	Miambani	\N	\N	2024-08-02 15:09:07.187413+03	\N
363	83	Kyangwithya West	\N	\N	2024-08-02 15:09:07.187413+03	\N
364	83	Mulango	\N	\N	2024-08-02 15:09:07.187413+03	\N
365	83	Kyangwithya East	\N	\N	2024-08-02 15:09:07.187413+03	\N
366	84	Ikanga/Kyatune	\N	\N	2024-08-02 15:09:07.187413+03	\N
367	84	Mutomo	\N	\N	2024-08-02 15:09:07.187413+03	\N
368	85	Zombe/Mwitika	\N	\N	2024-08-02 15:09:07.187413+03	\N
369	85	Chuluni	\N	\N	2024-08-02 15:09:07.187413+03	\N
370	85	Nzambani	\N	\N	2024-08-02 15:09:07.187413+03	\N
371	85	Voo/Kyamatu	\N	\N	2024-08-02 15:09:07.187413+03	\N
372	85	Endau/Malalani	\N	\N	2024-08-02 15:09:07.187413+03	\N
373	85	Mutito/Kaliku	\N	\N	2024-08-02 15:09:07.187413+03	\N
374	86	Mutonguni	\N	\N	2024-08-02 15:09:07.187413+03	\N
375	86	Kauwi	\N	\N	2024-08-02 15:09:07.187413+03	\N
376	86	Matinyani	\N	\N	2024-08-02 15:09:07.187413+03	\N
377	86	Kwa Mutonga/Kithumula	\N	\N	2024-08-02 15:09:07.187413+03	\N
378	87	Ngomeni	\N	\N	2024-08-02 15:09:07.187413+03	\N
379	87	Kyuso	\N	\N	2024-08-02 15:09:07.187413+03	\N
380	87	Mumoni	\N	\N	2024-08-02 15:09:07.187413+03	\N
381	87	Tseikuru	\N	\N	2024-08-02 15:09:07.187413+03	\N
382	87	Tharaka	\N	\N	2024-08-02 15:09:07.187413+03	\N
383	88	Mwea	\N	\N	2024-08-02 15:09:07.187413+03	\N
384	88	Makima	\N	\N	2024-08-02 15:09:07.187413+03	\N
385	88	Mbeti South	\N	\N	2024-08-02 15:09:07.187413+03	\N
386	88	Mavuria	\N	\N	2024-08-02 15:09:07.187413+03	\N
387	88	Kiambere	\N	\N	2024-08-02 15:09:07.187413+03	\N
388	89	Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
389	89	Kivou	\N	\N	2024-08-02 15:09:07.187413+03	\N
390	89	Nguni	\N	\N	2024-08-02 15:09:07.187413+03	\N
391	89	Nuu	\N	\N	2024-08-02 15:09:07.187413+03	\N
392	89	Mui	\N	\N	2024-08-02 15:09:07.187413+03	\N
393	89	Waita	\N	\N	2024-08-02 15:09:07.187413+03	\N
394	90	Kisasi	\N	\N	2024-08-02 15:09:07.187413+03	\N
395	90	Mbitini	\N	\N	2024-08-02 15:09:07.187413+03	\N
396	90	Kwavonza/Yatta	\N	\N	2024-08-02 15:09:07.187413+03	\N
397	90	Kanyangi	\N	\N	2024-08-02 15:09:07.187413+03	\N
398	91	Nthawa	\N	\N	2024-08-02 15:09:07.187413+03	\N
399	91	Muminji	\N	\N	2024-08-02 15:09:07.187413+03	\N
400	91	Evurore	\N	\N	2024-08-02 15:09:07.187413+03	\N
401	92	Mitheru	\N	\N	2024-08-02 15:09:07.187413+03	\N
402	92	Muthambi	\N	\N	2024-08-02 15:09:07.187413+03	\N
403	92	Mwimbi	\N	\N	2024-08-02 15:09:07.187413+03	\N
404	92	Ganga	\N	\N	2024-08-02 15:09:07.187413+03	\N
405	92	Chogoria	\N	\N	2024-08-02 15:09:07.187413+03	\N
406	93	Ruguru/Ngandori	\N	\N	2024-08-02 15:09:07.187413+03	\N
407	93	Kithimu	\N	\N	2024-08-02 15:09:07.187413+03	\N
408	93	Nginda	\N	\N	2024-08-02 15:09:07.187413+03	\N
409	93	Mbeti North	\N	\N	2024-08-02 15:09:07.187413+03	\N
410	93	Kirimari	\N	\N	2024-08-02 15:09:07.187413+03	\N
411	93	Gaturi South	\N	\N	2024-08-02 15:09:07.187413+03	\N
412	94	Kyome/Thaana	\N	\N	2024-08-02 15:09:07.187413+03	\N
413	94	Nguutani	\N	\N	2024-08-02 15:09:07.187413+03	\N
414	94	Migwani	\N	\N	2024-08-02 15:09:07.187413+03	\N
415	94	Kiomo/Kyethani	\N	\N	2024-08-02 15:09:07.187413+03	\N
416	95	Dedan Kimanthi	\N	\N	2024-08-02 15:09:07.187413+03	\N
417	95	Wamagana	\N	\N	2024-08-02 15:09:07.187413+03	\N
418	95	Aguthi/Gaaki	\N	\N	2024-08-02 15:09:07.187413+03	\N
419	96	Tulimani	\N	\N	2024-08-02 15:09:07.187413+03	\N
420	96	Mbooni	\N	\N	2024-08-02 15:09:07.187413+03	\N
421	96	Kithungo/Kitundu	\N	\N	2024-08-02 15:09:07.187413+03	\N
422	96	Kisau/Kiteta	\N	\N	2024-08-02 15:09:07.187413+03	\N
423	96	Waia/Kako	\N	\N	2024-08-02 15:09:07.187413+03	\N
424	96	Kalawa	\N	\N	2024-08-02 15:09:07.187413+03	\N
425	97	Masongaleni	\N	\N	2024-08-02 15:09:07.187413+03	\N
426	97	Mtito Andei	\N	\N	2024-08-02 15:09:07.187413+03	\N
427	97	Thange	\N	\N	2024-08-02 15:09:07.187413+03	\N
428	97	Ivingoni/Nzambani	\N	\N	2024-08-02 15:09:07.187413+03	\N
429	98	Wanjohi	\N	\N	2024-08-02 15:09:07.187413+03	\N
430	98	Kipipiri	\N	\N	2024-08-02 15:09:07.187413+03	\N
431	98	Geta	\N	\N	2024-08-02 15:09:07.187413+03	\N
432	98	Githioro	\N	\N	2024-08-02 15:09:07.187413+03	\N
433	99	Mahiga	\N	\N	2024-08-02 15:09:07.187413+03	\N
434	99	Iria-Ini	\N	\N	2024-08-02 15:09:07.187413+03	\N
435	99	Chinga	\N	\N	2024-08-02 15:09:07.187413+03	\N
436	99	Karima	\N	\N	2024-08-02 15:09:07.187413+03	\N
437	100	Mweiga	\N	\N	2024-08-02 15:09:07.187413+03	\N
438	100	Naromoru Kiamathaga	\N	\N	2024-08-02 15:09:07.187413+03	\N
439	100	Mwiyogo/Endarasha	\N	\N	2024-08-02 15:09:07.187413+03	\N
440	100	Mugunda	\N	\N	2024-08-02 15:09:07.187413+03	\N
441	100	Gatarakwa	\N	\N	2024-08-02 15:09:07.187413+03	\N
442	100	Thegu River	\N	\N	2024-08-02 15:09:07.187413+03	\N
443	100	Kabaru	\N	\N	2024-08-02 15:09:07.187413+03	\N
444	100	Gakawa	\N	\N	2024-08-02 15:09:07.187413+03	\N
445	101	Kasikeu	\N	\N	2024-08-02 15:09:07.187413+03	\N
446	101	Mukaa	\N	\N	2024-08-02 15:09:07.187413+03	\N
447	101	Kiima Kiu/Kalanzoni	\N	\N	2024-08-02 15:09:07.187413+03	\N
448	102	Gikondi	\N	\N	2024-08-02 15:09:07.187413+03	\N
449	102	Rugi	\N	\N	2024-08-02 15:09:07.187413+03	\N
450	103	Ndalani	\N	\N	2024-08-02 15:09:07.187413+03	\N
451	103	Matuu	\N	\N	2024-08-02 15:09:07.187413+03	\N
452	103	Kithimani	\N	\N	2024-08-02 15:09:07.187413+03	\N
453	103	Ikombe	\N	\N	2024-08-02 15:09:07.187413+03	\N
454	103	Katangi	\N	\N	2024-08-02 15:09:07.187413+03	\N
455	104	Athi River	\N	\N	2024-08-02 15:09:07.187413+03	\N
456	104	Kinanie	\N	\N	2024-08-02 15:09:07.187413+03	\N
457	104	Muthwani	\N	\N	2024-08-02 15:09:07.187413+03	\N
458	104	Syokimau/Mulolongo	\N	\N	2024-08-02 15:09:07.187413+03	\N
459	84	Mutha	\N	\N	2024-08-02 15:09:07.187413+03	\N
460	84	Ikutha	\N	\N	2024-08-02 15:09:07.187413+03	\N
461	84	Kanziko	\N	\N	2024-08-02 15:09:07.187413+03	\N
462	84	Athi	\N	\N	2024-08-02 15:09:07.187413+03	\N
463	105	Wote	\N	\N	2024-08-02 15:09:07.187413+03	\N
464	105	Muvau/Kikuumini	\N	\N	2024-08-02 15:09:07.187413+03	\N
465	105	Mavindini	\N	\N	2024-08-02 15:09:07.187413+03	\N
466	105	Kitise/Kithuki	\N	\N	2024-08-02 15:09:07.187413+03	\N
467	105	Kathonzweni	\N	\N	2024-08-02 15:09:07.187413+03	\N
468	105	Nzaui/Kilili/Kalamba	\N	\N	2024-08-02 15:09:07.187413+03	\N
469	106	Leshau Pondo	\N	\N	2024-08-02 15:09:07.187413+03	\N
470	106	Kiriita	\N	\N	2024-08-02 15:09:07.187413+03	\N
471	106	Shamata	\N	\N	2024-08-02 15:09:07.187413+03	\N
472	107	Mitaboni	\N	\N	2024-08-02 15:09:07.187413+03	\N
473	107	Kathiani Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
474	107	Upper Kaewa/Iveti	\N	\N	2024-08-02 15:09:07.187413+03	\N
475	107	Lower Kaewa/Kaani	\N	\N	2024-08-02 15:09:07.187413+03	\N
476	108	Tala	\N	\N	2024-08-02 15:09:07.187413+03	\N
477	108	Matungulu North	\N	\N	2024-08-02 15:09:07.187413+03	\N
478	108	Matungulu East	\N	\N	2024-08-02 15:09:07.187413+03	\N
479	108	Matungulu West	\N	\N	2024-08-02 15:09:07.187413+03	\N
480	108	Kyeleni	\N	\N	2024-08-02 15:09:07.187413+03	\N
481	109	Gathanji	\N	\N	2024-08-02 15:09:07.187413+03	\N
482	109	Gatimu	\N	\N	2024-08-02 15:09:07.187413+03	\N
483	109	Weru	\N	\N	2024-08-02 15:09:07.187413+03	\N
484	109	Charagita	\N	\N	2024-08-02 15:09:07.187413+03	\N
485	110	Ruguru	\N	\N	2024-08-02 15:09:07.187413+03	\N
486	110	Magutu	\N	\N	2024-08-02 15:09:07.187413+03	\N
487	110	Iriaini	\N	\N	2024-08-02 15:09:07.187413+03	\N
488	110	Konyu	\N	\N	2024-08-02 15:09:07.187413+03	\N
489	110	Kirimukuyu	\N	\N	2024-08-02 15:09:07.187413+03	\N
490	110	Karatina Town	\N	\N	2024-08-02 15:09:07.187413+03	\N
491	111	Kangundo North	\N	\N	2024-08-02 15:09:07.187413+03	\N
492	111	Kangundo Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
493	111	Kangundo East	\N	\N	2024-08-02 15:09:07.187413+03	\N
494	111	Kangundo West	\N	\N	2024-08-02 15:09:07.187413+03	\N
495	112	Mbiuni	\N	\N	2024-08-02 15:09:07.187413+03	\N
496	112	Makutano/ Mwala	\N	\N	2024-08-02 15:09:07.187413+03	\N
497	112	Masii	\N	\N	2024-08-02 15:09:07.187413+03	\N
498	112	Muthetheni	\N	\N	2024-08-02 15:09:07.187413+03	\N
499	112	Wamunyu	\N	\N	2024-08-02 15:09:07.187413+03	\N
500	112	Kibauni	\N	\N	2024-08-02 15:09:07.187413+03	\N
501	113	Makindu	\N	\N	2024-08-02 15:09:07.187413+03	\N
502	113	Nguumo	\N	\N	2024-08-02 15:09:07.187413+03	\N
503	113	Kikumbulyu North	\N	\N	2024-08-02 15:09:07.187413+03	\N
504	113	Kikumbulyu South	\N	\N	2024-08-02 15:09:07.187413+03	\N
505	113	Nguu/Masumba	\N	\N	2024-08-02 15:09:07.187413+03	\N
506	113	Emali/Mulala	\N	\N	2024-08-02 15:09:07.187413+03	\N
507	114	Karau	\N	\N	2024-08-02 15:09:07.187413+03	\N
508	114	Kanjuiri Ridge	\N	\N	2024-08-02 15:09:07.187413+03	\N
509	114	Mirangine	\N	\N	2024-08-02 15:09:07.187413+03	\N
510	114	Kaimbaga	\N	\N	2024-08-02 15:09:07.187413+03	\N
511	114	Rurii	\N	\N	2024-08-02 15:09:07.187413+03	\N
512	115	Ukia	\N	\N	2024-08-02 15:09:07.187413+03	\N
513	115	Kee	\N	\N	2024-08-02 15:09:07.187413+03	\N
514	115	Kilungu	\N	\N	2024-08-02 15:09:07.187413+03	\N
515	115	Ilima	\N	\N	2024-08-02 15:09:07.187413+03	\N
516	116	Kalama	\N	\N	2024-08-02 15:09:07.187413+03	\N
517	116	Mua	\N	\N	2024-08-02 15:09:07.187413+03	\N
518	116	Mutituni	\N	\N	2024-08-02 15:09:07.187413+03	\N
519	116	Machakos Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
520	116	Mumbuni North	\N	\N	2024-08-02 15:09:07.187413+03	\N
521	116	Muvuti/Kiima-Kimwe	\N	\N	2024-08-02 15:09:07.187413+03	\N
522	116	Kola	\N	\N	2024-08-02 15:09:07.187413+03	\N
523	117	Kivaa	\N	\N	2024-08-02 15:09:07.187413+03	\N
524	117	Masinga Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
525	117	Ekalakala	\N	\N	2024-08-02 15:09:07.187413+03	\N
526	117	Muthesya	\N	\N	2024-08-02 15:09:07.187413+03	\N
527	117	Ndithini	\N	\N	2024-08-02 15:09:07.187413+03	\N
528	21	Ngararia	\N	\N	2024-08-02 15:09:07.187413+03	\N
529	118	Bibirioni	\N	\N	2024-08-02 15:09:07.187413+03	\N
530	118	Limuru Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
531	118	Ndeiya	\N	\N	2024-08-02 15:09:07.187413+03	\N
532	118	Limuru East	\N	\N	2024-08-02 15:09:07.187413+03	\N
533	118	Ngecha Tigoni	\N	\N	2024-08-02 15:09:07.187413+03	\N
534	119	Gitaru	\N	\N	2024-08-02 15:09:07.187413+03	\N
535	119	Muguga	\N	\N	2024-08-02 15:09:07.187413+03	\N
536	119	Nyadhuna	\N	\N	2024-08-02 15:09:07.187413+03	\N
537	119	Kabete	\N	\N	2024-08-02 15:09:07.187413+03	\N
538	119	Uthiru	\N	\N	2024-08-02 15:09:07.187413+03	\N
539	23	Wangu	\N	\N	2024-08-02 15:09:07.187413+03	\N
540	23	Mugoiri	\N	\N	2024-08-02 15:09:07.187413+03	\N
541	23	Mbiri	\N	\N	2024-08-02 15:09:07.187413+03	\N
542	23	Murarandia	\N	\N	2024-08-02 15:09:07.187413+03	\N
543	120	Mukure	\N	\N	2024-08-02 15:09:07.187413+03	\N
544	120	Kiine	\N	\N	2024-08-02 15:09:07.187413+03	\N
545	120	Kariti	\N	\N	2024-08-02 15:09:07.187413+03	\N
546	102	Mukurwe-Ini West	\N	\N	2024-08-02 15:09:07.187413+03	\N
547	102	Mukurwe-Ini Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
548	26	Gitothua	\N	\N	2024-08-02 15:09:07.187413+03	\N
549	26	Biashara	\N	\N	2024-08-02 15:09:07.187413+03	\N
550	26	Gatongora	\N	\N	2024-08-02 15:09:07.187413+03	\N
551	26	Kahawa Sukari	\N	\N	2024-08-02 15:09:07.187413+03	\N
552	26	Kahawa Wendani	\N	\N	2024-08-02 15:09:07.187413+03	\N
553	26	Kiuu	\N	\N	2024-08-02 15:09:07.187413+03	\N
554	121	Ithanga	\N	\N	2024-08-02 15:09:07.187413+03	\N
555	121	Kakuzi/Mitubiri	\N	\N	2024-08-02 15:09:07.187413+03	\N
556	121	Mugumo-Ini	\N	\N	2024-08-02 15:09:07.187413+03	\N
557	121	Kihumbu-Ini	\N	\N	2024-08-02 15:09:07.187413+03	\N
558	121	Gatanga	\N	\N	2024-08-02 15:09:07.187413+03	\N
559	121	Kariara	\N	\N	2024-08-02 15:09:07.187413+03	\N
560	122	Tinganga	\N	\N	2024-08-02 15:09:07.187413+03	\N
561	122	Ndumberi	\N	\N	2024-08-02 15:09:07.187413+03	\N
562	122	Riabai	\N	\N	2024-08-02 15:09:07.187413+03	\N
563	123	Gitugi	\N	\N	2024-08-02 15:09:07.187413+03	\N
564	123	Kiru	\N	\N	2024-08-02 15:09:07.187413+03	\N
565	123	Kamacharia	\N	\N	2024-08-02 15:09:07.187413+03	\N
566	124	Gituamba	\N	\N	2024-08-02 15:09:07.187413+03	\N
567	124	Githobokoni	\N	\N	2024-08-02 15:09:07.187413+03	\N
568	124	Chania	\N	\N	2024-08-02 15:09:07.187413+03	\N
569	124	Mangu	\N	\N	2024-08-02 15:09:07.187413+03	\N
570	125	Karai	\N	\N	2024-08-02 15:09:07.187413+03	\N
571	125	Nachu	\N	\N	2024-08-02 15:09:07.187413+03	\N
572	125	Sigona	\N	\N	2024-08-02 15:09:07.187413+03	\N
573	125	Kikuyu	\N	\N	2024-08-02 15:09:07.187413+03	\N
574	125	Kinoo	\N	\N	2024-08-02 15:09:07.187413+03	\N
575	126	Kabare	\N	\N	2024-08-02 15:09:07.187413+03	\N
576	126	Baragwi	\N	\N	2024-08-02 15:09:07.187413+03	\N
577	126	Njukiini	\N	\N	2024-08-02 15:09:07.187413+03	\N
578	126	Ngariama	\N	\N	2024-08-02 15:09:07.187413+03	\N
579	126	Karumandi	\N	\N	2024-08-02 15:09:07.187413+03	\N
580	127	Kiganjo/Mathari	\N	\N	2024-08-02 15:09:07.187413+03	\N
581	127	Rware	\N	\N	2024-08-02 15:09:07.187413+03	\N
582	127	Gatitu/Muruguru	\N	\N	2024-08-02 15:09:07.187413+03	\N
583	127	Ruringu	\N	\N	2024-08-02 15:09:07.187413+03	\N
584	127	Kamakwa/Mukaro	\N	\N	2024-08-02 15:09:07.187413+03	\N
585	128	Kanyenyaini	\N	\N	2024-08-02 15:09:07.187413+03	\N
586	128	Muguru	\N	\N	2024-08-02 15:09:07.187413+03	\N
587	128	Rwathia	\N	\N	2024-08-02 15:09:07.187413+03	\N
588	129	Kimorori/Wempa	\N	\N	2024-08-02 15:09:07.187413+03	\N
589	129	Makuyu	\N	\N	2024-08-02 15:09:07.187413+03	\N
590	129	Kambiti	\N	\N	2024-08-02 15:09:07.187413+03	\N
591	129	Kamahuha	\N	\N	2024-08-02 15:09:07.187413+03	\N
592	129	Ichagaki	\N	\N	2024-08-02 15:09:07.187413+03	\N
593	130	Mutira	\N	\N	2024-08-02 15:09:07.187413+03	\N
594	130	Kanyeki-Ini	\N	\N	2024-08-02 15:09:07.187413+03	\N
595	130	Kerugoya	\N	\N	2024-08-02 15:09:07.187413+03	\N
596	130	Inoi	\N	\N	2024-08-02 15:09:07.187413+03	\N
597	131	Kiamwangi	\N	\N	2024-08-02 15:09:07.187413+03	\N
598	131	Kiganjo	\N	\N	2024-08-02 15:09:07.187413+03	\N
599	131	Ndarugu	\N	\N	2024-08-02 15:09:07.187413+03	\N
600	131	Ngenda	\N	\N	2024-08-02 15:09:07.187413+03	\N
601	132	Mutithi	\N	\N	2024-08-02 15:09:07.187413+03	\N
602	132	Kangai	\N	\N	2024-08-02 15:09:07.187413+03	\N
603	132	Thiba	\N	\N	2024-08-02 15:09:07.187413+03	\N
604	132	Wamumu	\N	\N	2024-08-02 15:09:07.187413+03	\N
605	132	Nyangati	\N	\N	2024-08-02 15:09:07.187413+03	\N
606	132	Murinduko	\N	\N	2024-08-02 15:09:07.187413+03	\N
607	132	Gathigiriri	\N	\N	2024-08-02 15:09:07.187413+03	\N
608	132	Tebere	\N	\N	2024-08-02 15:09:07.187413+03	\N
609	133	Kinale	\N	\N	2024-08-02 15:09:07.187413+03	\N
610	133	Kijabe	\N	\N	2024-08-02 15:09:07.187413+03	\N
611	133	Nyanduma	\N	\N	2024-08-02 15:09:07.187413+03	\N
612	133	Kamburu	\N	\N	2024-08-02 15:09:07.187413+03	\N
613	133	Lari/Kirenga	\N	\N	2024-08-02 15:09:07.187413+03	\N
614	134	Kahumbu	\N	\N	2024-08-02 15:09:07.187413+03	\N
615	134	Muthithi	\N	\N	2024-08-02 15:09:07.187413+03	\N
616	134	Kigumo	\N	\N	2024-08-02 15:09:07.187413+03	\N
617	134	Kangari	\N	\N	2024-08-02 15:09:07.187413+03	\N
618	134	Kinyona	\N	\N	2024-08-02 15:09:07.187413+03	\N
619	135	Murera	\N	\N	2024-08-02 15:09:07.187413+03	\N
620	135	Theta	\N	\N	2024-08-02 15:09:07.187413+03	\N
621	135	Juja	\N	\N	2024-08-02 15:09:07.187413+03	\N
622	135	Witeithie	\N	\N	2024-08-02 15:09:07.187413+03	\N
623	135	Kalimoni	\N	\N	2024-08-02 15:09:07.187413+03	\N
624	136	Kaeris	\N	\N	2024-08-02 15:09:07.187413+03	\N
625	136	Lake Zone	\N	\N	2024-08-02 15:09:07.187413+03	\N
626	136	Lapur	\N	\N	2024-08-02 15:09:07.187413+03	\N
627	136	Kaaleng/Kaikor	\N	\N	2024-08-02 15:09:07.187413+03	\N
628	137	Cianda	\N	\N	2024-08-02 15:09:07.187413+03	\N
629	137	Karuri	\N	\N	2024-08-02 15:09:07.187413+03	\N
630	137	Ndenderu	\N	\N	2024-08-02 15:09:07.187413+03	\N
631	137	Muchatha	\N	\N	2024-08-02 15:09:07.187413+03	\N
632	137	Kihara	\N	\N	2024-08-02 15:09:07.187413+03	\N
633	138	Kamenu	\N	\N	2024-08-02 15:09:07.187413+03	\N
634	138	Hospital	\N	\N	2024-08-02 15:09:07.187413+03	\N
635	138	Gatuanyaga	\N	\N	2024-08-02 15:09:07.187413+03	\N
636	138	Ngoliba	\N	\N	2024-08-02 15:09:07.187413+03	\N
637	139	Githunguri	\N	\N	2024-08-02 15:09:07.187413+03	\N
638	139	Githiga	\N	\N	2024-08-02 15:09:07.187413+03	\N
639	139	Ikinu	\N	\N	2024-08-02 15:09:07.187413+03	\N
640	139	Ngewa	\N	\N	2024-08-02 15:09:07.187413+03	\N
641	139	Komothai	\N	\N	2024-08-02 15:09:07.187413+03	\N
642	16	Ngenyilel	\N	\N	2024-08-02 15:09:07.187413+03	\N
643	16	Tapsagoi	\N	\N	2024-08-02 15:09:07.187413+03	\N
644	16	Kamagut	\N	\N	2024-08-02 15:09:07.187413+03	\N
645	16	Kiplombe	\N	\N	2024-08-02 15:09:07.187413+03	\N
646	16	Kapsaos	\N	\N	2024-08-02 15:09:07.187413+03	\N
647	140	Kapomboi	\N	\N	2024-08-02 15:09:07.187413+03	\N
648	140	Kwanza	\N	\N	2024-08-02 15:09:07.187413+03	\N
649	140	Keiyo	\N	\N	2024-08-02 15:09:07.187413+03	\N
650	140	Bidii	\N	\N	2024-08-02 15:09:07.187413+03	\N
651	141	Kiminini	\N	\N	2024-08-02 15:09:07.187413+03	\N
652	141	Waitaluk	\N	\N	2024-08-02 15:09:07.187413+03	\N
653	141	Sirende	\N	\N	2024-08-02 15:09:07.187413+03	\N
654	141	Sikhendu	\N	\N	2024-08-02 15:09:07.187413+03	\N
655	141	Nabiswa	\N	\N	2024-08-02 15:09:07.187413+03	\N
656	142	Kapyego	\N	\N	2024-08-02 15:09:07.187413+03	\N
657	142	Sambirir	\N	\N	2024-08-02 15:09:07.187413+03	\N
658	142	Endo	\N	\N	2024-08-02 15:09:07.187413+03	\N
659	142	Embobut / Embulot	\N	\N	2024-08-02 15:09:07.187413+03	\N
660	25	Mois Bridge	\N	\N	2024-08-02 15:09:07.187413+03	\N
661	25	Kapkures	\N	\N	2024-08-02 15:09:07.187413+03	\N
662	25	Ziwa	\N	\N	2024-08-02 15:09:07.187413+03	\N
663	25	Segero/Barsombe	\N	\N	2024-08-02 15:09:07.187413+03	\N
664	25	Kipsomba	\N	\N	2024-08-02 15:09:07.187413+03	\N
665	25	Soy	\N	\N	2024-08-02 15:09:07.187413+03	\N
666	143	Chepchoina	\N	\N	2024-08-02 15:09:07.187413+03	\N
667	143	Endebess	\N	\N	2024-08-02 15:09:07.187413+03	\N
668	143	Matumbei	\N	\N	2024-08-02 15:09:07.187413+03	\N
669	144	Kapsoya	\N	\N	2024-08-02 15:09:07.187413+03	\N
670	144	Kaptagat	\N	\N	2024-08-02 15:09:07.187413+03	\N
671	144	Ainabkoi/Olare	\N	\N	2024-08-02 15:09:07.187413+03	\N
672	145	Kaputir	\N	\N	2024-08-02 15:09:07.187413+03	\N
673	145	Katilu	\N	\N	2024-08-02 15:09:07.187413+03	\N
674	145	Lobokat	\N	\N	2024-08-02 15:09:07.187413+03	\N
675	145	Kalapata	\N	\N	2024-08-02 15:09:07.187413+03	\N
676	145	Lokichar	\N	\N	2024-08-02 15:09:07.187413+03	\N
677	146	Sekerr	\N	\N	2024-08-02 15:09:07.187413+03	\N
678	146	Masool	\N	\N	2024-08-02 15:09:07.187413+03	\N
679	146	Lomut	\N	\N	2024-08-02 15:09:07.187413+03	\N
680	146	Weiwei	\N	\N	2024-08-02 15:09:07.187413+03	\N
681	147	Waso	\N	\N	2024-08-02 15:09:07.187413+03	\N
682	147	Wamba West	\N	\N	2024-08-02 15:09:07.187413+03	\N
683	147	Wamba East	\N	\N	2024-08-02 15:09:07.187413+03	\N
684	147	Wamba North	\N	\N	2024-08-02 15:09:07.187413+03	\N
685	148	Suam	\N	\N	2024-08-02 15:09:07.187413+03	\N
686	148	Kodich	\N	\N	2024-08-02 15:09:07.187413+03	\N
687	148	Kapckok	\N	\N	2024-08-02 15:09:07.187413+03	\N
688	148	Kasei	\N	\N	2024-08-02 15:09:07.187413+03	\N
689	148	Kiwawa	\N	\N	2024-08-02 15:09:07.187413+03	\N
690	148	Alale	\N	\N	2024-08-02 15:09:07.187413+03	\N
691	149	Riwo	\N	\N	2024-08-02 15:09:07.187413+03	\N
692	149	Kapenguria	\N	\N	2024-08-02 15:09:07.187413+03	\N
693	149	Mnagei	\N	\N	2024-08-02 15:09:07.187413+03	\N
694	149	Siyoi	\N	\N	2024-08-02 15:09:07.187413+03	\N
695	149	Endugh	\N	\N	2024-08-02 15:09:07.187413+03	\N
696	149	Sook	\N	\N	2024-08-02 15:09:07.187413+03	\N
697	150	Kakuma	\N	\N	2024-08-02 15:09:07.187413+03	\N
698	150	Lopur	\N	\N	2024-08-02 15:09:07.187413+03	\N
699	150	Letea	\N	\N	2024-08-02 15:09:07.187413+03	\N
700	150	Songot	\N	\N	2024-08-02 15:09:07.187413+03	\N
701	150	Kalobeyei	\N	\N	2024-08-02 15:09:07.187413+03	\N
702	150	Lokichoggio	\N	\N	2024-08-02 15:09:07.187413+03	\N
703	150	Nanaam	\N	\N	2024-08-02 15:09:07.187413+03	\N
704	151	El-Barta	\N	\N	2024-08-02 15:09:07.187413+03	\N
705	151	Nachola	\N	\N	2024-08-02 15:09:07.187413+03	\N
706	151	Ndoto	\N	\N	2024-08-02 15:09:07.187413+03	\N
707	151	Nyiro	\N	\N	2024-08-02 15:09:07.187413+03	\N
708	151	Angata Nanyokie	\N	\N	2024-08-02 15:09:07.187413+03	\N
709	151	Baawa	\N	\N	2024-08-02 15:09:07.187413+03	\N
710	152	Sinyerere	\N	\N	2024-08-02 15:09:07.187413+03	\N
711	152	Makutano	\N	\N	2024-08-02 15:09:07.187413+03	\N
712	152	Kaplamai	\N	\N	2024-08-02 15:09:07.187413+03	\N
713	152	Motosiet	\N	\N	2024-08-02 15:09:07.187413+03	\N
714	152	Cherangany/Suwerwa	\N	\N	2024-08-02 15:09:07.187413+03	\N
715	152	Chepsiro/Kiptoror	\N	\N	2024-08-02 15:09:07.187413+03	\N
716	152	Sitatunga	\N	\N	2024-08-02 15:09:07.187413+03	\N
717	153	Kotaruk/Lobei	\N	\N	2024-08-02 15:09:07.187413+03	\N
718	153	Turkwel	\N	\N	2024-08-02 15:09:07.187413+03	\N
719	153	Loima	\N	\N	2024-08-02 15:09:07.187413+03	\N
720	153	Lokiriama/Lorengippi	\N	\N	2024-08-02 15:09:07.187413+03	\N
721	154	Simat/Kapseret	\N	\N	2024-08-02 15:09:07.187413+03	\N
722	154	Kipkenyo	\N	\N	2024-08-02 15:09:07.187413+03	\N
723	154	Ngeria	\N	\N	2024-08-02 15:09:07.187413+03	\N
724	154	Megun	\N	\N	2024-08-02 15:09:07.187413+03	\N
725	154	Langas	\N	\N	2024-08-02 15:09:07.187413+03	\N
726	155	Chepareria	\N	\N	2024-08-02 15:09:07.187413+03	\N
727	155	Batei	\N	\N	2024-08-02 15:09:07.187413+03	\N
728	155	Lelan	\N	\N	2024-08-02 15:09:07.187413+03	\N
729	155	Tapach	\N	\N	2024-08-02 15:09:07.187413+03	\N
730	156	Kapedo/Napeitom	\N	\N	2024-08-02 15:09:07.187413+03	\N
731	156	Katilia	\N	\N	2024-08-02 15:09:07.187413+03	\N
732	156	Lokori/Kochodin	\N	\N	2024-08-02 15:09:07.187413+03	\N
733	136	Kibish	\N	\N	2024-08-02 15:09:07.187413+03	\N
734	136	Nakalale	\N	\N	2024-08-02 15:09:07.187413+03	\N
735	157	Kinyoro	\N	\N	2024-08-02 15:09:07.187413+03	\N
736	157	Matisi	\N	\N	2024-08-02 15:09:07.187413+03	\N
737	157	Tuwani	\N	\N	2024-08-02 15:09:07.187413+03	\N
738	157	Saboti	\N	\N	2024-08-02 15:09:07.187413+03	\N
739	157	Machewa	\N	\N	2024-08-02 15:09:07.187413+03	\N
740	158	Tembelio	\N	\N	2024-08-02 15:09:07.187413+03	\N
741	158	Sergoit	\N	\N	2024-08-02 15:09:07.187413+03	\N
742	158	Karuna/Meibeki	\N	\N	2024-08-02 15:09:07.187413+03	\N
743	158	Moiben	\N	\N	2024-08-02 15:09:07.187413+03	\N
744	158	Kimumu	\N	\N	2024-08-02 15:09:07.187413+03	\N
745	159	Subukia	\N	\N	2024-08-02 15:09:07.187413+03	\N
746	160	Racecourse	\N	\N	2024-08-02 15:09:07.187413+03	\N
747	160	Cheptiret/Kipchamo	\N	\N	2024-08-02 15:09:07.187413+03	\N
748	160	Tulwet/Chuiyat	\N	\N	2024-08-02 15:09:07.187413+03	\N
749	160	Tarakwa	\N	\N	2024-08-02 15:09:07.187413+03	\N
750	161	Kerio Delta	\N	\N	2024-08-02 15:09:07.187413+03	\N
751	161	Kangatotha	\N	\N	2024-08-02 15:09:07.187413+03	\N
752	161	Kalokol	\N	\N	2024-08-02 15:09:07.187413+03	\N
753	161	Lodwar Township	\N	\N	2024-08-02 15:09:07.187413+03	\N
754	161	Kanamkemer	\N	\N	2024-08-02 15:09:07.187413+03	\N
755	162	Sengwer	\N	\N	2024-08-02 15:09:07.187413+03	\N
756	19	Chemundu/Kapngetuny	\N	\N	2024-08-02 15:09:07.187413+03	\N
757	19	Kosirai	\N	\N	2024-08-02 15:09:07.187413+03	\N
758	19	Lelmokwo/Ngechek	\N	\N	2024-08-02 15:09:07.187413+03	\N
759	19	Kaptel/Kamoiywo	\N	\N	2024-08-02 15:09:07.187413+03	\N
760	163	Songhor/Soba	\N	\N	2024-08-02 15:09:07.187413+03	\N
761	163	Tindiret	\N	\N	2024-08-02 15:09:07.187413+03	\N
762	163	Chemelil/Chemase	\N	\N	2024-08-02 15:09:07.187413+03	\N
763	163	Kapsimotwo	\N	\N	2024-08-02 15:09:07.187413+03	\N
764	164	Kiptororo	\N	\N	2024-08-02 15:09:07.187413+03	\N
765	164	Nyota	\N	\N	2024-08-02 15:09:07.187413+03	\N
766	164	Sirikwa	\N	\N	2024-08-02 15:09:07.187413+03	\N
767	164	Kamara	\N	\N	2024-08-02 15:09:07.187413+03	\N
768	165	Gilgil	\N	\N	2024-08-02 15:09:07.187413+03	\N
769	165	Elementaita	\N	\N	2024-08-02 15:09:07.187413+03	\N
770	165	Mbaruk/Eburu	\N	\N	2024-08-02 15:09:07.187413+03	\N
771	165	Malewa West	\N	\N	2024-08-02 15:09:07.187413+03	\N
772	165	Murindati	\N	\N	2024-08-02 15:09:07.187413+03	\N
773	166	Marigat	\N	\N	2024-08-02 15:09:07.187413+03	\N
774	166	Ilchamus	\N	\N	2024-08-02 15:09:07.187413+03	\N
775	166	Mochongoi	\N	\N	2024-08-02 15:09:07.187413+03	\N
776	166	Mukutani	\N	\N	2024-08-02 15:09:07.187413+03	\N
777	167	Kabwareng	\N	\N	2024-08-02 15:09:07.187413+03	\N
778	167	Terik	\N	\N	2024-08-02 15:09:07.187413+03	\N
779	167	Kemeloi-Maraba	\N	\N	2024-08-02 15:09:07.187413+03	\N
780	167	Kobujoi	\N	\N	2024-08-02 15:09:07.187413+03	\N
781	167	Kaptumo-Kaboi	\N	\N	2024-08-02 15:09:07.187413+03	\N
782	167	Koyo-Ndurio	\N	\N	2024-08-02 15:09:07.187413+03	\N
783	168	Mariashoni	\N	\N	2024-08-02 15:09:07.187413+03	\N
784	168	Elburgon	\N	\N	2024-08-02 15:09:07.187413+03	\N
785	168	Turi	\N	\N	2024-08-02 15:09:07.187413+03	\N
786	168	Molo	\N	\N	2024-08-02 15:09:07.187413+03	\N
787	169	Maunarok	\N	\N	2024-08-02 15:09:07.187413+03	\N
788	169	Mauche	\N	\N	2024-08-02 15:09:07.187413+03	\N
789	169	Kihingo	\N	\N	2024-08-02 15:09:07.187413+03	\N
790	169	Nessuit	\N	\N	2024-08-02 15:09:07.187413+03	\N
791	169	Lare	\N	\N	2024-08-02 15:09:07.187413+03	\N
792	169	Njoro	\N	\N	2024-08-02 15:09:07.187413+03	\N
793	170	Ngobit	\N	\N	2024-08-02 15:09:07.187413+03	\N
794	170	Tigithi	\N	\N	2024-08-02 15:09:07.187413+03	\N
795	170	Thingithu	\N	\N	2024-08-02 15:09:07.187413+03	\N
796	170	Nanyuki	\N	\N	2024-08-02 15:09:07.187413+03	\N
797	170	Umande	\N	\N	2024-08-02 15:09:07.187413+03	\N
798	171	Kabarnet	\N	\N	2024-08-02 15:09:07.187413+03	\N
799	171	Sacho	\N	\N	2024-08-02 15:09:07.187413+03	\N
800	171	Tenges	\N	\N	2024-08-02 15:09:07.187413+03	\N
801	171	Ewalel Chapchap	\N	\N	2024-08-02 15:09:07.187413+03	\N
802	171	Kapropita	\N	\N	2024-08-02 15:09:07.187413+03	\N
803	172	Sosian	\N	\N	2024-08-02 15:09:07.187413+03	\N
804	172	Segera	\N	\N	2024-08-02 15:09:07.187413+03	\N
805	172	Mukogondo West	\N	\N	2024-08-02 15:09:07.187413+03	\N
806	172	Mukogondo East	\N	\N	2024-08-02 15:09:07.187413+03	\N
807	173	Lembus	\N	\N	2024-08-02 15:09:07.187413+03	\N
808	173	Lembus Kwen	\N	\N	2024-08-02 15:09:07.187413+03	\N
809	173	Ravine	\N	\N	2024-08-02 15:09:07.187413+03	\N
810	173	Mumberes/Maji Mazuri	\N	\N	2024-08-02 15:09:07.187413+03	\N
811	173	Lembus/Perkerra	\N	\N	2024-08-02 15:09:07.187413+03	\N
812	173	Koibatek	\N	\N	2024-08-02 15:09:07.187413+03	\N
813	174	Tirioko	\N	\N	2024-08-02 15:09:07.187413+03	\N
814	174	Kolowa	\N	\N	2024-08-02 15:09:07.187413+03	\N
815	174	Ribkwo	\N	\N	2024-08-02 15:09:07.187413+03	\N
816	174	Silale	\N	\N	2024-08-02 15:09:07.187413+03	\N
817	174	Loiyamorock	\N	\N	2024-08-02 15:09:07.187413+03	\N
818	174	Tangulbei/Korossi	\N	\N	2024-08-02 15:09:07.187413+03	\N
819	174	Churo/Amaya	\N	\N	2024-08-02 15:09:07.187413+03	\N
820	175	Emsoo	\N	\N	2024-08-02 15:09:07.187413+03	\N
821	175	Kamariny	\N	\N	2024-08-02 15:09:07.187413+03	\N
822	175	Kapchemutwa	\N	\N	2024-08-02 15:09:07.187413+03	\N
823	175	Tambach	\N	\N	2024-08-02 15:09:07.187413+03	\N
824	176	Nandi Hills	\N	\N	2024-08-02 15:09:07.187413+03	\N
825	176	Chepkunyuk	\N	\N	2024-08-02 15:09:07.187413+03	\N
826	176	Ollessos	\N	\N	2024-08-02 15:09:07.187413+03	\N
827	176	Kapchorua	\N	\N	2024-08-02 15:09:07.187413+03	\N
828	177	Mogotio	\N	\N	2024-08-02 15:09:07.187413+03	\N
829	177	Emining	\N	\N	2024-08-02 15:09:07.187413+03	\N
830	177	Kisanana	\N	\N	2024-08-02 15:09:07.187413+03	\N
831	178	Barwessa	\N	\N	2024-08-02 15:09:07.187413+03	\N
832	178	Kabartonjo	\N	\N	2024-08-02 15:09:07.187413+03	\N
833	178	Saimo/Kipsaraman	\N	\N	2024-08-02 15:09:07.187413+03	\N
834	178	Saimo/Soi	\N	\N	2024-08-02 15:09:07.187413+03	\N
835	178	Bartabwa	\N	\N	2024-08-02 15:09:07.187413+03	\N
836	179	Hells Gate	\N	\N	2024-08-02 15:09:07.187413+03	\N
837	179	Lakeview	\N	\N	2024-08-02 15:09:07.187413+03	\N
838	179	Maai-Mahiu	\N	\N	2024-08-02 15:09:07.187413+03	\N
839	179	Maiella	\N	\N	2024-08-02 15:09:07.187413+03	\N
840	179	Olkaria	\N	\N	2024-08-02 15:09:07.187413+03	\N
841	179	Naivasha East	\N	\N	2024-08-02 15:09:07.187413+03	\N
842	179	Viwandani	\N	\N	2024-08-02 15:09:07.187413+03	\N
843	180	Olmoran	\N	\N	2024-08-02 15:09:07.187413+03	\N
844	180	Rumuruti Township	\N	\N	2024-08-02 15:09:07.187413+03	\N
845	180	Kinamba	\N	\N	2024-08-02 15:09:07.187413+03	\N
846	180	Marmanet	\N	\N	2024-08-02 15:09:07.187413+03	\N
847	180	Igwamiti	\N	\N	2024-08-02 15:09:07.187413+03	\N
848	180	Salama	\N	\N	2024-08-02 15:09:07.187413+03	\N
849	181	Chepterwai	\N	\N	2024-08-02 15:09:07.187413+03	\N
850	181	Kipkaren	\N	\N	2024-08-02 15:09:07.187413+03	\N
851	181	Kurgung/Surungai	\N	\N	2024-08-02 15:09:07.187413+03	\N
852	181	Kabiyet	\N	\N	2024-08-02 15:09:07.187413+03	\N
853	181	Ndalat	\N	\N	2024-08-02 15:09:07.187413+03	\N
854	181	Kabisaga	\N	\N	2024-08-02 15:09:07.187413+03	\N
855	181	Sangalo/Kebulonik	\N	\N	2024-08-02 15:09:07.187413+03	\N
856	182	Amalo	\N	\N	2024-08-02 15:09:07.187413+03	\N
857	182	Keringet	\N	\N	2024-08-02 15:09:07.187413+03	\N
858	182	Kiptagich	\N	\N	2024-08-02 15:09:07.187413+03	\N
859	182	Tinet	\N	\N	2024-08-02 15:09:07.187413+03	\N
860	183	Kaptarakwa	\N	\N	2024-08-02 15:09:07.187413+03	\N
861	183	Chepkorio	\N	\N	2024-08-02 15:09:07.187413+03	\N
862	183	Soy North	\N	\N	2024-08-02 15:09:07.187413+03	\N
863	183	Soy South	\N	\N	2024-08-02 15:09:07.187413+03	\N
864	183	Kabiemit	\N	\N	2024-08-02 15:09:07.187413+03	\N
865	183	Metkei	\N	\N	2024-08-02 15:09:07.187413+03	\N
866	162	Cherangany/Chebororwa	\N	\N	2024-08-02 15:09:07.187413+03	\N
867	162	Moiben/Kuserwo	\N	\N	2024-08-02 15:09:07.187413+03	\N
868	162	Kapsowar	\N	\N	2024-08-02 15:09:07.187413+03	\N
869	162	Arror	\N	\N	2024-08-02 15:09:07.187413+03	\N
870	20	Olpusimoru	\N	\N	2024-08-02 15:09:07.187413+03	\N
871	20	Olokurto	\N	\N	2024-08-02 15:09:07.187413+03	\N
872	20	Narok Town	\N	\N	2024-08-02 15:09:07.187413+03	\N
873	20	Nkareta	\N	\N	2024-08-02 15:09:07.187413+03	\N
874	184	Kunyak	\N	\N	2024-08-02 15:09:07.187413+03	\N
875	184	Kamasian	\N	\N	2024-08-02 15:09:07.187413+03	\N
876	184	Kipkelion	\N	\N	2024-08-02 15:09:07.187413+03	\N
877	184	Chilchila	\N	\N	2024-08-02 15:09:07.187413+03	\N
878	185	Menengai West	\N	\N	2024-08-02 15:09:07.187413+03	\N
879	185	Soin	\N	\N	2024-08-02 15:09:07.187413+03	\N
880	185	Visoi	\N	\N	2024-08-02 15:09:07.187413+03	\N
881	185	Mosop	\N	\N	2024-08-02 15:09:07.187413+03	\N
882	185	Solai	\N	\N	2024-08-02 15:09:07.187413+03	\N
883	186	Barut	\N	\N	2024-08-02 15:09:07.187413+03	\N
884	186	London	\N	\N	2024-08-02 15:09:07.187413+03	\N
885	186	Kaptembwo	\N	\N	2024-08-02 15:09:07.187413+03	\N
886	186	Rhoda	\N	\N	2024-08-02 15:09:07.187413+03	\N
887	186	Shaabab	\N	\N	2024-08-02 15:09:07.187413+03	\N
888	187	Kongasis	\N	\N	2024-08-02 15:09:07.187413+03	\N
889	187	Nyangores	\N	\N	2024-08-02 15:09:07.187413+03	\N
890	187	Sigor	\N	\N	2024-08-02 15:09:07.187413+03	\N
891	187	Chebunyo	\N	\N	2024-08-02 15:09:07.187413+03	\N
892	187	Siongiroi	\N	\N	2024-08-02 15:09:07.187413+03	\N
893	188	Purko	\N	\N	2024-08-02 15:09:07.187413+03	\N
894	188	Dalalekutuk	\N	\N	2024-08-02 15:09:07.187413+03	\N
895	188	Matapato North	\N	\N	2024-08-02 15:09:07.187413+03	\N
896	188	Matapato South	\N	\N	2024-08-02 15:09:07.187413+03	\N
897	189	Ilkerin	\N	\N	2024-08-02 15:09:07.187413+03	\N
898	189	Ololmasani	\N	\N	2024-08-02 15:09:07.187413+03	\N
899	189	Mogondo	\N	\N	2024-08-02 15:09:07.187413+03	\N
900	189	Kapsasian	\N	\N	2024-08-02 15:09:07.187413+03	\N
901	190	Kivumbini	\N	\N	2024-08-02 15:09:07.187413+03	\N
902	190	Flamingo	\N	\N	2024-08-02 15:09:07.187413+03	\N
903	190	Menengai	\N	\N	2024-08-02 15:09:07.187413+03	\N
904	190	Nakuru East	\N	\N	2024-08-02 15:09:07.187413+03	\N
905	191	Ilmotiok	\N	\N	2024-08-02 15:09:07.187413+03	\N
906	191	Mara	\N	\N	2024-08-02 15:09:07.187413+03	\N
907	191	Siana	\N	\N	2024-08-02 15:09:07.187413+03	\N
908	191	Naikarra	\N	\N	2024-08-02 15:09:07.187413+03	\N
909	192	Merigi	\N	\N	2024-08-02 15:09:07.187413+03	\N
910	193	Entonet/Lenkisim	\N	\N	2024-08-02 15:09:07.187413+03	\N
911	193	Mbirikani/Eselenkei	\N	\N	2024-08-02 15:09:07.187413+03	\N
912	193	Kuku	\N	\N	2024-08-02 15:09:07.187413+03	\N
913	193	Rombo	\N	\N	2024-08-02 15:09:07.187413+03	\N
914	193	Kimana	\N	\N	2024-08-02 15:09:07.187413+03	\N
915	194	Olkeri	\N	\N	2024-08-02 15:09:07.187413+03	\N
916	194	Ongata Rongai	\N	\N	2024-08-02 15:09:07.187413+03	\N
917	194	Nkaimurunya	\N	\N	2024-08-02 15:09:07.187413+03	\N
918	194	Oloolua	\N	\N	2024-08-02 15:09:07.187413+03	\N
919	194	Ngong	\N	\N	2024-08-02 15:09:07.187413+03	\N
920	195	Iloodokilani	\N	\N	2024-08-02 15:09:07.187413+03	\N
921	195	Magadi	\N	\N	2024-08-02 15:09:07.187413+03	\N
922	195	Ewuaso Oonkidongi	\N	\N	2024-08-02 15:09:07.187413+03	\N
923	196	Majimoto/Naroosura	\N	\N	2024-08-02 15:09:07.187413+03	\N
924	196	Ololulunga	\N	\N	2024-08-02 15:09:07.187413+03	\N
925	196	Melelo	\N	\N	2024-08-02 15:09:07.187413+03	\N
926	196	Loita	\N	\N	2024-08-02 15:09:07.187413+03	\N
927	196	Sogoo	\N	\N	2024-08-02 15:09:07.187413+03	\N
928	196	Sagamian	\N	\N	2024-08-02 15:09:07.187413+03	\N
929	197	Dundori	\N	\N	2024-08-02 15:09:07.187413+03	\N
930	197	Kabatini	\N	\N	2024-08-02 15:09:07.187413+03	\N
931	197	Kiamaina	\N	\N	2024-08-02 15:09:07.187413+03	\N
932	197	Lanet/Umoja	\N	\N	2024-08-02 15:09:07.187413+03	\N
933	197	Bahati	\N	\N	2024-08-02 15:09:07.187413+03	\N
934	198	Kisiara	\N	\N	2024-08-02 15:09:07.187413+03	\N
935	198	Tebesonik	\N	\N	2024-08-02 15:09:07.187413+03	\N
936	198	Cheboin	\N	\N	2024-08-02 15:09:07.187413+03	\N
937	198	Chemosot	\N	\N	2024-08-02 15:09:07.187413+03	\N
938	198	Litein	\N	\N	2024-08-02 15:09:07.187413+03	\N
939	198	Cheplanget	\N	\N	2024-08-02 15:09:07.187413+03	\N
940	198	Kapkatet	\N	\N	2024-08-02 15:09:07.187413+03	\N
941	199	Kilgoris Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
942	199	Keyian	\N	\N	2024-08-02 15:09:07.187413+03	\N
943	199	Angata Barikoi	\N	\N	2024-08-02 15:09:07.187413+03	\N
944	199	Shankoe	\N	\N	2024-08-02 15:09:07.187413+03	\N
945	199	Kimintet	\N	\N	2024-08-02 15:09:07.187413+03	\N
946	199	Lolgorian	\N	\N	2024-08-02 15:09:07.187413+03	\N
947	200	Waldai	\N	\N	2024-08-02 15:09:07.187413+03	\N
948	200	Kabianga	\N	\N	2024-08-02 15:09:07.187413+03	\N
949	200	Cheptororiet/Seretut	\N	\N	2024-08-02 15:09:07.187413+03	\N
950	200	Chaik	\N	\N	2024-08-02 15:09:07.187413+03	\N
951	200	Kapsuser	\N	\N	2024-08-02 15:09:07.187413+03	\N
952	201	Kapsoit	\N	\N	2024-08-02 15:09:07.187413+03	\N
953	201	Ainamoi	\N	\N	2024-08-02 15:09:07.187413+03	\N
954	201	Kapkugerwet	\N	\N	2024-08-02 15:09:07.187413+03	\N
955	201	Kipchebor	\N	\N	2024-08-02 15:09:07.187413+03	\N
956	201	Kipchimchim	\N	\N	2024-08-02 15:09:07.187413+03	\N
957	202	Sigowet	\N	\N	2024-08-02 15:09:07.187413+03	\N
958	202	Kaplelartet	\N	\N	2024-08-02 15:09:07.187413+03	\N
959	202	Soliat	\N	\N	2024-08-02 15:09:07.187413+03	\N
960	203	Londiani	\N	\N	2024-08-02 15:09:07.187413+03	\N
961	203	Kedowa/Kimugul	\N	\N	2024-08-02 15:09:07.187413+03	\N
962	203	Chepseon	\N	\N	2024-08-02 15:09:07.187413+03	\N
963	203	Tendeno/Sorget	\N	\N	2024-08-02 15:09:07.187413+03	\N
964	204	Kaputiei North	\N	\N	2024-08-02 15:09:07.187413+03	\N
965	204	Kitengela	\N	\N	2024-08-02 15:09:07.187413+03	\N
966	204	Oloosirkon/Sholinke	\N	\N	2024-08-02 15:09:07.187413+03	\N
967	204	Kenyawa-Poka	\N	\N	2024-08-02 15:09:07.187413+03	\N
968	204	Imaroro	\N	\N	2024-08-02 15:09:07.187413+03	\N
969	205	Ndanai/Abosi	\N	\N	2024-08-02 15:09:07.187413+03	\N
970	205	Chemagel	\N	\N	2024-08-02 15:09:07.187413+03	\N
971	205	Kipsonoi	\N	\N	2024-08-02 15:09:07.187413+03	\N
972	205	Kapletundo	\N	\N	2024-08-02 15:09:07.187413+03	\N
973	205	Rongena/Manaret	\N	\N	2024-08-02 15:09:07.187413+03	\N
974	159	Waseges	\N	\N	2024-08-02 15:09:07.187413+03	\N
975	159	Kabazi	\N	\N	2024-08-02 15:09:07.187413+03	\N
976	18	Mautuma	\N	\N	2024-08-02 15:09:07.187413+03	\N
977	18	Lugari	\N	\N	2024-08-02 15:09:07.187413+03	\N
978	18	Lumakanda	\N	\N	2024-08-02 15:09:07.187413+03	\N
979	206	Kabuchai/Chwele	\N	\N	2024-08-02 15:09:07.187413+03	\N
980	206	West Nalondo	\N	\N	2024-08-02 15:09:07.187413+03	\N
981	206	Bwake/Luuya	\N	\N	2024-08-02 15:09:07.187413+03	\N
982	206	Mukuyuni	\N	\N	2024-08-02 15:09:07.187413+03	\N
983	207	Idakho South	\N	\N	2024-08-02 15:09:07.187413+03	\N
984	207	Idakho East	\N	\N	2024-08-02 15:09:07.187413+03	\N
985	207	Idakho North	\N	\N	2024-08-02 15:09:07.187413+03	\N
986	207	Idakho Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
987	208	Ingostse-Mathia	\N	\N	2024-08-02 15:09:07.187413+03	\N
988	208	Shinoyi-Shikomari-	\N	\N	2024-08-02 15:09:07.187413+03	\N
989	208	Bunyala West	\N	\N	2024-08-02 15:09:07.187413+03	\N
990	208	Bunyala East	\N	\N	2024-08-02 15:09:07.187413+03	\N
991	208	Bunyala Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
992	209	Luanda Township	\N	\N	2024-08-02 15:09:07.187413+03	\N
993	209	Wemilabi	\N	\N	2024-08-02 15:09:07.187413+03	\N
994	209	Mwibona	\N	\N	2024-08-02 15:09:07.187413+03	\N
995	209	Luanda South	\N	\N	2024-08-02 15:09:07.187413+03	\N
996	209	Emabungo	\N	\N	2024-08-02 15:09:07.187413+03	\N
997	210	Chepchabas	\N	\N	2024-08-02 15:09:07.187413+03	\N
998	210	Kimulot	\N	\N	2024-08-02 15:09:07.187413+03	\N
999	210	Mogogosiek	\N	\N	2024-08-02 15:09:07.187413+03	\N
1000	210	Boito	\N	\N	2024-08-02 15:09:07.187413+03	\N
1001	210	Embomos	\N	\N	2024-08-02 15:09:07.187413+03	\N
1002	211	Marama West	\N	\N	2024-08-02 15:09:07.187413+03	\N
1003	211	Marama Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
1004	211	Marenyo - Shianda	\N	\N	2024-08-02 15:09:07.187413+03	\N
1005	211	Marama North	\N	\N	2024-08-02 15:09:07.187413+03	\N
1006	211	Marama South	\N	\N	2024-08-02 15:09:07.187413+03	\N
1007	212	Lubinu/Lusheya	\N	\N	2024-08-02 15:09:07.187413+03	\N
1008	212	Isongo/Makunga/Malaha	\N	\N	2024-08-02 15:09:07.187413+03	\N
1009	212	East Wanga	\N	\N	2024-08-02 15:09:07.187413+03	\N
1010	213	North East Bunyore	\N	\N	2024-08-02 15:09:07.187413+03	\N
1011	213	Central Bunyore	\N	\N	2024-08-02 15:09:07.187413+03	\N
1012	213	West Bunyore	\N	\N	2024-08-02 15:09:07.187413+03	\N
1013	214	Butsotso East	\N	\N	2024-08-02 15:09:07.187413+03	\N
1014	214	Butsotso South	\N	\N	2024-08-02 15:09:07.187413+03	\N
1015	214	Butsotso Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
1016	214	Sheywe	\N	\N	2024-08-02 15:09:07.187413+03	\N
1017	214	Mahiakalo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1018	214	Shirere	\N	\N	2024-08-02 15:09:07.187413+03	\N
1019	215	Lyaduywa/Izava	\N	\N	2024-08-02 15:09:07.187413+03	\N
1020	215	West Sabatia	\N	\N	2024-08-02 15:09:07.187413+03	\N
1021	215	Chavakali	\N	\N	2024-08-02 15:09:07.187413+03	\N
1022	215	North Maragoli	\N	\N	2024-08-02 15:09:07.187413+03	\N
1023	215	Wodanga	\N	\N	2024-08-02 15:09:07.187413+03	\N
1024	215	Busali	\N	\N	2024-08-02 15:09:07.187413+03	\N
1025	192	Kembu	\N	\N	2024-08-02 15:09:07.187413+03	\N
1026	192	Longisa	\N	\N	2024-08-02 15:09:07.187413+03	\N
1027	192	Kipreres	\N	\N	2024-08-02 15:09:07.187413+03	\N
1028	192	Chemaner	\N	\N	2024-08-02 15:09:07.187413+03	\N
1029	216	Mumias Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
1030	216	Mumias North	\N	\N	2024-08-02 15:09:07.187413+03	\N
1031	216	Etenje	\N	\N	2024-08-02 15:09:07.187413+03	\N
1032	216	Musanda	\N	\N	2024-08-02 15:09:07.187413+03	\N
1033	28	West Kabras	\N	\N	2024-08-02 15:09:07.187413+03	\N
1034	28	Chemuche	\N	\N	2024-08-02 15:09:07.187413+03	\N
1035	28	East Kabras	\N	\N	2024-08-02 15:09:07.187413+03	\N
1036	28	Butali/Chegulo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1037	28	Manda-Shivanga	\N	\N	2024-08-02 15:09:07.187413+03	\N
1038	28	Shirugu-Mugai	\N	\N	2024-08-02 15:09:07.187413+03	\N
1039	217	Namwela	\N	\N	2024-08-02 15:09:07.187413+03	\N
1040	217	Malakisi/South Kulisiru	\N	\N	2024-08-02 15:09:07.187413+03	\N
1041	217	Lwandanyi	\N	\N	2024-08-02 15:09:07.187413+03	\N
1042	218	Koyonzo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1043	218	Kholera	\N	\N	2024-08-02 15:09:07.187413+03	\N
1044	218	Mayoni	\N	\N	2024-08-02 15:09:07.187413+03	\N
1045	218	Namamali	\N	\N	2024-08-02 15:09:07.187413+03	\N
1046	219	Silibwet Township	\N	\N	2024-08-02 15:09:07.187413+03	\N
1047	219	Ndaraweta	\N	\N	2024-08-02 15:09:07.187413+03	\N
1048	219	Singorwet	\N	\N	2024-08-02 15:09:07.187413+03	\N
1049	219	Chesoen	\N	\N	2024-08-02 15:09:07.187413+03	\N
1050	219	Mutarakwa	\N	\N	2024-08-02 15:09:07.187413+03	\N
1051	220	Isukha North	\N	\N	2024-08-02 15:09:07.187413+03	\N
1052	220	Murhanda	\N	\N	2024-08-02 15:09:07.187413+03	\N
1053	220	Isukha Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
1054	220	Isukha South	\N	\N	2024-08-02 15:09:07.187413+03	\N
1055	220	Isukha East	\N	\N	2024-08-02 15:09:07.187413+03	\N
1056	220	Isukha West	\N	\N	2024-08-02 15:09:07.187413+03	\N
1057	221	Lugaga-Wamuluma	\N	\N	2024-08-02 15:09:07.187413+03	\N
1058	221	South Maragoli	\N	\N	2024-08-02 15:09:07.187413+03	\N
1059	221	Central Maragoli	\N	\N	2024-08-02 15:09:07.187413+03	\N
1060	221	Mungoma	\N	\N	2024-08-02 15:09:07.187413+03	\N
1061	222	Shiru	\N	\N	2024-08-02 15:09:07.187413+03	\N
1062	222	Muhudu	\N	\N	2024-08-02 15:09:07.187413+03	\N
1063	222	Shamakhokho	\N	\N	2024-08-02 15:09:07.187413+03	\N
1064	222	Gisambai	\N	\N	2024-08-02 15:09:07.187413+03	\N
1065	222	Banja	\N	\N	2024-08-02 15:09:07.187413+03	\N
1066	222	Tambua	\N	\N	2024-08-02 15:09:07.187413+03	\N
1067	222	Jepkoyai	\N	\N	2024-08-02 15:09:07.187413+03	\N
1068	223	Cheptais	\N	\N	2024-08-02 15:09:07.187413+03	\N
1069	223	Chesikaki	\N	\N	2024-08-02 15:09:07.187413+03	\N
1070	223	Chepyuk	\N	\N	2024-08-02 15:09:07.187413+03	\N
1071	223	Kapkateny	\N	\N	2024-08-02 15:09:07.187413+03	\N
1072	223	Kaptama	\N	\N	2024-08-02 15:09:07.187413+03	\N
1073	223	Elgon	\N	\N	2024-08-02 15:09:07.187413+03	\N
1074	224	South Bukusu	\N	\N	2024-08-02 15:09:07.187413+03	\N
1075	224	Bumula	\N	\N	2024-08-02 15:09:07.187413+03	\N
1076	224	Khasoko	\N	\N	2024-08-02 15:09:07.187413+03	\N
1077	224	Kabula	\N	\N	2024-08-02 15:09:07.187413+03	\N
1078	224	Kimaeti	\N	\N	2024-08-02 15:09:07.187413+03	\N
1079	224	West Bukusu	\N	\N	2024-08-02 15:09:07.187413+03	\N
1080	224	Siboti	\N	\N	2024-08-02 15:09:07.187413+03	\N
1081	225	Likuyani	\N	\N	2024-08-02 15:09:07.187413+03	\N
1082	225	Sango	\N	\N	2024-08-02 15:09:07.187413+03	\N
1083	225	Kongoni	\N	\N	2024-08-02 15:09:07.187413+03	\N
1084	225	Nzoia	\N	\N	2024-08-02 15:09:07.187413+03	\N
1085	225	Sinoko	\N	\N	2024-08-02 15:09:07.187413+03	\N
1086	226	Kisa North	\N	\N	2024-08-02 15:09:07.187413+03	\N
1087	226	Kisa East	\N	\N	2024-08-02 15:09:07.187413+03	\N
1088	226	Kisa West	\N	\N	2024-08-02 15:09:07.187413+03	\N
1089	226	Kisa Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
1090	227	Miwani	\N	\N	2024-08-02 15:09:07.187413+03	\N
1091	227	Ombeyi	\N	\N	2024-08-02 15:09:07.187413+03	\N
1092	227	Masogo/Nyangoma	\N	\N	2024-08-02 15:09:07.187413+03	\N
1093	227	Chemelil	\N	\N	2024-08-02 15:09:07.187413+03	\N
1094	227	Muhoroni/Koru	\N	\N	2024-08-02 15:09:07.187413+03	\N
1095	24	Usonga	\N	\N	2024-08-02 15:09:07.187413+03	\N
1096	24	West Alego	\N	\N	2024-08-02 15:09:07.187413+03	\N
1097	24	Central Alego	\N	\N	2024-08-02 15:09:07.187413+03	\N
1098	24	Siaya Township	\N	\N	2024-08-02 15:09:07.187413+03	\N
1099	24	North Alego	\N	\N	2024-08-02 15:09:07.187413+03	\N
1100	228	East Asembo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1101	228	West Asembo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1102	228	North Uyoma	\N	\N	2024-08-02 15:09:07.187413+03	\N
1103	228	South Uyoma	\N	\N	2024-08-02 15:09:07.187413+03	\N
1104	228	West Uyoma	\N	\N	2024-08-02 15:09:07.187413+03	\N
1105	229	West Ugenya	\N	\N	2024-08-02 15:09:07.187413+03	\N
1106	229	Ukwala	\N	\N	2024-08-02 15:09:07.187413+03	\N
1107	229	North Ugenya	\N	\N	2024-08-02 15:09:07.187413+03	\N
1108	229	East Ugenya	\N	\N	2024-08-02 15:09:07.187413+03	\N
1109	230	West Yimbo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1110	230	Central Sakwa	\N	\N	2024-08-02 15:09:07.187413+03	\N
1111	230	South Sakwa	\N	\N	2024-08-02 15:09:07.187413+03	\N
1112	230	Yimbo East	\N	\N	2024-08-02 15:09:07.187413+03	\N
1113	230	West Sakwa	\N	\N	2024-08-02 15:09:07.187413+03	\N
1114	230	North Sakwa	\N	\N	2024-08-02 15:09:07.187413+03	\N
1115	231	Namboboto Nambuku	\N	\N	2024-08-02 15:09:07.187413+03	\N
1116	231	Nangina	\N	\N	2024-08-02 15:09:07.187413+03	\N
1117	231	Agenga Nanguba	\N	\N	2024-08-02 15:09:07.187413+03	\N
1118	231	Bwiri	\N	\N	2024-08-02 15:09:07.187413+03	\N
1119	232	Marachi West	\N	\N	2024-08-02 15:09:07.187413+03	\N
1120	232	Kingandole	\N	\N	2024-08-02 15:09:07.187413+03	\N
1121	232	Marachi Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
1122	232	Marachi East	\N	\N	2024-08-02 15:09:07.187413+03	\N
1123	232	Marachi North	\N	\N	2024-08-02 15:09:07.187413+03	\N
1124	232	Elugulu	\N	\N	2024-08-02 15:09:07.187413+03	\N
1125	233	North Gem	\N	\N	2024-08-02 15:09:07.187413+03	\N
1126	233	West Gem	\N	\N	2024-08-02 15:09:07.187413+03	\N
1127	233	Central Gem	\N	\N	2024-08-02 15:09:07.187413+03	\N
1128	233	Yala Township	\N	\N	2024-08-02 15:09:07.187413+03	\N
1129	233	East Gem	\N	\N	2024-08-02 15:09:07.187413+03	\N
1130	233	South Gem	\N	\N	2024-08-02 15:09:07.187413+03	\N
1131	234	Mbakalo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1132	234	Naitiri/Kabuyefwe	\N	\N	2024-08-02 15:09:07.187413+03	\N
1133	234	Milima	\N	\N	2024-08-02 15:09:07.187413+03	\N
1134	234	Ndalu/ Tabani	\N	\N	2024-08-02 15:09:07.187413+03	\N
1135	234	Tongaren	\N	\N	2024-08-02 15:09:07.187413+03	\N
1136	234	Soysambu/ Mitua	\N	\N	2024-08-02 15:09:07.187413+03	\N
1137	235	Angorom	\N	\N	2024-08-02 15:09:07.187413+03	\N
1138	235	Chakol South	\N	\N	2024-08-02 15:09:07.187413+03	\N
1139	235	Chakol North	\N	\N	2024-08-02 15:09:07.187413+03	\N
1140	235	Amukura West	\N	\N	2024-08-02 15:09:07.187413+03	\N
1141	235	Amukura East	\N	\N	2024-08-02 15:09:07.187413+03	\N
1142	235	Amukura Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
1143	236	Nambale Township	\N	\N	2024-08-02 15:09:07.187413+03	\N
1144	236	Bukhayo North/Waltsi	\N	\N	2024-08-02 15:09:07.187413+03	\N
1145	236	Bukhayo East	\N	\N	2024-08-02 15:09:07.187413+03	\N
1146	236	Bukhayo Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
1147	237	Malaba Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
1148	237	Malaba North	\N	\N	2024-08-02 15:09:07.187413+03	\N
1149	237	Angurai South	\N	\N	2024-08-02 15:09:07.187413+03	\N
1150	237	Angurai North	\N	\N	2024-08-02 15:09:07.187413+03	\N
1151	237	Angurai East	\N	\N	2024-08-02 15:09:07.187413+03	\N
1152	237	Malaba South	\N	\N	2024-08-02 15:09:07.187413+03	\N
1153	238	Railways	\N	\N	2024-08-02 15:09:07.187413+03	\N
1154	238	Migosi	\N	\N	2024-08-02 15:09:07.187413+03	\N
1155	238	Shaurimoyo Kaloleni	\N	\N	2024-08-02 15:09:07.187413+03	\N
1156	238	Market Milimani	\N	\N	2024-08-02 15:09:07.187413+03	\N
1157	238	Kondele	\N	\N	2024-08-02 15:09:07.187413+03	\N
1158	238	Nyalenda B	\N	\N	2024-08-02 15:09:07.187413+03	\N
1159	239	Misikhu	\N	\N	2024-08-02 15:09:07.187413+03	\N
1160	239	Sitikho	\N	\N	2024-08-02 15:09:07.187413+03	\N
1161	239	Matulo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1162	239	Bokoli	\N	\N	2024-08-02 15:09:07.187413+03	\N
1163	240	East Kano/Wawidhi	\N	\N	2024-08-02 15:09:07.187413+03	\N
1164	240	Awasi/Onjiko	\N	\N	2024-08-02 15:09:07.187413+03	\N
1165	240	Ahero	\N	\N	2024-08-02 15:09:07.187413+03	\N
1166	240	Kabonyo/Kanyagwal	\N	\N	2024-08-02 15:09:07.187413+03	\N
1167	240	Kobura	\N	\N	2024-08-02 15:09:07.187413+03	\N
1168	241	Bunyala North	\N	\N	2024-08-02 15:09:07.187413+03	\N
1169	241	Bunyala South	\N	\N	2024-08-02 15:09:07.187413+03	\N
1170	242	Mihuu	\N	\N	2024-08-02 15:09:07.187413+03	\N
1171	242	Ndivisi	\N	\N	2024-08-02 15:09:07.187413+03	\N
1172	242	Maraka	\N	\N	2024-08-02 15:09:07.187413+03	\N
1173	243	Kimilili	\N	\N	2024-08-02 15:09:07.187413+03	\N
1174	243	Kibingei	\N	\N	2024-08-02 15:09:07.187413+03	\N
1175	243	Maeni	\N	\N	2024-08-02 15:09:07.187413+03	\N
1176	243	Kamukuywa	\N	\N	2024-08-02 15:09:07.187413+03	\N
1177	244	Kajulu	\N	\N	2024-08-02 15:09:07.187413+03	\N
1178	244	Kolwa East	\N	\N	2024-08-02 15:09:07.187413+03	\N
1179	244	Manyatta B	\N	\N	2024-08-02 15:09:07.187413+03	\N
1180	244	Nyalenda A	\N	\N	2024-08-02 15:09:07.187413+03	\N
1181	244	Kolwa Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
1182	245	South West Kisumu	\N	\N	2024-08-02 15:09:07.187413+03	\N
1183	245	Central Kisumu	\N	\N	2024-08-02 15:09:07.187413+03	\N
1184	245	Kisumu North	\N	\N	2024-08-02 15:09:07.187413+03	\N
1185	245	West Kisumu	\N	\N	2024-08-02 15:09:07.187413+03	\N
1186	245	North West Kisumu	\N	\N	2024-08-02 15:09:07.187413+03	\N
1187	246	Sidindi	\N	\N	2024-08-02 15:09:07.187413+03	\N
1188	246	Sigomere	\N	\N	2024-08-02 15:09:07.187413+03	\N
1189	246	Ugunja	\N	\N	2024-08-02 15:09:07.187413+03	\N
1190	247	South West Nyakach	\N	\N	2024-08-02 15:09:07.187413+03	\N
1191	247	North Nyakach	\N	\N	2024-08-02 15:09:07.187413+03	\N
1192	248	Bukhayo West	\N	\N	2024-08-02 15:09:07.187413+03	\N
1193	248	Mayenje	\N	\N	2024-08-02 15:09:07.187413+03	\N
1194	248	Matayos South	\N	\N	2024-08-02 15:09:07.187413+03	\N
1195	248	Busibwabo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1196	248	Burumba	\N	\N	2024-08-02 15:09:07.187413+03	\N
1197	249	West Seme	\N	\N	2024-08-02 15:09:07.187413+03	\N
1198	249	Central Seme	\N	\N	2024-08-02 15:09:07.187413+03	\N
1199	249	East Seme	\N	\N	2024-08-02 15:09:07.187413+03	\N
1200	249	North Seme	\N	\N	2024-08-02 15:09:07.187413+03	\N
1201	250	Homa Bay Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
1202	250	Homa Bay Arujo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1203	250	Homa Bay West	\N	\N	2024-08-02 15:09:07.187413+03	\N
1204	250	Homa Bay East	\N	\N	2024-08-02 15:09:07.187413+03	\N
1205	251	Gwassi South	\N	\N	2024-08-02 15:09:07.187413+03	\N
1206	251	Gwassi North	\N	\N	2024-08-02 15:09:07.187413+03	\N
1207	251	Kaksingri West	\N	\N	2024-08-02 15:09:07.187413+03	\N
1208	251	Ruma Kaksingri East	\N	\N	2024-08-02 15:09:07.187413+03	\N
1209	22	Gokeharaka/Getambwega	\N	\N	2024-08-02 15:09:07.187413+03	\N
1210	22	Ntimaru West	\N	\N	2024-08-02 15:09:07.187413+03	\N
1211	22	Ntimaru East	\N	\N	2024-08-02 15:09:07.187413+03	\N
1212	22	Nyabasi East	\N	\N	2024-08-02 15:09:07.187413+03	\N
1213	252	Kabondo East	\N	\N	2024-08-02 15:09:07.187413+03	\N
1214	252	Kabondo West	\N	\N	2024-08-02 15:09:07.187413+03	\N
1215	252	Kokwanyo/Kakelo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1216	252	Kojwach	\N	\N	2024-08-02 15:09:07.187413+03	\N
1217	254	Ichuni	\N	\N	2024-08-02 15:09:07.187413+03	\N
1218	254	Nyamasibi	\N	\N	2024-08-02 15:09:07.187413+03	\N
1219	254	Masimba	\N	\N	2024-08-02 15:09:07.187413+03	\N
1220	254	Gesusu	\N	\N	2024-08-02 15:09:07.187413+03	\N
1221	254	Kiamokama	\N	\N	2024-08-02 15:09:07.187413+03	\N
1222	255	Mfangano Island	\N	\N	2024-08-02 15:09:07.187413+03	\N
1223	255	Rusinga Island	\N	\N	2024-08-02 15:09:07.187413+03	\N
1224	255	Kasgunga	\N	\N	2024-08-02 15:09:07.187413+03	\N
1225	255	Gembe	\N	\N	2024-08-02 15:09:07.187413+03	\N
1226	255	Lambwe	\N	\N	2024-08-02 15:09:07.187413+03	\N
1227	27	Masige West	\N	\N	2024-08-02 15:09:07.187413+03	\N
1228	27	Masige East	\N	\N	2024-08-02 15:09:07.187413+03	\N
1229	27	Bobasi Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
1230	27	Nyacheki	\N	\N	2024-08-02 15:09:07.187413+03	\N
1231	27	Bobasi Bogetaorio	\N	\N	2024-08-02 15:09:07.187413+03	\N
1232	27	Bobasi Chache	\N	\N	2024-08-02 15:09:07.187413+03	\N
1233	256	North Kamagambo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1234	256	Central Kamagambo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1235	256	East Kamagambo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1236	256	South Kamagambo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1237	257	Kwabwai	\N	\N	2024-08-02 15:09:07.187413+03	\N
1238	257	Kanyadoto	\N	\N	2024-08-02 15:09:07.187413+03	\N
1239	257	Kanyikela	\N	\N	2024-08-02 15:09:07.187413+03	\N
1240	257	North Kabuoch	\N	\N	2024-08-02 15:09:07.187413+03	\N
1241	257	Kabuoch South/Pala	\N	\N	2024-08-02 15:09:07.187413+03	\N
1242	257	Kanyamwa Kologi	\N	\N	2024-08-02 15:09:07.187413+03	\N
1243	257	Kanyamwa Kosewe	\N	\N	2024-08-02 15:09:07.187413+03	\N
1244	258	Kachieng	\N	\N	2024-08-02 15:09:07.187413+03	\N
1245	258	Kanyasa	\N	\N	2024-08-02 15:09:07.187413+03	\N
1246	258	North Kadem	\N	\N	2024-08-02 15:09:07.187413+03	\N
1247	258	Macalder/Kanyarwanda	\N	\N	2024-08-02 15:09:07.187413+03	\N
1248	258	Kaler	\N	\N	2024-08-02 15:09:07.187413+03	\N
1249	258	Got Kachola	\N	\N	2024-08-02 15:09:07.187413+03	\N
1250	258	Muhuru	\N	\N	2024-08-02 15:09:07.187413+03	\N
1251	259	Kagan	\N	\N	2024-08-02 15:09:07.187413+03	\N
1252	259	Kochia	\N	\N	2024-08-02 15:09:07.187413+03	\N
1253	260	West Kanyamkago	\N	\N	2024-08-02 15:09:07.187413+03	\N
1254	260	North Kanyamkago	\N	\N	2024-08-02 15:09:07.187413+03	\N
1255	260	Central Kanyamkago	\N	\N	2024-08-02 15:09:07.187413+03	\N
1256	260	South Kanyamkago	\N	\N	2024-08-02 15:09:07.187413+03	\N
1257	260	East Kanyamkago	\N	\N	2024-08-02 15:09:07.187413+03	\N
1258	261	Bomariba	\N	\N	2024-08-02 15:09:07.187413+03	\N
1259	261	Bogiakumu	\N	\N	2024-08-02 15:09:07.187413+03	\N
1260	261	Bomorenda	\N	\N	2024-08-02 15:09:07.187413+03	\N
1261	261	Riana	\N	\N	2024-08-02 15:09:07.187413+03	\N
1262	262	Bukira East	\N	\N	2024-08-02 15:09:07.187413+03	\N
1263	262	Bukira Central/Ikerege	\N	\N	2024-08-02 15:09:07.187413+03	\N
1264	262	Isibania	\N	\N	2024-08-02 15:09:07.187413+03	\N
1265	262	Makerero	\N	\N	2024-08-02 15:09:07.187413+03	\N
1266	262	Masaba	\N	\N	2024-08-02 15:09:07.187413+03	\N
1267	262	Tagare	\N	\N	2024-08-02 15:09:07.187413+03	\N
1268	262	Nyamosense/Komosoko	\N	\N	2024-08-02 15:09:07.187413+03	\N
1269	263	Bobaracho	\N	\N	2024-08-02 15:09:07.187413+03	\N
1270	263	Kisii Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
1271	263	Keumbu	\N	\N	2024-08-02 15:09:07.187413+03	\N
1272	263	Kiogoro	\N	\N	2024-08-02 15:09:07.187413+03	\N
1273	264	God Jope	\N	\N	2024-08-02 15:09:07.187413+03	\N
1274	264	Suna Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
1275	264	Kakrao	\N	\N	2024-08-02 15:09:07.187413+03	\N
1276	264	Kwa	\N	\N	2024-08-02 15:09:07.187413+03	\N
1277	265	Majoge	\N	\N	2024-08-02 15:09:07.187413+03	\N
1278	265	Boochi/Tendere	\N	\N	2024-08-02 15:09:07.187413+03	\N
1279	265	Bosoti/Sengera	\N	\N	2024-08-02 15:09:07.187413+03	\N
1280	266	Tabaka	\N	\N	2024-08-02 15:09:07.187413+03	\N
1281	266	Boikanga	\N	\N	2024-08-02 15:09:07.187413+03	\N
1282	266	Bogetenga	\N	\N	2024-08-02 15:09:07.187413+03	\N
1283	266	Borabu / Chitago	\N	\N	2024-08-02 15:09:07.187413+03	\N
1284	266	Moticho	\N	\N	2024-08-02 15:09:07.187413+03	\N
1285	266	Getenga	\N	\N	2024-08-02 15:09:07.187413+03	\N
1286	267	West Kasipul	\N	\N	2024-08-02 15:09:07.187413+03	\N
1287	267	South Kasipul	\N	\N	2024-08-02 15:09:07.187413+03	\N
1288	267	Central Kasipul	\N	\N	2024-08-02 15:09:07.187413+03	\N
1289	267	East Kamagak	\N	\N	2024-08-02 15:09:07.187413+03	\N
1290	267	West Kamagak	\N	\N	2024-08-02 15:09:07.187413+03	\N
1291	268	West Karachuonyo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1292	268	North Karachuonyo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1293	268	Kanyaluo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1294	268	Kibiri	\N	\N	2024-08-02 15:09:07.187413+03	\N
1295	268	Wangchieng	\N	\N	2024-08-02 15:09:07.187413+03	\N
1296	268	Kendu Bay Town	\N	\N	2024-08-02 15:09:07.187413+03	\N
1297	269	Bombaba Borabu	\N	\N	2024-08-02 15:09:07.187413+03	\N
1298	269	Boochi Borabu	\N	\N	2024-08-02 15:09:07.187413+03	\N
1299	269	Bokimonge	\N	\N	2024-08-02 15:09:07.187413+03	\N
1300	269	Magenche	\N	\N	2024-08-02 15:09:07.187413+03	\N
1301	247	Central Nyakach	\N	\N	2024-08-02 15:09:07.187413+03	\N
1302	247	West Nyakach	\N	\N	2024-08-02 15:09:07.187413+03	\N
1303	247	South East Nyakach	\N	\N	2024-08-02 15:09:07.187413+03	\N
1304	5	Kayole North	\N	\N	2024-08-02 15:09:07.187413+03	\N
1305	270	Pumwani	\N	\N	2024-08-02 15:09:07.187413+03	\N
1306	270	Eastleigh North	\N	\N	2024-08-02 15:09:07.187413+03	\N
1307	270	Eastleigh South	\N	\N	2024-08-02 15:09:07.187413+03	\N
1308	270	Airbase	\N	\N	2024-08-02 15:09:07.187413+03	\N
1309	270	California	\N	\N	2024-08-02 15:09:07.187413+03	\N
1310	29	Kiabonyoru	\N	\N	2024-08-02 15:09:07.187413+03	\N
1311	29	Nyansiongo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1312	29	Esise	\N	\N	2024-08-02 15:09:07.187413+03	\N
1313	271	Kitisuru	\N	\N	2024-08-02 15:09:07.187413+03	\N
1314	271	Parklands/Highridge	\N	\N	2024-08-02 15:09:07.187413+03	\N
1315	271	Karura	\N	\N	2024-08-02 15:09:07.187413+03	\N
1316	271	Kangemi	\N	\N	2024-08-02 15:09:07.187413+03	\N
1317	271	Mountain View	\N	\N	2024-08-02 15:09:07.187413+03	\N
1318	272	Baba Dogo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1319	272	Utalii	\N	\N	2024-08-02 15:09:07.187413+03	\N
1320	272	Mathare North	\N	\N	2024-08-02 15:09:07.187413+03	\N
1321	272	Lucky Summer	\N	\N	2024-08-02 15:09:07.187413+03	\N
1322	272	Korogocho	\N	\N	2024-08-02 15:09:07.187413+03	\N
1323	273	Itibo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1324	273	Bomwagamo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1325	273	Bokeira	\N	\N	2024-08-02 15:09:07.187413+03	\N
1326	273	Magwagwa	\N	\N	2024-08-02 15:09:07.187413+03	\N
1327	273	Ekerenyo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1328	274	Nairobi Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
1329	274	Ngara	\N	\N	2024-08-02 15:09:07.187413+03	\N
1330	274	Ziwani/Kariokor	\N	\N	2024-08-02 15:09:07.187413+03	\N
1331	274	Pangani	\N	\N	2024-08-02 15:09:07.187413+03	\N
1332	274	Landimawe	\N	\N	2024-08-02 15:09:07.187413+03	\N
1333	274	Nairobi South	\N	\N	2024-08-02 15:09:07.187413+03	\N
1334	275	Claycity	\N	\N	2024-08-02 15:09:07.187413+03	\N
1335	275	Kasarani	\N	\N	2024-08-02 15:09:07.187413+03	\N
1336	275	Njiru	\N	\N	2024-08-02 15:09:07.187413+03	\N
1337	275	Ruai	\N	\N	2024-08-02 15:09:07.187413+03	\N
1338	276	Nyamaiya	\N	\N	2024-08-02 15:09:07.187413+03	\N
1339	276	Bogichora	\N	\N	2024-08-02 15:09:07.187413+03	\N
1340	276	Bosamaro	\N	\N	2024-08-02 15:09:07.187413+03	\N
1341	276	Bonyamatuta	\N	\N	2024-08-02 15:09:07.187413+03	\N
1342	277	Kariobangi North	\N	\N	2024-08-02 15:09:07.187413+03	\N
1343	277	Dandora Area I	\N	\N	2024-08-02 15:09:07.187413+03	\N
1344	277	Dandora Area Ii	\N	\N	2024-08-02 15:09:07.187413+03	\N
1345	277	Dandora Area Iii	\N	\N	2024-08-02 15:09:07.187413+03	\N
1346	277	Dandora Area Iv	\N	\N	2024-08-02 15:09:07.187413+03	\N
1347	278	Makongeni	\N	\N	2024-08-02 15:09:07.187413+03	\N
1348	278	Maringo/Hamza	\N	\N	2024-08-02 15:09:07.187413+03	\N
1349	278	Harambee	\N	\N	2024-08-02 15:09:07.187413+03	\N
1350	279	Upper Savannah	\N	\N	2024-08-02 15:09:07.187413+03	\N
1351	279	Lower Savannah	\N	\N	2024-08-02 15:09:07.187413+03	\N
1352	279	Embakasi	\N	\N	2024-08-02 15:09:07.187413+03	\N
1353	279	Utawala	\N	\N	2024-08-02 15:09:07.187413+03	\N
1354	279	Mihango	\N	\N	2024-08-02 15:09:07.187413+03	\N
1355	280	Mutuini	\N	\N	2024-08-02 15:09:07.187413+03	\N
1356	280	Ngando	\N	\N	2024-08-02 15:09:07.187413+03	\N
1357	280	Riruta	\N	\N	2024-08-02 15:09:07.187413+03	\N
1358	280	Uthiru/Ruthimitu	\N	\N	2024-08-02 15:09:07.187413+03	\N
1359	280	Waithaka	\N	\N	2024-08-02 15:09:07.187413+03	\N
1360	281	Umoja I	\N	\N	2024-08-02 15:09:07.187413+03	\N
1361	281	Umoja Ii	\N	\N	2024-08-02 15:09:07.187413+03	\N
1362	281	Mowlem	\N	\N	2024-08-02 15:09:07.187413+03	\N
1363	281	Kariobangi South	\N	\N	2024-08-02 15:09:07.187413+03	\N
1364	282	Kilimani	\N	\N	2024-08-02 15:09:07.187413+03	\N
1365	282	Kawangware	\N	\N	2024-08-02 15:09:07.187413+03	\N
1366	282	Gatina	\N	\N	2024-08-02 15:09:07.187413+03	\N
1367	282	Kileleshwa	\N	\N	2024-08-02 15:09:07.187413+03	\N
1368	282	Kabiro	\N	\N	2024-08-02 15:09:07.187413+03	\N
1369	263	Birongo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1370	263	Ibeno	\N	\N	2024-08-02 15:09:07.187413+03	\N
1371	283	Githurai	\N	\N	2024-08-02 15:09:07.187413+03	\N
1372	283	Kahawa West	\N	\N	2024-08-02 15:09:07.187413+03	\N
1373	283	Zimmerman	\N	\N	2024-08-02 15:09:07.187413+03	\N
1374	283	Roysambu	\N	\N	2024-08-02 15:09:07.187413+03	\N
1375	283	Kahawa	\N	\N	2024-08-02 15:09:07.187413+03	\N
1376	284	Monyerero	\N	\N	2024-08-02 15:09:07.187413+03	\N
1377	284	Sensi	\N	\N	2024-08-02 15:09:07.187413+03	\N
1378	284	Marani	\N	\N	2024-08-02 15:09:07.187413+03	\N
1379	284	Kegogi	\N	\N	2024-08-02 15:09:07.187413+03	\N
1380	285	Imara Daima	\N	\N	2024-08-02 15:09:07.187413+03	\N
1381	285	Kwa Njenga	\N	\N	2024-08-02 15:09:07.187413+03	\N
1382	285	Kwa Reuben	\N	\N	2024-08-02 15:09:07.187413+03	\N
1383	285	Pipeline	\N	\N	2024-08-02 15:09:07.187413+03	\N
1384	285	Kware	\N	\N	2024-08-02 15:09:07.187413+03	\N
1385	286	Mabatini	\N	\N	2024-08-02 15:09:07.187413+03	\N
1386	286	Ngei	\N	\N	2024-08-02 15:09:07.187413+03	\N
1387	286	Mlango Kubwa	\N	\N	2024-08-02 15:09:07.187413+03	\N
1388	286	Kiamaiko	\N	\N	2024-08-02 15:09:07.187413+03	\N
1389	287	Karen	\N	\N	2024-08-02 15:09:07.187413+03	\N
1390	287	Nairobi West	\N	\N	2024-08-02 15:09:07.187413+03	\N
1391	287	South-C	\N	\N	2024-08-02 15:09:07.187413+03	\N
1392	287	Nyayo Highrise	\N	\N	2024-08-02 15:09:07.187413+03	\N
1393	288	Rigoma	\N	\N	2024-08-02 15:09:07.187413+03	\N
1394	288	Gachuba	\N	\N	2024-08-02 15:09:07.187413+03	\N
1395	288	Kemera	\N	\N	2024-08-02 15:09:07.187413+03	\N
1396	288	Magombo	\N	\N	2024-08-02 15:09:07.187413+03	\N
1397	288	Manga	\N	\N	2024-08-02 15:09:07.187413+03	\N
1398	288	Gesima	\N	\N	2024-08-02 15:09:07.187413+03	\N
1399	289	Laini Saba	\N	\N	2024-08-02 15:09:07.187413+03	\N
1400	289	Lindi	\N	\N	2024-08-02 15:09:07.187413+03	\N
1401	289	Makina	\N	\N	2024-08-02 15:09:07.187413+03	\N
1402	289	Woodley/Kenyatta Golf	\N	\N	2024-08-02 15:09:07.187413+03	\N
1403	289	Sarangombe	\N	\N	2024-08-02 15:09:07.187413+03	\N
1404	290	Bogusero	\N	\N	2024-08-02 15:09:07.187413+03	\N
1405	290	Bogeka	\N	\N	2024-08-02 15:09:07.187413+03	\N
1406	290	Nyakoe	\N	\N	2024-08-02 15:09:07.187413+03	\N
1407	290	Kitutu   Central	\N	\N	2024-08-02 15:09:07.187413+03	\N
1408	290	Nyatieko	\N	\N	2024-08-02 15:09:07.187413+03	\N
\.


--
-- Data for Name: tbl_constituency; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tbl_constituency (cst_id, cty_id, name, date_created, last_update) FROM stdin;
1	1	Jomvu	2024-08-02 15:09:07.187413	\N
2	1	Changamwe	2024-08-02 15:09:07.187413	\N
3	1	Nyali	2024-08-02 15:09:07.187413	\N
4	1	Kisauni	2024-08-02 15:09:07.187413	\N
5	2	Embakasi Central	2024-08-02 15:09:07.187413	\N
6	3	Voi	2024-08-02 15:09:07.187413	\N
7	4	Dadaab	2024-08-02 15:09:07.187413	\N
8	5	Wajir North	2024-08-02 15:09:07.187413	\N
9	6	Isiolo South	2024-08-02 15:09:07.187413	\N
10	7	North Imenti	2024-08-02 15:09:07.187413	\N
11	8	Kanduyi	2024-08-02 15:09:07.187413	\N
12	9	Narok East	2024-08-02 15:09:07.187413	\N
13	10	Kinangop	2024-08-02 15:09:07.187413	\N
14	11	Samburu West	2024-08-02 15:09:07.187413	\N
15	12	Emgwen	2024-08-02 15:09:07.187413	\N
16	13	Turbo	2024-08-02 15:09:07.187413	\N
17	14	Suna West	2024-08-02 15:09:07.187413	\N
18	15	Lugari	2024-08-02 15:09:07.187413	\N
19	12	Chesumei	2024-08-02 15:09:07.187413	\N
20	9	Narok North	2024-08-02 15:09:07.187413	\N
21	16	Kandara	2024-08-02 15:09:07.187413	\N
22	14	Kuria East	2024-08-02 15:09:07.187413	\N
23	16	Kiharu	2024-08-02 15:09:07.187413	\N
24	17	Alego Usonga	2024-08-02 15:09:07.187413	\N
25	13	Soy	2024-08-02 15:09:07.187413	\N
26	18	Ruiru	2024-08-02 15:09:07.187413	\N
27	19	Bobasi	2024-08-02 15:09:07.187413	\N
28	15	Malava	2024-08-02 15:09:07.187413	\N
29	20	Borabu	2024-08-02 15:09:07.187413	\N
30	1	Likoni	2024-08-02 15:09:07.187413	\N
31	1	Mvita	2024-08-02 15:09:07.187413	\N
32	21	Lungalunga	2024-08-02 15:09:07.187413	\N
33	21	Kinango	2024-08-02 15:09:07.187413	\N
34	21	Matuga	2024-08-02 15:09:07.187413	\N
35	21	Msambweni	2024-08-02 15:09:07.187413	\N
36	22	Kilifi North	2024-08-02 15:09:07.187413	\N
37	22	Kilifi South	2024-08-02 15:09:07.187413	\N
38	22	Rabai	2024-08-02 15:09:07.187413	\N
39	22	Ganze	2024-08-02 15:09:07.187413	\N
40	22	Malindi	2024-08-02 15:09:07.187413	\N
41	22	Kaloleni	2024-08-02 15:09:07.187413	\N
42	22	Magarini	2024-08-02 15:09:07.187413	\N
43	23	Bura	2024-08-02 15:09:07.187413	\N
44	23	Garsen	2024-08-02 15:09:07.187413	\N
45	23	Galole	2024-08-02 15:09:07.187413	\N
46	24	Lamu East	2024-08-02 15:09:07.187413	\N
47	24	Lamu West	2024-08-02 15:09:07.187413	\N
48	3	Wundanyi	2024-08-02 15:09:07.187413	\N
49	3	Mwatate	2024-08-02 15:09:07.187413	\N
50	3	Taveta	2024-08-02 15:09:07.187413	\N
51	4	Garissa Township	2024-08-02 15:09:07.187413	\N
52	4	Ijara	2024-08-02 15:09:07.187413	\N
53	4	Lagdera	2024-08-02 15:09:07.187413	\N
54	4	Fafi	2024-08-02 15:09:07.187413	\N
55	4	Balambala	2024-08-02 15:09:07.187413	\N
56	5	Eldas	2024-08-02 15:09:07.187413	\N
57	5	Tarbaj	2024-08-02 15:09:07.187413	\N
58	5	Wajir West	2024-08-02 15:09:07.187413	\N
59	5	Wajir South	2024-08-02 15:09:07.187413	\N
60	5	Wajir East	2024-08-02 15:09:07.187413	\N
61	25	Mandera North	2024-08-02 15:09:07.187413	\N
62	25	Mandera South	2024-08-02 15:09:07.187413	\N
63	25	Mandera East	2024-08-02 15:09:07.187413	\N
64	25	Mandera West	2024-08-02 15:09:07.187413	\N
65	25	Banissa	2024-08-02 15:09:07.187413	\N
66	25	Lafey	2024-08-02 15:09:07.187413	\N
67	26	Moyale	2024-08-02 15:09:07.187413	\N
68	26	Saku	2024-08-02 15:09:07.187413	\N
69	26	North Horr	2024-08-02 15:09:07.187413	\N
70	26	Laisamis	2024-08-02 15:09:07.187413	\N
71	6	Isiolo North	2024-08-02 15:09:07.187413	\N
72	7	Igembe South	2024-08-02 15:09:07.187413	\N
73	7	South Imenti	2024-08-02 15:09:07.187413	\N
74	7	Central Imenti	2024-08-02 15:09:07.187413	\N
75	7	Igembe North	2024-08-02 15:09:07.187413	\N
76	7	Tigania West	2024-08-02 15:09:07.187413	\N
77	7	Buuri	2024-08-02 15:09:07.187413	\N
78	7	Igembe Central	2024-08-02 15:09:07.187413	\N
79	7	Tigania East	2024-08-02 15:09:07.187413	\N
80	27	Tharaka	2024-08-02 15:09:07.187413	\N
81	27	Chuka/Igambangom	2024-08-02 15:09:07.187413	\N
82	28	Runyenjes	2024-08-02 15:09:07.187413	\N
83	29	Kitui Central	2024-08-02 15:09:07.187413	\N
84	29	Kitui South	2024-08-02 15:09:07.187413	\N
85	29	Kitui East	2024-08-02 15:09:07.187413	\N
86	29	Kitui West	2024-08-02 15:09:07.187413	\N
87	29	Mwingi North	2024-08-02 15:09:07.187413	\N
88	28	Mbeere South	2024-08-02 15:09:07.187413	\N
89	29	Mwingi Central	2024-08-02 15:09:07.187413	\N
90	29	Kitui Rural	2024-08-02 15:09:07.187413	\N
91	28	Mbeere North	2024-08-02 15:09:07.187413	\N
92	27	Maara	2024-08-02 15:09:07.187413	\N
93	28	Manyatta	2024-08-02 15:09:07.187413	\N
94	29	Mwingi West	2024-08-02 15:09:07.187413	\N
95	30	Tetu	2024-08-02 15:09:07.187413	\N
96	31	Mbooni	2024-08-02 15:09:07.187413	\N
97	31	Kibwezi East	2024-08-02 15:09:07.187413	\N
98	10	Kipipiri	2024-08-02 15:09:07.187413	\N
99	30	Othaya	2024-08-02 15:09:07.187413	\N
100	30	Kieni	2024-08-02 15:09:07.187413	\N
101	31	Kilome	2024-08-02 15:09:07.187413	\N
102	30	Mukurweini	2024-08-02 15:09:07.187413	\N
103	32	Yatta	2024-08-02 15:09:07.187413	\N
104	32	Mavoko	2024-08-02 15:09:07.187413	\N
105	31	Makueni	2024-08-02 15:09:07.187413	\N
106	10	Ndaragwa	2024-08-02 15:09:07.187413	\N
107	32	Kathiani	2024-08-02 15:09:07.187413	\N
108	32	Matungulu	2024-08-02 15:09:07.187413	\N
109	10	Ol Jorok	2024-08-02 15:09:07.187413	\N
110	30	Mathira	2024-08-02 15:09:07.187413	\N
111	32	Kangundo	2024-08-02 15:09:07.187413	\N
112	32	Mwala	2024-08-02 15:09:07.187413	\N
113	31	Kibwezi West	2024-08-02 15:09:07.187413	\N
114	10	Ol Kalou	2024-08-02 15:09:07.187413	\N
115	31	Kaiti	2024-08-02 15:09:07.187413	\N
116	32	Machakos Town	2024-08-02 15:09:07.187413	\N
117	32	Masinga	2024-08-02 15:09:07.187413	\N
118	18	Limuru	2024-08-02 15:09:07.187413	\N
119	18	Kabete	2024-08-02 15:09:07.187413	\N
120	33	Ndia	2024-08-02 15:09:07.187413	\N
121	16	Gatanga	2024-08-02 15:09:07.187413	\N
122	18	Kiambu	2024-08-02 15:09:07.187413	\N
123	16	Mathioya	2024-08-02 15:09:07.187413	\N
124	18	Gatundu North	2024-08-02 15:09:07.187413	\N
125	18	Kikuyu	2024-08-02 15:09:07.187413	\N
126	33	Gichugu	2024-08-02 15:09:07.187413	\N
127	30	Nyeri Town	2024-08-02 15:09:07.187413	\N
128	16	Kangema	2024-08-02 15:09:07.187413	\N
129	16	Maragwa	2024-08-02 15:09:07.187413	\N
130	33	Kirinyaga Central	2024-08-02 15:09:07.187413	\N
131	18	Gatundu South	2024-08-02 15:09:07.187413	\N
132	33	Mwea	2024-08-02 15:09:07.187413	\N
133	18	Lari	2024-08-02 15:09:07.187413	\N
134	16	Kigumo	2024-08-02 15:09:07.187413	\N
135	18	Juja	2024-08-02 15:09:07.187413	\N
136	34	Turkana North	2024-08-02 15:09:07.187413	\N
137	18	Kiambaa	2024-08-02 15:09:07.187413	\N
138	18	Thika Town	2024-08-02 15:09:07.187413	\N
139	18	Githunguri	2024-08-02 15:09:07.187413	\N
140	35	Kwanza	2024-08-02 15:09:07.187413	\N
141	35	Kiminini	2024-08-02 15:09:07.187413	\N
142	36	Marakwet East	2024-08-02 15:09:07.187413	\N
143	35	Endebess	2024-08-02 15:09:07.187413	\N
144	13	Ainabkoi	2024-08-02 15:09:07.187413	\N
145	34	Turkana South	2024-08-02 15:09:07.187413	\N
146	37	Sigor	2024-08-02 15:09:07.187413	\N
147	11	Samburu East	2024-08-02 15:09:07.187413	\N
148	37	Kacheliba	2024-08-02 15:09:07.187413	\N
149	37	Kapenguria	2024-08-02 15:09:07.187413	\N
150	34	Turkana West	2024-08-02 15:09:07.187413	\N
151	11	Samburu North	2024-08-02 15:09:07.187413	\N
152	35	Cherangany	2024-08-02 15:09:07.187413	\N
153	34	Loima	2024-08-02 15:09:07.187413	\N
154	13	Kapseret	2024-08-02 15:09:07.187413	\N
155	37	Pokot South	2024-08-02 15:09:07.187413	\N
156	34	Turkana East	2024-08-02 15:09:07.187413	\N
157	35	Saboti	2024-08-02 15:09:07.187413	\N
158	13	Moiben	2024-08-02 15:09:07.187413	\N
159	38	Subukia	2024-08-02 15:09:07.187413	\N
160	13	Kesses	2024-08-02 15:09:07.187413	\N
161	34	Turkana Central	2024-08-02 15:09:07.187413	\N
162	36	Marakwet West	2024-08-02 15:09:07.187413	\N
163	12	Tinderet	2024-08-02 15:09:07.187413	\N
164	38	Kuresoi North	2024-08-02 15:09:07.187413	\N
165	38	Gilgil	2024-08-02 15:09:07.187413	\N
166	39	Baringo South	2024-08-02 15:09:07.187413	\N
167	12	Aldai	2024-08-02 15:09:07.187413	\N
168	38	Molo	2024-08-02 15:09:07.187413	\N
169	38	Njoro	2024-08-02 15:09:07.187413	\N
170	40	Laikipia East	2024-08-02 15:09:07.187413	\N
171	39	Baringo Central	2024-08-02 15:09:07.187413	\N
172	40	Laikipia North	2024-08-02 15:09:07.187413	\N
173	39	Eldama Ravine	2024-08-02 15:09:07.187413	\N
174	39	Tiaty	2024-08-02 15:09:07.187413	\N
175	36	Keiyo North	2024-08-02 15:09:07.187413	\N
176	12	Nandi Hills	2024-08-02 15:09:07.187413	\N
177	39	Mogotio	2024-08-02 15:09:07.187413	\N
178	39	Baringo  North	2024-08-02 15:09:07.187413	\N
179	38	Naivasha	2024-08-02 15:09:07.187413	\N
180	40	Laikipia West	2024-08-02 15:09:07.187413	\N
181	12	Mosop	2024-08-02 15:09:07.187413	\N
182	38	Kuresoi South	2024-08-02 15:09:07.187413	\N
183	36	Keiyo South	2024-08-02 15:09:07.187413	\N
184	41	Kipkelion West	2024-08-02 15:09:07.187413	\N
185	38	Rongai	2024-08-02 15:09:07.187413	\N
186	38	Nakuru Town West	2024-08-02 15:09:07.187413	\N
187	42	Chepalungu	2024-08-02 15:09:07.187413	\N
188	43	Kajiado Central	2024-08-02 15:09:07.187413	\N
189	9	Emurua Dikirr	2024-08-02 15:09:07.187413	\N
190	38	Nakuru Town East	2024-08-02 15:09:07.187413	\N
191	9	Narok West	2024-08-02 15:09:07.187413	\N
192	42	Bomet East	2024-08-02 15:09:07.187413	\N
193	43	Kajiado South	2024-08-02 15:09:07.187413	\N
194	43	Kajiado North	2024-08-02 15:09:07.187413	\N
195	43	Kajiado West	2024-08-02 15:09:07.187413	\N
196	9	Narok South	2024-08-02 15:09:07.187413	\N
197	38	Bahati	2024-08-02 15:09:07.187413	\N
198	41	Bureti	2024-08-02 15:09:07.187413	\N
199	9	Kilgoris	2024-08-02 15:09:07.187413	\N
200	41	Belgut	2024-08-02 15:09:07.187413	\N
201	41	Ainamoi	2024-08-02 15:09:07.187413	\N
202	41	Sigowet/Soin	2024-08-02 15:09:07.187413	\N
203	41	Kipkelion East	2024-08-02 15:09:07.187413	\N
204	43	Kajiado East	2024-08-02 15:09:07.187413	\N
205	42	Sotik	2024-08-02 15:09:07.187413	\N
206	8	Kabuchai	2024-08-02 15:09:07.187413	\N
207	15	Ikolomani	2024-08-02 15:09:07.187413	\N
208	15	Navakholo	2024-08-02 15:09:07.187413	\N
209	44	Luanda	2024-08-02 15:09:07.187413	\N
210	42	Konoin	2024-08-02 15:09:07.187413	\N
211	15	Butere	2024-08-02 15:09:07.187413	\N
212	15	Mumias East	2024-08-02 15:09:07.187413	\N
213	44	Emuhaya	2024-08-02 15:09:07.187413	\N
214	15	Lurambi	2024-08-02 15:09:07.187413	\N
215	44	Sabatia	2024-08-02 15:09:07.187413	\N
216	15	Mumias West	2024-08-02 15:09:07.187413	\N
217	8	Sirisia	2024-08-02 15:09:07.187413	\N
218	15	Matungu	2024-08-02 15:09:07.187413	\N
219	42	Bomet Central	2024-08-02 15:09:07.187413	\N
220	15	Shinyalu	2024-08-02 15:09:07.187413	\N
221	44	Vihiga	2024-08-02 15:09:07.187413	\N
222	44	Hamisi	2024-08-02 15:09:07.187413	\N
223	8	Mt.Elgon	2024-08-02 15:09:07.187413	\N
224	8	Bumula	2024-08-02 15:09:07.187413	\N
225	15	Likuyani	2024-08-02 15:09:07.187413	\N
226	15	Khwisero	2024-08-02 15:09:07.187413	\N
227	45	Muhoroni	2024-08-02 15:09:07.187413	\N
228	17	Rarieda	2024-08-02 15:09:07.187413	\N
229	17	Ugenya	2024-08-02 15:09:07.187413	\N
230	17	Bondo	2024-08-02 15:09:07.187413	\N
231	46	Funyula	2024-08-02 15:09:07.187413	\N
232	46	Butula	2024-08-02 15:09:07.187413	\N
233	17	Gem	2024-08-02 15:09:07.187413	\N
234	8	Tongaren	2024-08-02 15:09:07.187413	\N
235	46	Teso South	2024-08-02 15:09:07.187413	\N
236	46	Nambale	2024-08-02 15:09:07.187413	\N
237	46	Teso North	2024-08-02 15:09:07.187413	\N
238	45	Kisumu Central	2024-08-02 15:09:07.187413	\N
239	8	Webuye West	2024-08-02 15:09:07.187413	\N
240	45	Nyando	2024-08-02 15:09:07.187413	\N
241	46	Budalangi	2024-08-02 15:09:07.187413	\N
242	8	Webuye East	2024-08-02 15:09:07.187413	\N
243	8	Kimilili	2024-08-02 15:09:07.187413	\N
244	45	Kisumu East	2024-08-02 15:09:07.187413	\N
245	45	Kisumu West	2024-08-02 15:09:07.187413	\N
246	17	Ugunja	2024-08-02 15:09:07.187413	\N
247	45	Nyakach	2024-08-02 15:09:07.187413	\N
248	46	Matayos	2024-08-02 15:09:07.187413	\N
249	45	Seme	2024-08-02 15:09:07.187413	\N
250	47	Homa Bay Town	2024-08-02 15:09:07.187413	\N
251	47	Suba	2024-08-02 15:09:07.187413	\N
252	47	Kabondo Kasipul	2024-08-02 15:09:07.187413	\N
253	14	Awendo	2024-08-02 15:09:07.187413	\N
254	19	Nyaribari Masaba	2024-08-02 15:09:07.187413	\N
255	47	Mbita	2024-08-02 15:09:07.187413	\N
256	14	Rongo	2024-08-02 15:09:07.187413	\N
257	47	Ndhiwa	2024-08-02 15:09:07.187413	\N
258	14	Nyatike	2024-08-02 15:09:07.187413	\N
259	47	Rangwe	2024-08-02 15:09:07.187413	\N
260	14	Uriri	2024-08-02 15:09:07.187413	\N
261	19	Bonchari	2024-08-02 15:09:07.187413	\N
262	14	Kuria West	2024-08-02 15:09:07.187413	\N
263	19	Nyaribari Chache	2024-08-02 15:09:07.187413	\N
264	14	Suna East	2024-08-02 15:09:07.187413	\N
265	19	Bomachoge Chache	2024-08-02 15:09:07.187413	\N
266	19	South Mugirango	2024-08-02 15:09:07.187413	\N
267	47	Kasipul	2024-08-02 15:09:07.187413	\N
268	47	Karachuonyo	2024-08-02 15:09:07.187413	\N
269	19	Bomachoge Borabu	2024-08-02 15:09:07.187413	\N
270	2	Kamukunji	2024-08-02 15:09:07.187413	\N
271	2	Westlands	2024-08-02 15:09:07.187413	\N
272	2	Ruaraka	2024-08-02 15:09:07.187413	\N
273	20	North Mugirango	2024-08-02 15:09:07.187413	\N
274	2	Starehe	2024-08-02 15:09:07.187413	\N
275	2	Kasarani	2024-08-02 15:09:07.187413	\N
276	20	West Mugirango	2024-08-02 15:09:07.187413	\N
277	2	Embakasi North	2024-08-02 15:09:07.187413	\N
278	2	Makadara	2024-08-02 15:09:07.187413	\N
279	2	Embakasi East	2024-08-02 15:09:07.187413	\N
280	2	Dagoretti South	2024-08-02 15:09:07.187413	\N
281	2	Embakasi West	2024-08-02 15:09:07.187413	\N
282	2	Dagoretti North	2024-08-02 15:09:07.187413	\N
283	2	Roysambu	2024-08-02 15:09:07.187413	\N
284	19	Kitutu Chache North	2024-08-02 15:09:07.187413	\N
285	2	Embakasi South	2024-08-02 15:09:07.187413	\N
286	2	Mathare	2024-08-02 15:09:07.187413	\N
287	2	Langata	2024-08-02 15:09:07.187413	\N
288	20	Kitutu Masaba	2024-08-02 15:09:07.187413	\N
289	2	Kibra	2024-08-02 15:09:07.187413	\N
290	19	Kitutu Chache South	2024-08-02 15:09:07.187413	\N
\.


--
-- Data for Name: tbl_contact; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tbl_contact (cnt_id, area_id, cat_id, msisdn, first_name, last_name, username, password, email, auth_token, date_created, last_update) FROM stdin;
35	100	3	722348678	John	Doe		$2a$14$aFlbtoe8YPD05xh8mo6XbOpX2GjzZbQf7IrWAH1LNnalovsY0N4Lq	john.doe@example.com		0001-01-01 02:27:16+02:27:16	0001-01-01 02:27:16+02:27:16
\.


--
-- Data for Name: tbl_county; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tbl_county (cty_id, reg_id, code, name, date_created, last_update) FROM stdin;
1	1	1	Mombasa	2024-08-02 15:09:07.187413	\N
2	2	47	Nairobi	2024-08-02 15:09:07.187413	\N
3	1	6	Taita Taveta	2024-08-02 15:09:07.187413	\N
4	3	7	Garissa	2024-08-02 15:09:07.187413	\N
5	3	8	Wajir	2024-08-02 15:09:07.187413	\N
6	4	11	Isiolo	2024-08-02 15:09:07.187413	\N
7	4	12	Meru	2024-08-02 15:09:07.187413	\N
8	5	39	Bungoma	2024-08-02 15:09:07.187413	\N
9	6	33	Narok	2024-08-02 15:09:07.187413	\N
10	7	18	Nyandarua	2024-08-02 15:09:07.187413	\N
11	8	25	Samburu	2024-08-02 15:09:07.187413	\N
12	8	29	Nandi	2024-08-02 15:09:07.187413	\N
13	8	27	Uasin Gishu	2024-08-02 15:09:07.187413	\N
14	9	44	Migori	2024-08-02 15:09:07.187413	\N
15	5	37	Kakamega	2024-08-02 15:09:07.187413	\N
16	7	21	Muranga	2024-08-02 15:09:07.187413	\N
17	9	41	Siaya	2024-08-02 15:09:07.187413	\N
18	7	22	Kiambu	2024-08-02 15:09:07.187413	\N
19	9	45	Kisii	2024-08-02 15:09:07.187413	\N
20	9	46	Nyamira	2024-08-02 15:09:07.187413	\N
21	1	2	Kwale	2024-08-02 15:09:07.187413	\N
22	1	3	Kilifi	2024-08-02 15:09:07.187413	\N
23	1	4	Tana River	2024-08-02 15:09:07.187413	\N
24	1	5	Lamu	2024-08-02 15:09:07.187413	\N
25	3	9	Mandera	2024-08-02 15:09:07.187413	\N
26	4	10	Marsabit	2024-08-02 15:09:07.187413	\N
27	4	13	Tharaka-Nithi	2024-08-02 15:09:07.187413	\N
28	4	14	Embu	2024-08-02 15:09:07.187413	\N
29	4	15	Kitui	2024-08-02 15:09:07.187413	\N
30	7	19	Nyeri	2024-08-02 15:09:07.187413	\N
31	4	17	Makueni	2024-08-02 15:09:07.187413	\N
32	4	16	Machakos	2024-08-02 15:09:07.187413	\N
33	7	20	Kirinyaga	2024-08-02 15:09:07.187413	\N
34	8	23	Turkana	2024-08-02 15:09:07.187413	\N
35	8	26	Trans Nzoia	2024-08-02 15:09:07.187413	\N
36	8	28	Elgeyo Marakwet	2024-08-02 15:09:07.187413	\N
37	8	24	West Pokot	2024-08-02 15:09:07.187413	\N
38	6	32	Nakuru	2024-08-02 15:09:07.187413	\N
39	8	30	Baringo	2024-08-02 15:09:07.187413	\N
40	6	31	Laikipia	2024-08-02 15:09:07.187413	\N
41	6	35	Kericho	2024-08-02 15:09:07.187413	\N
42	6	36	Bomet	2024-08-02 15:09:07.187413	\N
43	6	34	Kajiado	2024-08-02 15:09:07.187413	\N
44	5	38	Vihiga	2024-08-02 15:09:07.187413	\N
45	9	42	Kisumu	2024-08-02 15:09:07.187413	\N
46	5	40	Busia	2024-08-02 15:09:07.187413	\N
47	9	43	Homa Bay	2024-08-02 15:09:07.187413	\N
\.



--
-- Data for Name: tbl_region; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tbl_region (reg_id, name, date_created, last_update) FROM stdin;
1	Coast	2024-08-02 15:09:07.187413	\N
2	Nairobi	2024-08-02 15:09:07.187413	\N
3	North Eastern	2024-08-02 15:09:07.187413	\N
4	Eastern	2024-08-02 15:09:07.187413	\N
5	Western	2024-08-02 15:09:07.187413	\N
6	South Rift	2024-08-02 15:09:07.187413	\N
7	Central	2024-08-02 15:09:07.187413	\N
8	North Rift	2024-08-02 15:09:07.187413	\N
9	Nyanza	2024-08-02 15:09:07.187413	\N
\.


--
-- Data for Name: tbl_category; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tbl_category (cat_id,parent_id, name, description, amount, date_created, last_update) FROM stdin;
1 0	Job Alerts	Job Ads	0	2024-08-11 23:24:06.708823+03	2024-08-11 23:28:17.133648+03
2 0	Red/Amber Alerts	Red/Amber Alerts	50	2024-08-11 23:24:06.708823+03	2024-08-11 23:28:47.155955+03
3 0	Seasonal Deals	Seasonal Deals	50	2024-08-11 23:24:06.708823+03	2024-08-11 23:28:47.155955+03
4 1	Employment Opportunity	Employment Opportunity	50	2024-08-11 23:24:06.708823+03	2024-08-11 23:28:47.155955+03
5 1	Tenders  Tenders  50	2024-08-11 23:24:06.708823+03	2024-08-11 23:28:47.155955+03


\.


--
-- Data for Name: tbl_ussd_sesions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tbl_ussd_sesions (session_id, msisdn, plan_payload, region_payload, county_payload, constituency_payload, area_payload, completed, date_created, last_update) FROM stdin;
\.


--
-- Name: tbl_area_area_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tbl_area_area_id_seq', 1, false);


--
-- Name: tbl_constituency_cst_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tbl_constituency_cst_id_seq', 290, true);


--
-- Name: tbl_contact_cnt_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tbl_contact_cnt_id_seq', 35, true);


--
-- Name: tbl_county_cty_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tbl_county_cty_id_seq', 47, true);


--
-- Name: tbl_region_reg_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tbl_region_reg_id_seq', 9, true);


--
-- Name: tbl_category_cat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tbl_category_cat_id_seq', 4, true);


--
-- Name: tbl_area tbl_area_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbl_area
    ADD CONSTRAINT tbl_area_pkey PRIMARY KEY (area_id);


--
-- Name: tbl_constituency tbl_constituency_cst_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbl_constituency
    ADD CONSTRAINT tbl_constituency_cst_id_key UNIQUE (cst_id);


--
-- Name: tbl_contact tbl_contact_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbl_contact
    ADD CONSTRAINT tbl_contact_pkey PRIMARY KEY (cnt_id);


--
-- Name: tbl_county tbl_county2_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbl_county
    ADD CONSTRAINT tbl_county2_pkey PRIMARY KEY (cty_id);


--
-- Name: tbl_region tbl_region_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbl_region
    ADD CONSTRAINT tbl_region_pkey PRIMARY KEY (reg_id);


--
-- Name: tbl_category tbl_category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbl_category
    ADD CONSTRAINT tbl_category_pkey PRIMARY KEY (cat_id);


--
-- Name: tbl_ussd_sesions tbl_ussd_sesions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbl_ussd_sesions
    ADD CONSTRAINT tbl_ussd_sesions_pkey PRIMARY KEY (session_id);


--
-- Name: tbl_contact uniq_msisdn; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbl_contact
    ADD CONSTRAINT uniq_msisdn UNIQUE (msisdn);


--
-- Name: tbl_region unique_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbl_region
    ADD CONSTRAINT unique_name UNIQUE (name);


--
-- Name: tbl_category_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tbl_category_name_idx ON public.tbl_category USING btree (name);


--
-- PostgreSQL database dump complete
--

