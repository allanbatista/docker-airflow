FROM ubuntu:18.04

LABEL author="Allan Batista <allan@allanbatista.com.br>"

EXPOSE 8080 5555 8793

SHELL ["/bin/bash", "-c"]

# no interaction
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux
ENV SLUGIFY_USES_TEXT_UNIDECODE=yes

# airflow
ENV AIRFLOW=/opt/airflow
ENV AIRFLOW_HOME=$AIRFLOW/home
ENV AIRFLOW__CORE__DAGS_FOLDER=$AIRFLOW/dags
ENV AIRFLOW__CORE__PLUGINS_FOLDER=$AIRFLOW/plugins
ENV AIRFLOW__CORE__BASE_LOG_FOLDER=$AIRFLOW/logs
ENV AIRFLOW_KEYS=$AIRFLOW/keys
ENV AIRFLOW_VERSION=1.10.4
ENV AIRFLOW_COMPONENTS=all_dbs,async,celery,cloudant,crypto,gcp_api,google_auth,hdfs,hive,jdbc,mysql,oracle,password,postgres,rabbitmq,redis,s3,samba,slack,ssh,github_enterprise
ENV AIRFLOW_GPL_UNIDECODE=yes
ENV C_FORCE_ROOT=true

# language
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8

# pip install extensions
ENV PYTHON_PACKAGES=
ENV PYTHONDONTWRITEBYTECODE=true

# google cloud sdk
ENV PATH=$PATH:/usr/local/gcloud/google-cloud-sdk/bin
ENV CLOUDSDK_PYTHON="python2.7"
ENV GOOGLE_APPLICATION_CREDENTIALS_JSON=
ENV GOOGLE_APPLICATION_ACCOUNT=
ENV CLOUD_SDK_REPO=cloud-sdk-bionic

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

RUN apt-get update -y \
    && apt-get install -y \
                        python-minimal \
                        python3-pip \
                        python3-dev \
                        python3-setuptools \
                        zip \
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
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen \
    && apt-get clean

RUN echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update -y && \
    apt-get install google-cloud-sdk -y


RUN ln -sf $(which pip3) /usr/bin/pip \
    && ln -sf $(which python3) /usr/bin/python

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
                pandas \
                psycopg2 \
                psycopg2-binary \
                py-postgresql \
                numpy \
                matplotlib \
                scikit-learn \
                google-cloud-bigquery==1.11.3 \
                google-cloud-storage \
                google-cloud-pubsub \
                tensorflow \
                sasl \
                thrift_sasl \
                setuptools \
                wheel \
                pika \
                pymongo \
                unidecode \
                cx_Oracle \
                nltk \
                -U --no-cache-dir

RUN python -c "import nltk; nltk.download('rslp')"

# remove apt cache
RUN apt-get clean --dry-run

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["/entrypoint.sh", "webserver"]
