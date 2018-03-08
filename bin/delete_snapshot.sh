#!/bin/bash

#db call to get database name

PSQL="psql -q"

pushd `dirname $0`

for dbname in `$PSQL -d postgres -t -f "../sql/get_db_names.sql"`
do
	echo "Results for database ${dbname}"
	$PSQL -d "${dbname}" -c "select pgstatspack2.pgstatspack2_delete_snap ();"
	echo ""
	echo ""
done 
popd
