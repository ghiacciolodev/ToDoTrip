#!/bin/sh
# Creates the database the test suite drops and rebuilds on every run.
#
# Postgres only runs the scripts in this directory the first time the data
# volume is created, which is exactly right: after that the database exists and
# recreating it would be wrong.
set -e

psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE DATABASE todotrip_test OWNER $POSTGRES_USER;
EOSQL
