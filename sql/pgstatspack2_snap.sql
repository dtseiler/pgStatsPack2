SET client_min_messages TO error;
--
-- Create pgstatspack2_snap procedure.
--
-- By frits.hoogland@interaccess.nl
-- Based on Glenn.Fawcett@Sun.com's snap procedure
--

SET search_path TO pgstatspack2,public;

CREATE OR REPLACE FUNCTION pgstatspack2_snap ( description varchar(256) ) RETURNS bigint AS $$
DECLARE
  now_dts TIMESTAMP;
  spid BIGINT;
  version_major int;
  version_minor int;
BEGIN
    SELECT current_timestamp INTO now_dts; 
    SELECT nextval('pgstatspackid') INTO spid;
    INSERT INTO pgstatspack2_snap VALUES (spid, now_dts, description);

    INSERT INTO pgstatspack2_names (name)
        SELECT DISTINCT datname
        FROM pg_database
            LEFT JOIN pgstatspack2_names ON datname=name
        WHERE name IS NULL;

    INSERT INTO pgstatspack2_database
        (snapid, datid, numbackends, xact_commit, xact_rollback, blks_read, blks_hit, dbnameid)
    SELECT
        spid            AS snapid,
        d.datid         AS datid,
        d.numbackends   AS numbackends,
        d.xact_commit   AS xact_commit,
        d.xact_rollback AS xact_rollback,
        d.blks_read     AS blks_read,
        d.blks_hit      AS blks_hit,
        n.nameid
    FROM pg_stat_database d
        JOIN pgstatspack2_names n ON d.datname=n.name;

    INSERT INTO pgstatspack2_names (name)
        SELECT DISTINCT schemaname||'.'||relname
        FROM pg_stat_all_tables
            LEFT JOIN pgstatspack2_names ON schemaname||'.'||relname=name
        WHERE name IS NULL;

    INSERT INTO pgstatspack2_tables
        (snapid, seq_scan, seq_tup_read, idx_scan, idx_tup_fetch, n_tup_ins, 
            n_tup_upd, n_tup_del, heap_blks_read, heap_blks_hit, idx_blks_read, 
            idx_blks_hit, toast_blks_read, toast_blks_hit, tidx_blks_read, 
            tidx_blks_hit, tbl_size, idx_size, table_name_id)
    SELECT
        spid               AS snapid,
        t.seq_scan         AS seq_scan,
        t.seq_tup_read     AS seq_tup_read,
        t.idx_scan         AS idx_scan,
        t.idx_tup_fetch    AS idx_tup_fetch,
        t.n_tup_ins        AS n_tup_ins,
        t.n_tup_upd        AS n_tup_upd,
        t.n_tup_del        AS n_tup_del,
        it.heap_blks_read  AS heap_blks_read,
        it.heap_blks_hit   AS heap_blks_hit,
        it.idx_blks_read   AS idx_blks_read,
        it.idx_blks_hit    AS idx_blks_hit,
        it.toast_blks_read AS toast_blks_read,
        it.toast_blks_hit  AS toast_blks_hit,
        it.tidx_blks_read  AS tidx_blks_read,
        it.tidx_blks_hit   AS tidx_blks_hit,
        pg_relation_size(t.relid)+pg_relation_size(s.relid) AS tbl_size,
        sum(pg_relation_size(i.indexrelid)) AS idx_size,
        n.nameid
    FROM
        pg_statio_all_tables it,
        pg_stat_all_tables t
    JOIN pg_class c ON t.relid=c.oid
        LEFT JOIN pg_stat_sys_tables s ON c.reltoastrelid=s.relid 
        LEFT JOIN pg_index i ON i.indrelid=t.relid
        LEFT JOIN pg_locks l ON c.oid=l.relation AND locktype='relation' 
            AND mode IN ('AccessExclusiveLock','ShareRowExclusiveLock','ShareLock','ShareUpdateExclusiveLock')
        JOIN pgstatspack2_names n ON t.schemaname ||'.'|| t.relname=n.name
    WHERE l.relation IS NULL AND (t.relid = it.relid)
    GROUP BY
        n.nameid,t.seq_scan,t.seq_tup_read,t.idx_scan,t.idx_tup_fetch,t.n_tup_ins,t.n_tup_upd,t.n_tup_del,
        it.heap_blks_read,it.heap_blks_hit,it.idx_blks_read,it.idx_blks_hit,it.toast_blks_read,
        it.toast_blks_hit,it.tidx_blks_read,it.tidx_blks_hit,t.relid,s.relid
    ;

    INSERT INTO pgstatspack2_names (name)
        SELECT DISTINCT i.schemaname ||'.'|| i.indexrelname
        FROM pg_stat_all_indexes i
            LEFT JOIN pgstatspack2_names ON i.schemaname ||'.'|| i.indexrelname=name
        WHERE name IS NULL;

    INSERT INTO pgstatspack2_indexes
        ( snapid, idx_scan, idx_tup_read, idx_tup_fetch, idx_blks_read, 
        idx_blks_hit, index_name_id, table_name_id)
    SELECT
        spid               AS snapid,
        i.idx_scan         AS idx_scan,
        i.idx_tup_read     AS idx_tup_read,
        i.idx_tup_fetch    AS idx_tup_fetch,
        ii.idx_blks_read   AS idx_blks_read,
        ii.idx_blks_hit    AS idx_blks_hit,
        n1.nameid,
        n2.nameid
    FROM pg_stat_all_indexes i
        JOIN pg_statio_all_indexes ii ON i.indexrelid = ii.indexrelid
        JOIN pgstatspack2_names n1 ON i.schemaname ||'.'|| i.indexrelname=n1.name
        JOIN pgstatspack2_names n2 ON i.schemaname ||'.'|| i.relname=n2.name
    ;

    INSERT INTO pgstatspack2_names (name)
        SELECT DISTINCT s.schemaname ||'.'|| s.relname
        FROM pg_statio_all_sequences s
            LEFT JOIN pgstatspack2_names ON s.schemaname ||'.'|| s.relname=name
        WHERE name IS NULL;

    INSERT INTO pgstatspack2_sequences
        ( snapid, seq_blks_read, seq_blks_hit, sequence_name_id)
    SELECT
        spid               AS snapid,
        s.blks_read        AS seq_blks_read,
        s.blks_hit         AS seq_blks_hit,
        n.nameid
    FROM pg_statio_all_sequences s
        JOIN pgstatspack2_names n ON s.schemaname ||'.'|| s.relname=n.name
    ;

    INSERT INTO pgstatspack2_names (name)
        SELECT DISTINCT s.name
        FROM pg_settings s
            LEFT JOIN pgstatspack2_names n ON n.name=s.name
        WHERE source!='default' AND n.name is null;

    INSERT INTO pgstatspack2_names (name)
        SELECT DISTINCT s.setting
        FROM pg_settings s
            LEFT JOIN pgstatspack2_names n ON n.name=s.setting
        WHERE source!='default' AND n.name IS NULL;

    INSERT INTO pgstatspack2_names (name)
        SELECT DISTINCT s.source
        FROM PG_SETTINGS s
            LEFT JOIN pgstatspack2_names n ON n.name=s.source
        WHERE source!='default' AND n.name is null;

    INSERT INTO pgstatspack2_settings
        ( snapid, name_id, setting_id, source_id)
    SELECT
        spid			AS snapid,
        n1.nameid,
        n2.nameid,
        n3.nameid
    FROM pg_settings s
        JOIN pgstatspack2_names n1 ON s.name=n1.name
        JOIN pgstatspack2_names n2 ON s.setting=n2.name
        JOIN pgstatspack2_names n3 ON s.source=n3.name
    WHERE s.source != 'default'
    ;

    SELECT CAST(SUBSTRING(version(), 'PostgreSQL ([0-9]*).') AS int) INTO version_major;
    SELECT CAST(SUBSTRING(version(), 'PostgreSQL [0-9]*.([0-9]*).') AS int) INTO version_minor;

    IF ((version_major = 8 AND version_minor >= 4 ) OR version_major > 8 ) THEN
        BEGIN
            PERFORM relname FROM pg_class WHERE relname='pg_stat_statements';
            IF FOUND THEN
                BEGIN

                    INSERT INTO pgstatspack2_names (name)
                    SELECT DISTINCT query
                    FROM pg_stat_statements
                        LEFT JOIN pgstatspack2_names ON query=name
                    WHERE dbid=(select oid FROM pg_database WHERE datname=current_database()) 
                    AND name IS NULL;

                    INSERT INTO pgstatspack2_names (name)
                    SELECT pg_get_userbyid(userid)
                    FROM pg_stat_statements
                        LEFT JOIN pgstatspack2_names ON pg_get_userbyid(userid)=name
                    WHERE dbid=(select oid FROM pg_database WHERE datname=current_database()) 
                    AND name IS NULL;

                    INSERT INTO pgstatspack2_statements
                        ( snapid, calls, total_time, "rows", query_id, user_name_id)
                    SELECT
                        spid AS snapid,
                        s.calls AS calls,
                        s.total_time AS total_time,
                        s.rows AS rows,
                        n1.nameid,
                        n2.nameid
                    FROM pg_stat_statements s
                        JOIN pgstatspack2_names n1 ON s.query=n.name
                        JOIN pgstatspack2_names n2 ON s.pg_get_userbyid(s.userid)=n2.name
                    WHERE dbid=(select oid FROM pg_database WHERE datname=current_database())
                    ORDER BY total_time;

                EXCEPTION WHEN object_not_in_prerequisite_state THEN raise warning '%', SQLERRM;
                END;
            END IF;
        END; 
    END IF;

    IF ((version_major = 8 AND version_minor >= 4 ) OR version_major > 8 ) THEN
        BEGIN

            INSERT INTO pgstatspack2_names (name)
            SELECT schemaname||'.'||funcname
            FROM pg_stat_user_functions
                LEFT JOIN pgstatspack2_names ON schemaname||'.'||funcname=name
            WHERE name IS NULL;

            INSERT INTO pgstatspack2_functions
                ( snapid, funcid, calls, total_time, self_time, function_name_id)
            SELECT
                spid AS snapid,
                funcid AS funcid,
                calls AS calls,
                total_time AS total_time,
                self_time AS self_time,
                n.nameid
            FROM pg_stat_user_functions
                JOIN pgstatspack2_names n ON schemaname||'.'||funcname=n.name
            ORDER BY total_time
            LIMIT 100;
        END;
    END IF;

    IF ((version_major = 8 AND version_minor >= 3 ) OR version_major > 8 ) THEN
	    INSERT INTO pgstatspack2_bgwriter 
        SELECT
	        spid AS snapid,
	        checkpoints_timed,
	        checkpoints_req,
	        buffers_checkpoint,
	        buffers_clean,
	        maxwritten_clean,
	        buffers_backend,
	        buffers_alloc
	    FROM pg_stat_bgwriter;
    END IF;

    RETURN spid;
END;
$$ LANGUAGE plpgsql;

