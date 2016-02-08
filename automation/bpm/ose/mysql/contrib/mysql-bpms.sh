#!/bin/bash

# Create users and databases
function initialize_bpms_database {

  echo "Creating BPMS databases..."  

mysql $mysql_flags <<EOSQL
    GRANT ALL ON *.* TO 'jbpm'@'localhost' IDENTIFIED BY 'jbpm';
    GRANT ALL ON *.* TO 'jbpm'@'%' IDENTIFIED BY 'jbpm';
    CREATE DATABASE IF NOT EXISTS jbpm;
    GRANT ALL ON *.* TO 'dashbuilder'@'localhost' IDENTIFIED BY 'dashbuilder';
    GRANT ALL ON *.* TO 'dashbuilder'@'%' IDENTIFIED BY 'dashbuilder';
    CREATE DATABASE IF NOT EXISTS dashbuilder;
EOSQL

  mysql $mysql_flags jbpm < /sql/mysql5-jbpm-schema.sql
  mysql $mysql_flags jbpm < /sql/quartz_tables_mysql.sql

  # TO-DO:  use dashbuilder database
  mysql $mysql_flags dashbuilder < /sql/mysql5-dashbuilder-schema.sql

}

