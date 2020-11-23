#!/bin/bash

# Initialize defaults
MYSQL_PORT=${MYSQL_PORT:-"3306"}
MYSQL_HOST=${MYSQL_HOST:-"127.0.0.1"}
MYSQL_USER=${MYSQL_USER:-"mangos"}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-"mangos"}
MYSQL_CLASSIC_REALM_DB=${MYSQL_CLASSIC_REALM_DB:-"classicrealmd"}
REALM_NAME=${REALM_NAME:-"CMangos Classic"}
REALM_HOST=${REALM_HOST:-"127.0.0.1"}
REALM_PORT=${REALM_PORT:-"8085"}
REALM_ICON=${REALM_ICON:-"1"}
REALM_FLAGS=${REALM_FLAGS:-"0"}
REALM_TIMEZONE=${REALM_TIMEZONE:-"1"}
REALM_ALLOWED_SEC_LEVEL=${REALM_ALLOWED_SEC_LEVEL:-"0"}

# replace localhost with db as per docker-compose service name
cd /mangos/tmp
sed -i "s|127.0.0.1;3306;mangos;mangos;classicrealmd|$MYSQL_HOST;$MYSQL_PORT;$MYSQL_USER;$MYSQL_PASSWORD;$MYSQL_CLASSIC_REALM_DB|g" *.conf

# copy all conf files to mounted host config directory
cp *.conf /mangos/etc/

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

echo "Database is ready. Updating realmlist.";

mysql --defaults-file=my.cnf -e "DELETE FROM $MYSQL_CLASSIC_REALM_DB.realmlist WHERE id=1;"
mysql --defaults-file=my.cnf -e "INSERT INTO $MYSQL_CLASSIC_REALM_DB.realmlist (id, name, address, port, icon, realmflags, timezone, allowedSecurityLevel) VALUES ('1', '$REALM_NAME', '$REALM_HOST', '$REALM_PORT', '$REALM_ICON', '$REALM_FLAGS', '$REALM_TIMEZONE', '$REALM_ALLOWED_SEC_LEVEL');"

echo "Realmliist updated. Proceeding.";

# Run realmd
/mangos/bin/realmd