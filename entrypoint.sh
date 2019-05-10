#!/bin/bash

if [ -n "$PYTHON_PACKAGES" ]
then
    pip install $PYTHON_PACKAGES
fi

case $1 in
    "webserver")
        echo "Starting Webserver"
        airflow initdb
        airflow webserver
        ;;
    "worker"|"scheduler")
        echo "Starting $1"
        airflow $1
        ;;
    *)
        exec $@
        ;;
esac