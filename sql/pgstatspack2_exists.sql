SELECT COUNT(tablename)
FROM pg_tables
WHERE schemaname='pgstatspack2'
AND tablename IN (
      'pgstatspack2_snap'
    , 'pgstatspack2_database'
    , 'pgstatspack2_tables'
    , 'pgstatspack2_indexes'
    , 'pgstatspack2_sequences'
    , 'pgstatspack2_settings'
    , 'pgstatspack2_version'
    , 'pgstatspack2_statements'
);
