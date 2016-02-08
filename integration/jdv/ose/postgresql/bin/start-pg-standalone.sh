#!/bin/bash
#
# script that starts postgres in a Kube/Openshift environment
# in a standalone configuration
#
source /cluster/bin/setenv.sh
/cluster/bin/initdb.sh > /tmp/initdb.log
echo "PG_USERNAME=" $PG_USERNAME > /tmp/envvars.log
echo "PG_PASSWORD=" $PG_PASSWORD >> /tmp/envvars.log
echo "host all all 0.0.0.0/0 md5" >> /pgdata/pg_hba.conf
echo "listen_addresses = '*'" >> /pgdata/postgresql.conf
echo "port = 5432" >> /pgdata/postgresql.conf

env >> /tmp/envvars.log
pg_ctl -w -D /pgdata start 2> /tmp/startpg.err > /tmp/startpg.log
#
# this will create a database with the same name as the PG_USERNAME
echo create database $PG_USERNAME > /tmp/createdb-string
psql -U postgres postgres < /tmp/createdb-string
#
# this will create a new user role with the same name as the PG_USERNAME
echo create role $PG_USERNAME superuser login password \'$PG_PASSWORD\' > /tmp/createuser-string
psql -U postgres postgres < /tmp/createuser-string
#
# this will grant the new user access to the user's database
echo grant all on database $PG_USERNAME to $PG_USERNAME > /tmp/grant-string
psql -U postgres postgres < /tmp/grant-string

#
# this creates a brokerinfo database, jdv user, and sets the password to jdv
psql -U postgres postgres < /cluster/bin/standalone-setup.sql

# seed brokerinfo course database
psql -U postgres postgres < /cluster/bin/financials-psql.sql

#now we sleep forever, this is to run pg in
# a Docker setting where something needs to block to keep
# the container running, this script serves the purpose
# of blocking while pg runs in the background
while true; do
sleep 30000
done
