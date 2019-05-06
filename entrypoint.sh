#!/bin/bash

if [ "$1" == "webserver" ]
then
    airflow initdb
fi

airflow $@