#!/bin/bash

#db call to get database name

PSQL="psql -q"

pushd `dirname $0` > /dev/null

txt='cron based snapshot'

for dbname in `$PSQL -d postgres -t -f "../sql/get_db_names.sql" `
do
	echo "Results for database ${dbname}"
	$PSQL -d "${dbname}" -c "select pgstatspack2.pgstatspack2_snap('$txt');"
	echo ""
	echo ""
done 

popd > /dev/null
