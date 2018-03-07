SELECT COUNT(tablename)
FROM pg_tables
WHERE schemaname='pgstatspack2'
AND tablename IN (
      'pgstatspack_snap'
    , 'pgstatspack_database'
    , 'pgstatspack_tables'
    , 'pgstatspack_indexes'
    , 'pgstatspack_sequences'
    , 'pgstatspack_settings'
    , 'pgstatspack_version'
    , 'pgstatspack_statements'
);
