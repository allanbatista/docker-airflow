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
ENV AIRFLOW_VERSION=1.10.3
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

# google cloud sdk
ENV PATH=$PATH:/usr/local/gcloud/google-cloud-sdk/bin
ENV CLOUDSDK_PYTHON="python2.7"
ENV GOOGLE_APPLICATION_CREDENTIALS_JSON=
ENV GOOGLE_APPLICATION_ACCOUNT=
ENV CLOUD_SDK_REPO=cloud-sdk-bionic

# base
RUN mkdir -p $AIRFLOW_HOME && \
    mkdir -p $AIRFLOW_KEYS && \
    mkdir -p $AIRFLOW__CORE__DAGS_FOLDER && \
    mkdir -p $AIRFLOW__CORE__BASE_LOG_FOLDER && \
    mkdir -p AIRFLOW__CORE__PLUGINS_FOLDER    
ADD airflow/home /opt/airflow/home
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
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen \
    && apt-get clean

RUN echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update -y && \
    apt-get install google-cloud-sdk -y


RUN ln -sf $(which pip3) /usr/bin/pip \
    && ln -sf $(which python3) /usr/bin/python

RUN pip install boto3 \
                pandas \
                psycopg2 \
                psycopg2-binary \
                py-postgresql \
                numpy \
                matplotlib \
                scikit-learn \
                google-cloud-bigquery \
                google-cloud-storage \
                google-cloud-pubsub \
                tensorflow \
                sasl \
                thrift_sasl \
                setuptools \
                wheel

ENV AIRFLOW_COMPONENTS=all_dbs,async,celery,cloudant,crypto,gcp_api,google_auth,hdfs,hive,jdbc,mysql,oracle,password,postgres,rabbitmq,redis,s3,samba,slack,ssh,github_enterprise

RUN pip3 install "apache-airflow[${AIRFLOW_COMPONENTS}]==${AIRFLOW_VERSION}"

RUN mkdir -p /airflow_custom
ADD airflow/airflow_custom /airflow_custom
RUN python -m pip install -e /airflow_custom

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["/entrypoint.sh", "webserver"]
