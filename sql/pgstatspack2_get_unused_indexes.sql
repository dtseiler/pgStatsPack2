SET client_min_messages TO error;
-- Function: pgstatspack2_get_unused_indexes(interval)

SET search_path TO pgstatspack2,public;

DROP FUNCTION if exists pgstatspack2_get_unused_indexes(interval);

CREATE OR REPLACE FUNCTION pgstatspack2_get_unused_indexes(IN p_timespan interval)
    RETURNS TABLE(table_name text, index_name text, size text, indexdef text) AS
$BODY$
DECLARE
    l_max_ts timestamp;
    l_snapid_start integer;
    l_snapid_stop integer;
    l_timespan interval := '1 week'; -- default
BEGIN
    -- this function returns the name of the unused indexes and their corresponding table name.
    -- author: ubartels
    -- date: 26/10/2010
    --
    -- prerequsites: pgstatspack2
 
    IF p_timespan IS NOT NULL THEN
        l_timespan = p_timespan;
    END IF;
 
    l_max_ts := MAX(ts) FROM pgstatspack2.pgstatspack2_snap;
    l_snapid_stop  := snapid FROM pgstatspack2.pgstatspack2_snap WHERE ts=l_max_ts;
    l_snapid_start := snapid FROM pgstatspack2.pgstatspack2_snap WHERE ts > l_max_ts - l_timespan ORDER BY ts ASC LIMIT 1;

    -- check if there is any data
    IF l_snapid_start IS NULL OR l_snapid_stop IS NULL THEN
        raise info 'no data found for the timespan of %.',l_timespan;
        RETURN;
    END IF;

    -- check if the stats are active or stale
    IF l_max_ts < now()-'1 day'::interval THEN
        raise info 'pgstatspack data is stale (older than 1 day). please get it up and running first.';
        RETURN;
    END IF;

    RETURN query
    SELECT a.table_name::text, a.index_name::text ,pg_size_pretty(pg_relation_size(c.oid))::text, pg_get_indexdef(c.oid)::text
    FROM pg_class c, pg_namespace n, pg_index i, pgstatspack2.pgstatspack2_indexes a, pgstatspack2.pgstatspack2_indexes b
    WHERE
        a.snapid=l_snapid_start AND 
        b.snapid=l_snapid_stop AND
        a.index_name=b.index_name AND
        a.table_name=b.table_name AND
        (b.idx_scan-a.idx_scan) = 0 AND
        (b.idx_tup_read-a.idx_tup_read) = 0 AND
        (b.idx_tup_fetch-a.idx_tup_fetch) = 0 AND
        a.index_name=n.nspname||'.'||c.relname AND
        n.oid=c.relnamespace AND
        c.oid=i.indexrelid AND
        i.indisprimary IS FALSE AND
        i.indisunique IS FALSE AND
        i.indisclustered IS FALSE AND
        a.index_name not in (SELECT n.nspname||'.'||conname FROM pg_constraint WHERE contype='f')
    ORDER BY pg_relation_size(c.oid) DESC;

END;
$BODY$
    LANGUAGE 'plpgsql' VOLATILE SECURITY DEFINER
    COST 100
    ROWS 1000;
