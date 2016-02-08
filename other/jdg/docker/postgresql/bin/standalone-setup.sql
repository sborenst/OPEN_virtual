ALTER USER postgres WITH PASSWORD 'postgres';
create user jdg login superuser password 'jdg';

# DROP DATABASE IF EXISTS jdgcachestore;
CREATE DATABASE jdgcachestore;
grant all privileges on database jdgcachestore to jdg;
