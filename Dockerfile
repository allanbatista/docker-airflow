FROM python:2.7-slim

LABEL author="Allan Batista <allan@allanbatista.com.br>"

EXPOSE 8080 5555 8793

# no interaction
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# airflow
ENV AIRFLOW=/opt/airflow
ENV AIRFLOW_HOME=$AIRFLOW/home
ENV AIRFLOW__CORE__DAGS_FOLDER=$AIRFLOW/dags
ENV AIRFLOW__CORE__PLUGINS_FOLDER=$AIRFLOW/plugins
ENV AIRFLOW__CORE__BASE_LOG_FOLDER=$AIRFLOW/logs
ENV AIRFLOW_KEYS=$AIRFLOW/keys
ENV AIRFLOW_VERSION=1.10.3
ENV AIRFLOW_GPL_UNIDECODE=yes

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

# base
RUN mkdir -p $AIRFLOW_HOME && \
    mkdir -p $AIRFLOW_KEYS && \
    mkdir -p $AIRFLOW__CORE__DAGS_FOLDER && \
    mkdir -p $AIRFLOW__CORE__BASE_LOG_FOLDER && \
    mkdir -p AIRFLOW__CORE__PLUGINS_FOLDER    
ADD airflow/home /opt/airflow/home
COPY entrypoint.sh /entrypoint.sh
WORKDIR /opt/airflow

RUN apt-get update && \
    apt-get install -y \
    freetds-bin \
    build-essential \
    apt-utils \
    curl \
    rsync \
    netcat \
    locales \
    default-libmysqlclient-dev \
    freetds-dev \
    libkrb5-dev \
    libsasl2-dev \
    libssl-dev \
    libffi-dev \
    libpq-dev \
    git && \
    apt-get clean

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen

RUN pip install "apache-airflow[all]==${AIRFLOW_VERSION}" \
                google-cloud-bigquery \
                google-cloud-storage \
                google-cloud-pubsub \
                boto3 \
                pandas \
                numpy \
                matplotlib \
                sklearn==0.20 \
                tensorflow \
                psycopg2

# Installing google cloud sdk
COPY google-cloud-sdk-240.0.0-linux-x86_64.tar.gz /tmp
RUN mkdir -p /usr/local/gcloud \
  && tar -C /usr/local/gcloud -xf /tmp/google-cloud-sdk-240.0.0-linux-x86_64.tar.gz \
  && /usr/local/gcloud/google-cloud-sdk/install.sh \
  && rm /tmp/google-cloud-sdk-240.0.0-linux-x86_64.tar.gz \
  && gcloud components update --quiet

RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["/entrypoint.sh", "webserver"]