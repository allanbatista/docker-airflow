FROM python:3.7.9

LABEL author="Allan Batista <allan@allanbatista.com.br>"

EXPOSE 8080 5555 8793

SHELL ["/bin/bash", "-c"]

# no interaction
ENV TERM linux
ENV DEBIAN_FRONTEND noninteractiv
ENV SLUGIFY_USES_TEXT_UNIDECODE=yes

# language
ENV LANGUAGE=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LC_CTYPE=en_US.UTF-8 \
    LC_MESSAGES=en_US.UTF-8

# airflow core config
ENV AIRFLOW=/opt/airflow \
    AIRFLOW_HOME=$AIRFLOW/home \
    AIRFLOW__CORE__DAGS_FOLDER=$AIRFLOW/dags \
    AIRFLOW__CORE__PLUGINS_FOLDER=$AIRFLOW/plugins \
    AIRFLOW__CORE__BASE_LOG_FOLDER=$AIRFLOW/logs \
    AIRFLOW_KEYS=$AIRFLOW/keys \
    AIRFLOW_VERSION=1.10.12 \
    AIRFLOW_COMPONENTS=all_dbs,async,celery,cloudant,crypto,gcp_api,google_auth,hdfs,hive,jdbc,mysql,oracle,password,postgres,rabbitmq,redis,s3,samba,slack,ssh,github_enterprise \
    AIRFLOW_GPL_UNIDECODE=yes \
    C_FORCE_ROOT=true

# aiflow configs
ENV AIRFLOW__WEBSERVER__AUTHENTICATE=True \
    AIRFLOW__WEBSERVER__AUTH_BACKEND=airflow.contrib.auth.backends.password_auth \
    AIRFLOW__CELERY__BROKER_URL=pyamqp://guest:guest@rabbitmq:5672 \
    AIRFLOW__CELERY__DEFAULT_QUEUE=airflow \
    AIRFLOW__CELERY__RESULT_BACKEND=db+psycopg2://airflow:pg_password@postgres:5432/airflow \
    AIRFLOW__CORE__EXECUTOR=CeleryExecutor \
    AIRFLOW__CORE__LOAD_EXAMPLES=False \
    AIRFLOW__CORE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:pg_passwordg@postgres:5432/airflow \
    AIRFLOW__CORE__HOSTNAME_CALLABLE=airflow_custom.net:get_ip \
    AIRFLOW__SCHEDULER__DAG_DIR_LIST_INTERVAL=5 \
    AIRFLOW__CORE__TASK_RUNNER=BashTaskRunner

# pip install extensions
ENV PYTHON_PACKAGES=
ENV PYTHONDONTWRITEBYTECODE=true

# GOOGLE SYNC
ENV PATH=$PATH:/usr/local/gcloud/google-cloud-sdk/bin
ENV GOOGLE_APPLICATION_CREDENTIALS_JSON=
ENV GOOGLE_APPLICATION_ACCOUNT=

# oracle driver
ENV ORACLE_HOME=/opt/cx_oracle
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ORACLE_HOME

# base
RUN mkdir -p $AIRFLOW_HOME && \
    mkdir -p $AIRFLOW_KEYS && \
    mkdir -p $AIRFLOW__CORE__DAGS_FOLDER && \
    mkdir -p $AIRFLOW__CORE__BASE_LOG_FOLDER && \
    mkdir -p $AIRFLOW__CORE__PLUGINS_FOLDER
ADD airflow/home /opt/airflow/home
ADD instantclient-basic-linux.x64-19.3.0.0.0dbru.zip /tmp/
WORKDIR /opt/airflow

RUN apt-get update -y && \
    apt-get install -y zip \
                       wget \
                       git \
                       vim \
                       locales \
                       build-essential \
                       curl \
                       default-libmysqlclient-dev \
                       freetds-dev \
                       libkrb5-dev \
                       libsasl2-dev \
                       libssl-dev \
                       libffi-dev \
                       libpq-dev \
                       libaio1 \
                       openjdk-11-jdk \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen \
    && apt-get clean

RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update && \
    apt-get install google-cloud-sdk -y

## install oracle driver
RUN cd /tmp/ && \
    unzip instantclient-basic-linux.x64-19.3.0.0.0dbru.zip && \
    mv instantclient_19_3 $ORACLE_HOME && \
    rm instantclient-basic-linux.x64-19.3.0.0.0dbru.zip

## Install Airflow
RUN pip install "apache-airflow[${AIRFLOW_COMPONENTS}]==${AIRFLOW_VERSION}" --no-cache-dir

RUN mkdir -p /airflow_custom
ADD airflow/airflow_custom /airflow_custom
RUN python -m pip install -e /airflow_custom

## Install additional packages
RUN pip install boto3 \
                google-cloud-bigquery \
                google-cloud-storage \
                google-cloud-pubsub \
                pandas \
                psycopg2 \
                psycopg2-binary \
                py-postgresql \
                numpy \
                matplotlib \
                scikit-learn \
                tensorflow-gpu==2.3.0 \
                sasl \
                thrift_sasl \
                setuptools \
                wheel \
                pika \
                pymongo \
                unidecode \
                cx_Oracle \
                nltk \
                git+https://github.com/facebookresearch/fastText \
                -U --no-cache-dir

# remove apt cache
RUN apt-get clean --dry-run

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["/entrypoint.sh", "webserver"]
