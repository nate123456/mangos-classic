#!/bin/bash

# Initialize defaults
MYSQL_PORT=${MYSQL_PORT:-"3306"}
MYSQL_HOST=${MYSQL_HOST:-"127.0.0.1"}
MYSQL_USER=${MYSQL_USER:-"mangos"}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-"mangos"}
MYSQL_CLASSIC_REALM_DB=${MYSQL_CLASSIC_REALM_DB:-"classicrealmd"}
REALM_NAME=${REALM_NAME:-"CMangos Classic"}
REALM_HOST=${REALM_HOST:-"127.0.0.1"}

# replace localhost with db as per docker-compose service name
cd /mangos/tmp
sed -i "s|127.0.0.1;3306;mangos;mangos;classicrealmd|$MYSQL_HOST;$MYSQL_PORT;$MYSQL_USER;$MYSQL_PASSWORD;$MYSQL_CLASSIC_REALM_DB|g" *.conf

# copy all conf files to mounted host config directory (does not overwrite)
cp -u *.conf /mangos/etc/

echo "[client]" > my.cnf
echo "host=$MYSQL_HOST" >> my.cnf
echo "port=$MYSQL_PORT" >> my.cnf
echo "user=$MYSQL_USER" >> my.cnf
echo "password=$MYSQL_PASSWORD" >> my.cnf

# Wait for DB to start and contain realm db
while ! mysql --defaults-file=my.cnf -e 'SHOW DATABASES;' 2>&1 | grep -q -io $MYSQL_CLASSIC_REALM_DB;
do
    echo "Unable to connect to database. Waiting for connection."
    sleep 10;
done

echo "Database is ready. Proceeding.";

# Run realmd
/mangos/bin/realmd