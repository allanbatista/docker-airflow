FROM python:3.7-slim

LABEL author="Allan Batista <allan@allanbatista.com.br>"

EXPOSE 8080 5555 8793

# no interaction
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# airflow
ENV AIRFLOW=/opt/airflow
ENV AIRFLOW_HOME=$AIRFLOW/home
ENV AIRFLOW_DAGS=$AIRFLOW/dags
ENV AIRFLOW_LOGS=$AIRFLOW/logs
ENV AIRFLOW_VERSION=1.10.3
ENV AIRFLOW_GPL_UNIDECODE=yes

# language
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8

# base
RUN mkdir -p $AIRFLOW_HOME && \
    mkdir -p $AIRFLOW_DAGS && \
    mkdir -p $AIRFLOW_LOGS
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
                sklearn \
                tensorflow

RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["webserver"]