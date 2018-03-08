#!/bin/bash

#db call to get database name

PSQL="psql -qX --set ON_ERROR_STOP=on"

install_stats () {
        set -e
        # Create Schema and Tables
        $PSQL -d "${dbname}" -f "sql/pgstatspack2_create_schema.sql"
        $PSQL -d "${dbname}" -f "sql/pgstatspack2_create_tables.sql"
        # Create Functions
        $PSQL -d "${dbname}" -f "sql/pgstatspack2_snap.sql"
        $PSQL -d "${dbname}" -f "sql/pgstatspack2_delete_snap.sql"
        $PSQL -d "${dbname}" -f "sql/pgstatspack2_get_unused_indexes.sql"
        set +e
}

for dbname in $($PSQL -d postgres -t -f "sql/get_db_names.sql")
do
        echo "Results for database ${dbname}"
        if [ $($PSQL -d "${dbname}" -t -c "select count(lanname) from pg_language where lanname='plpgsql';") -lt 1 ]
        then
                echo "Installing language plpgsql for database ${dbname}"
                $PSQL -d "${dbname}" -c "create language plpgsql;"
        fi
        x=$($PSQL -tA  -d "${dbname}" -f "sql/pgstatspack2_exists.sql")
        if [ $x -eq "0" ]
        then
                echo "Installing Statistics Package for database ${dbname}"
                install_stats
        elif [ $x -lt "8" ]
        then
                echo "Previous install of statisics package was incomplete. Reinstalling Stats for database ${dbname}"
                install_stats
        else
                echo "Statistics package already exists for database: ${dbname}"
        fi
        x=0
done
