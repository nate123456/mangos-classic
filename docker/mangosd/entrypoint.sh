#!/bin/bash

# Initialize defaults
MYSQL_PORT=${MYSQL_PORT:-"3306"}
MYSQL_HOST=${MYSQL_HOST:-"127.0.0.1"}
MYSQL_USER=${MYSQL_USER:-"mangos"}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-"mangos"}
MYSQL_ROOT_USER=${MYSQL_ROOT_USER:-"root"}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-"mangos"}
MYSQL_CLASSIC_MANGOS_DB=${MYSQL_MANGOS_DB:-"classicmangos"}
MYSQL_CLASSIC_CHARS_DB=${MYSQL_CLASSIC_CHARS_DB:-"classiccharacters"}
MYSQL_CLASSIC_REALM_DB=${MYSQL_CLASSIC_REALM_DB:-"classicrealmd"}
RE_POPULATE=${RE_POPULATE:-true}
CONFIG_FILE="InstallFullDB.config"

# replace localhost with db as per docker-compose service name
cp -u /mangos/tmp/*.conf /mangos/etc/

# copy all conf files to mounted host config directory (does not overwrite)
cd /mangos/etc
sed -i "s|127.0.0.1;3306;mangos;mangos;|$MYSQL_HOST;$MYSQL_PORT;$MYSQL_USER;$MYSQL_PASSWORD;|g" *.conf

# save sql parameters to config file

cd /mangos/sql

echo "[client]" > my.cnf
echo "host=$MYSQL_HOST" >> my.cnf
echo "port=$MYSQL_PORT" >> my.cnf
echo "user=$MYSQL_ROOT_USER" >> my.cnf
echo "password=$MYSQL_ROOT_PASSWORD" >> my.cnf

# Wait for DB to start
while mysql --defaults-file=my.cnf -e 'SHOW DATABASES;' 2>&1 | grep -q -io 'ERROR'
do
    echo "Unable to connect to database. Waiting for connection."
    sleep 10
done

echo "Connected to database. Proceeding."

run_sql_file() {
    FILE=$1
    DB="${2:-}"
    # -p -s -r -N
    sed -i "s/mangos'@'localhost/$MYSQL_USER'@'%/g" $FILE
    sed -i "s/'mangos'@'localhost' IDENTIFIED BY 'mangos';/'mangos'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';/g" $FILE
    sed -i "s/classicmangos;/$MYSQL_CLASSIC_MANGOS_DB;/g" $FILE
    sed -i "s/classiccharacters;/$MYSQL_CLASSIC_CHARS_DB;/g" $FILE
    sed -i "s/classicrealmd;/$MYSQL_CLASSIC_REALM_DB;/g" $FILE
    
    echo "Executing $FILE"
    mysql --defaults-file=my.cnf --database="$DB" < $FILE
}

if ! mysql --defaults-file=my.cnf  -e 'SHOW DATABASES;' | grep -q -io $MYSQL_CLASSIC_MANGOS_DB; then
    echo "Data structure is not present. Initializing data structure."
    
    # fix error in newer MYSQL versions.
    mysql --defaults-file=my.cnf -e "SET SQL_REQUIRE_PRIMARY_KEY = OFF;"
    
    run_sql_file "/mangos/sql/create/db_create_mysql.sql"
    run_sql_file "/mangos/sql/base/mangos.sql" $MYSQL_CLASSIC_MANGOS_DB
    
    for f in /mangos/sql/base/dbc/original_data/*.sql; do
        run_sql_file $f $MYSQL_CLASSIC_MANGOS_DB
    done
    
    for f in /mangos/sql/base/dbc/cmangos_fixes/*.sql; do
        run_sql_file $f $MYSQL_CLASSIC_MANGOS_DB
    done
    
    run_sql_file "/mangos/sql/base/characters.sql" $MYSQL_CLASSIC_CHARS_DB
    run_sql_file "/mangos/sql/base/realmd.sql" $MYSQL_CLASSIC_REALM_DB
fi

if [ "$RE_POPULATE" = true ] ; then
    echo 'Repopulation of world data is enabled. Repopulating.'
    cd /mangos/db
    
    cat > $CONFIG_FILE << EOF
DB_HOST=$MYSQL_HOST
DB_PORT=$MYSQL_PORT
DATABASE=$MYSQL_CLASSIC_MANGOS_DB
USERNAME=$MYSQL_USER
PASSWORD=$MYSQL_PASSWORD
CORE_PATH=../
MYSQL="mysql"
FORCE_WAIT="NO"
DEV_UPDATES="NO"
AHBOT="YES"
EOF
    echo "Running installer script."
    ./InstallFullDB.sh
fi

echo "Setup finished. Running server."

for i in {1..10}
do
    echo -ne .
    sleep 1
done
echo .

# Run realmd
cd /mangos/bin
/mangos/bin/mangosd