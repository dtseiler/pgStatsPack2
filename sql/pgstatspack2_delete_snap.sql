SET client_min_messages TO error;
-- Create pgstatspack2_delete_snap procedure.
--
-- By frits.hoogland@interaccess.nl
-- Based on Glenn.Fawcett@Sun.com's snap procedure
--

SET search_path TO pgstatspack2,public;

CREATE OR REPLACE FUNCTION pgstatspack2_delete_snap () returns varchar(512) AS $$
DECLARE
    old_snap_time TIMESTAMP;
    old_snap_id BIGINT;
    message VARCHAR(512);
BEGIN
    SELECT current_timestamp - interval '30 days' INTO old_snap_time;

    SELECT max(snapid) INTO old_snap_id FROM pgstatspack2.pgstatspack2_snap WHERE ts < old_snap_time;

    SELECT 'Deleted '||count(snapid)||' snapshots older than '||old_snap_time
    INTO message 
    FROM pgstatspack2.pgstatspack2_snap 
    WHERE snapid <= old_snap_id;

    DELETE FROM pgstatspack2.pgstatspack2_snap WHERE snapid <= old_snap_id;
    DELETE FROM pgstatspack2.pgstatspack2_database WHERE snapid <= old_snap_id;
    DELETE FROM pgstatspack2.pgstatspack2_tables WHERE snapid <= old_snap_id;
    DELETE FROM pgstatspack2.pgstatspack2_indexes WHERE snapid <= old_snap_id;
    DELETE FROM pgstatspack2.pgstatspack2_sequences WHERE snapid <= old_snap_id;
    DELETE FROM pgstatspack2.pgstatspack2_settings WHERE snapid <= old_snap_id;
    DELETE FROM pgstatspack2.pgstatspack2_statements WHERE snapid <= old_snap_id;
    DELETE FROM pgstatspack2.pgstatspack2_bgwriter WHERE snapid <= old_snap_id;

    RETURN message;
END;
$$ LANGUAGE plpgsql;

