GRANT ALL ON rhsso.* TO '{{rhsso_mysql_user}}'@'localhost' IDENTIFIED BY '{{rhsso_mysql_password}}';
GRANT ALL ON rhsso.* TO '{{rhsso_mysql_user}}'@'%' IDENTIFIED BY '{{rhsso_mysql_password}}';

CREATE DATABASE IF NOT EXISTS {{rhsso_mysql_schema}};



