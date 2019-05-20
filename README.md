# Docker image for Airflow

Docker Image for Apahce Airflow to be utilized on production.

## Envs

    GOOGLE_APPLICATION_CREDENTIALS_JSON
    GOOGLE_APPLICATION_ACCOUNT
    PYTHON_PACKAGES
    GCS_DAGS=gs://bucket/path/dags

### example

    docker run --rm -it \
    -e AIRFLOW__CELERY__BROKER_URL=amqp://192.168.85.196:31566 \
    -e AIRFLOW__CELERY__DEFAULT_QUEUE=airflow \
    -e AIRFLOW__CELERY__RESULT_BACKEND=db+psycopg2://postgres:password@192.168.85.211:31641/postgres \
    -e AIRFLOW__CORE__EXECUTOR=CeleryExecutor \
    -e AIRFLOW__CORE__LOAD_EXAMPLES=False \
    -e AIRFLOW__CORE__SQL_ALCHEMY_CONN=postgresql+psycopg2://postgres:password@192.168.85.211:31641/postgres \
    allanbatista/airflow worker

## Dir

    /opt/airflow/home airflow home
    /opt/airflow/dags airflow dags
    /opt/airflow/logs airflow logs
    /opt/airflow/plugins airflow plugins
    /opt/airflow/keys store your keys here

## Ports

    8080 webserver
    5555 flower
    8793 worker log server port

## Executing

    docker run --rm -it -p 8080:8080 allanbatista/airflow webserver
    docker run --rm -it allanbatista/airflow scheduler
    docker run --rm -it -p 8793:8793 allanbatista/airflow worker
    docker run --rm -it -p 5555:5555 allanbatista/airflow flower
    docker run --rm -it -e GCS_DAGS=gs://bucket/path/dags allanbatista/airflow sync

