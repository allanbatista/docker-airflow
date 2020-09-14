#!/bin/bash

if [ -n "$PYTHON_PACKAGES" ]
then
  echo "instaling PYTHON_PACKAGES=${PYTHON_PACKAGES}"
  pip install $PYTHON_PACKAGES
fi

if [ -n "$GOOGLE_APPLICATION_CREDENTIALS_JSON" ]; then
  export GOOGLE_APPLICATION_CREDENTIALS=$AIRFLOW_KEYS/google_key.json
  echo $GOOGLE_APPLICATION_CREDENTIALS_JSON | base64 --decode > $GOOGLE_APPLICATION_CREDENTIALS

  if [ -n "$GOOGLE_APPLICATION_ACCOUNT" ]; then
    if [ -n "$GOOGLE_APPLICATION_PROJECT" ]; then
      gcloud auth activate-service-account --account $GOOGLE_APPLICATION_ACCOUNT --key-file=$GOOGLE_APPLICATION_CREDENTIALS --project=$GOOGLE_APPLICATION_PROJECT
    fi
  fi
fi

case $1 in
    "webserver")
        echo "Starting Webserver"
        airflow initdb
        airflow webserver
        ;;
    "worker"|"scheduler"|"flower")
        echo "Starting $1"
        airflow $1
        ;;
    "sync")
	while true
	do
		gsutil -m rsync -r -d $GCS_DAGS $AIRFLOW__CORE__DAGS_FOLDER
		sleep 1
	done
	;;
    *)
        exec $@
        ;;
esac
