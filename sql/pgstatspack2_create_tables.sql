SET client_min_messages TO error;
-- Create pgstatspack schema tables.	
--
-- By frits.hoogland@interaccess.nl
-- Based on Glenn.Fawcett@Sun.com's snap procedure
--

SET search_path TO pgstatspack2;

DROP TABLE if exists pgstatspack2_snap;
CREATE TABLE pgstatspack2_snap
(
    snapid      bigint,
    ts          timestamp,
    description varchar(255)
);

DROP TABLE if exists pgstatspack2_database;
CREATE TABLE pgstatspack2_database
(
  snapid        bigint NOT NULL,
  datid         oid NOT NULL,
  dbnameid      int NOT NULL,
  numbackends   integer,
  xact_commit   bigint,
  xact_rollback bigint,
  blks_read     bigint,
  blks_hit      bigint,
  datname_id    integer,
  CONSTRAINT    pgstatspack2_database_pk PRIMARY KEY (snapid, datid)
);

DROP TABLE if exists pgstatspack2_tables;
CREATE TABLE pgstatspack2_tables
(
  snapid            bigint NOT NULL,
  table_name_id     integer,
  seq_scan          bigint,
  seq_tup_read      bigint,
  idx_scan          bigint,
  idx_tup_fetch     bigint,
  n_tup_ins         bigint,
  n_tup_upd         bigint,
  n_tup_del         bigint,
  heap_blks_read    bigint,
  heap_blks_hit     bigint,
  idx_blks_read     bigint,
  idx_blks_hit      bigint,
  toast_blks_read   bigint,
  toast_blks_hit    bigint,
  tidx_blks_read    bigint,
  tidx_blks_hit     bigint,
  tbl_size          bigint,
  idx_size          bigint,
  CONSTRAINT pgstatspack2_tables_pk PRIMARY KEY (snapid, table_name_id)
);

DROP TABLE if exists pgstatspack2_indexes;
CREATE TABLE pgstatspack2_indexes
(
  snapid            bigint NOT NULL,
  index_name_id     integer,
  table_name_id     integer,
  idx_scan          bigint,
  idx_tup_read      bigint,
  idx_tup_fetch     bigint,
  idx_blks_read     bigint,
  idx_blks_hit      bigint,
  CONSTRAINT pgstatspack2_indexes_pk PRIMARY KEY (snapid, index_name_id, table_name_id)
);

DROP TABLE if exists pgstatspack2_sequences;
CREATE TABLE pgstatspack2_sequences
(
  snapid bigint     NOT NULL,
  sequence_name_id  integer,
  seq_blks_read     bigint,
  seq_blks_hit      bigint,
  CONSTRAINT pgstatspack2_sequences_pk PRIMARY KEY (snapid, sequence_name_id)
);

DROP TABLE if exists pgstatspack2_settings;
CREATE TABLE pgstatspack2_settings
(
  snapid            bigint,
  name_id           int,
  setting_id        int,
  source_id         int,
  CONSTRAINT pgstatspack2_settings_pk PRIMARY KEY (snapid, name_id)
);

CREATE TABLE pgstatspack2_statements
(
  snapid            bigint NOT NULL,
  user_name_id      integer,
  query_id          integer,
  calls             bigint,
  total_time        double precision,
  "rows"            bigint,
  CONSTRAINT pgstatspack2_statements_pk PRIMARY KEY (snapid, user_name_id, query_id)
);

CREATE TABLE pgstatspack2_functions
(
  snapid            bigint NOT NULL,
  funcid            oid NOT NULL,
  function_name_id  integer,
  calls             bigint,
  total_time        bigint,
  self_time         bigint,
  CONSTRAINT pgstatspack2_functions_pk PRIMARY KEY (snapid, funcid)
);

create table pgstatspack2_bgwriter
(
  snapid                bigint NOT NULL,
  checkpoints_timed     bigint,
  checkpoints_req       bigint,
  buffers_checkpoint    bigint,
  buffers_clean         bigint,
  maxwritten_clean      bigint,
  buffers_backend       bigint,
  buffers_alloc         bigint,
  CONSTRAINT pgstatspack2_bgwriter_pk PRIMARY KEY (snapid)
);

CREATE SEQUENCE pgstatspacknameid
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 2147483647
  START 1
  CACHE 1;

CREATE TABLE pgstatspack2_names(
  nameid    integer NOT NULL DEFAULT nextval('pgstatspacknameid'::text),
  name      text,
  CONSTRAINT pgstatspack2_names_pkey PRIMARY KEY (nameid)
);
CREATE UNIQUE INDEX idx_pgstatspack2_names_name ON pgstatspack2_names(name);

CREATE TABLE pgstatspack2_version
(
  version VARCHAR(10)
);

DROP SEQUENCE IF EXISTS pgstatspackid;
CREATE SEQUENCE pgstatspackid;

CREATE OR REPLACE VIEW pgstatspack2_database_v AS 
    SELECT snapid, datid, name AS datname, numbackends, xact_commit, xact_rollback, blks_read, blks_hit
    FROM pgstatspack2_database
    JOIN pgstatspack2_names ON nameid = dbnameid;

CREATE OR REPLACE VIEW pgstatspack2_tables_v AS
    SELECT snapid, name AS table_name, seq_scan, seq_tup_read, idx_scan, idx_tup_fetch, n_tup_ins, 
       n_tup_upd, n_tup_del, heap_blks_read, heap_blks_hit, idx_blks_read, 
       idx_blks_hit, toast_blks_read, toast_blks_hit, tidx_blks_read, 
       tidx_blks_hit, tbl_size, idx_size
    FROM pgstatspack2_tables
        JOIN pgstatspack2_names ON nameid=table_name_id;

CREATE VIEW pgstatspack2_indexes_v AS
    SELECT snapid, n1.name AS index_name, n2.name AS table_name, idx_scan, idx_tup_read, 
       idx_tup_fetch, idx_blks_read, idx_blks_hit
    FROM pgstatspack2_indexes
        JOIN pgstatspack2_names n1 ON n1.nameid=index_name_id
        JOIN pgstatspack2_names n2 ON n2.nameid=table_name_id;

CREATE VIEW pgstatspack2_sequences_v AS
    SELECT snapid, name AS sequence_name, seq_blks_read, seq_blks_hit
    FROM pgstatspack2_sequences
    JOIN pgstatspack2_names ON nameid=sequence_name_id;

CREATE VIEW pgstatspack2_settings_v AS
    SELECT snapid, n1.name AS name, n2.name AS setting, n3.name AS source
    FROM pgstatspack2_settings
        JOIN pgstatspack2_names n1 ON n1.nameid=name_id
        JOIN pgstatspack2_names n2 ON n2.nameid=setting_id
        JOIN pgstatspack2_names n3 ON n3.nameid=source_id;

CREATE VIEW pgstatspack2_statements_v AS
    SELECT snapid, n1.name AS user_name, n2.name AS query, calls, total_time, "rows"
    FROM pgstatspack2_statements
        JOIN pgstatspack2_names n1 ON n1.nameid=user_name_id
        JOIN pgstatspack2_names n2 ON n2.nameid=query_id;

CREATE VIEW pgstatspack2_functions_v AS
    SELECT snapid, funcid, n1.name AS function_name, calls, total_time, self_time
    FROM pgstatspack2_functions
        JOIN pgstatspack2_names n1 ON n1.nameid=function_name_id;

INSERT INTO pgstatspack2_version VALUES('0.1.0');
