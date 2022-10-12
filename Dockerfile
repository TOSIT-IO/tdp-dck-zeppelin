FROM apache/zeppelin:0.10.0

ENV DEBIAN_FRONTEND noninteractive
ENV HADOOP_HOME /etc/cluster/hadoop
ENV HADOOP_CONF_DIR ${HADOOP_HOME}
ENV ZEPPELIN_INTP_CLASSPATH_OVERRIDES /etc/cluster/hive
ENV ZEPPELIN_RUN_MODE local

USER root

RUN apt-get update && apt-get install -y gnupg2

RUN apt-get -qq update && apt-get -qq install -y --no-install-recommends \
      jq \
      vim \
      krb5-user \
      s3cmd \
      wget \
      curl \
      openssl \
      libnss-ldap \
      libpam-ldap \
      ldap-utils \
      bind9 \
      nginx \
      libnginx-mod-stream \
      cron \
    && rm -rf /var/lib/apt/lists/*

### Install of Spark 2 TDP ###
ENV APACHE_SPARK_VERSION 2.3.5
ENV HADOOP_VERSION 3.1.1
ENV SPARK_BASE_DIR /usr/local/spark2
ENV SPARK_HOME ${SPARK_BASE_DIR}/${APACHE_SPARK_VERSION}
RUN mkdir -p ${SPARK_BASE_DIR}
COPY files/spark-2.3.5-TDP-0.1.0-SNAPSHOT-bin-tdp.tgz /var/tmp
RUN tar xvzf /var/tmp/spark-2.3.5-TDP-0.1.0-SNAPSHOT-bin-tdp.tgz -C ${SPARK_BASE_DIR} \
    && SPARK_DISTRIB="spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" \
    && rm -rf /var/tmp/spark-2.3.5-TDP-0.1.0-SNAPSHOT-bin-tdp.tgz \
    && mv ${SPARK_BASE_DIR}/spark-2.3.5-TDP-0.1.0-SNAPSHOT-bin-tdp ${SPARK_BASE_DIR}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} \
    && cp ${SPARK_BASE_DIR}/${SPARK_DISTRIB}/conf/log4j.properties.template ${SPARK_BASE_DIR}/${SPARK_DISTRIB}/conf/log4j.properties \
    && ln -s ${SPARK_BASE_DIR}/${SPARK_DISTRIB} ${SPARK_HOME}

### Configuration of Nginx ###
RUN mkdir -p /var/lib/nginx && \
  mkdir -p /etc/nginx/sites-enabled && \
  mkdir -p /etc/nginx/certs && \
  mkdir -p /etc/nginx/conf.d && \
  mkdir -p /var/log/nginx && \
  mkdir -p /var/www/html && \
  mkdir -p /var/tmp/logs && \
  mkdir -p /var/tmp/run && \
  mkdir -p /data/www/html && \
  mkdir -p /var/www/localhost/htdocs && \
  mkdir -p /etc/ssl/private && \
  mkdir -p /etc/ssl/certs && \
  echo "<h1>Hello world!</h1>" > /var/www/localhost/htdocs/index.html;

RUN openssl req -x509 -nodes -days 3650 \
-subj "/C=CA/ST=QC/O=Company, Inc./CN=mydomain.com" \
-newkey rsa:2048 \
-keyout /etc/ssl/private/nginx-selfsigned.key \
-out /etc/ssl/certs/nginx-selfsigned.crt;

ADD ./files/nginx.conf /etc/nginx/nginx.conf
ADD ./files/myapp.conf /etc/nginx/conf.d/myapp.conf
ADD ./files/proxy_params /etc/nginx/proxy_params
ADD ./files/tdp_user.htpasswd /etc/nginx/conf.d/tdp_user.htpasswd

### Add Hadoop to profile ###
RUN echo "export HADOOP_CONF_DIR=/etc/cluster/hadoop" >> /etc/profile.d/hadoop.sh

### Add TDP sandbox confs ###
ADD files/hosts /etc/hosts
ADD files/krb5.conf /etc/krb5.conf
COPY files/clients-config.tar.gz clients-config.tar.gz

### Add TDP zeppelin confs ###
COPY files/zeppelin-conf.tar.gz zeppelin-conf.tar.gz
RUN tar -xzf zeppelin-conf.tar.gz -C /opt/zeppelin/conf && \
  rm zeppelin-conf.tar.gz

### Add TDP clients confs ###
RUN  mkdir -p clients-config && \
  tar -xzf clients-config.tar.gz -C clients-config && \
  mkdir -p /etc/cluster/hadoop && rm -rf /etc/cluster/hadoop/* && \
  mkdir -p /etc/cluster/hive && rm -rf /etc/cluster/hive/* && \
  mkdir -p /usr/local/spark2/2.3.0/conf && rm -rf /usr/local/spark2/2.3.0/conf/* && \
  mkdir -p /etc/cluster/hbase && rm -rf /etc/cluster/hbase/* && \
  cp -r clients-config/hadoop/* /etc/cluster/hadoop && \
  cp -r clients-config/hive/* /etc/cluster/hive && \
  cp -r clients-config/hbase/* /etc/cluster/hbase && \
  cp -r clients-config/spark/* /usr/local/spark2/2.3.0/conf && \
  rm clients-config.tar.gz && \
  rm -rf clients-config

### Add TDP SSL confs ###
COPY files/truststore.jks /truststore.jks
RUN mkdir -p /data
RUN mkdir -p /etc/security/keytabs/
RUN mkdir -p /etc/ssl/certs/
RUN mkdir -p /etc/security/serverKeys/
RUN cp -rf /truststore.jks /etc/ssl/certs/truststore.jks
RUN cp -rf /truststore.jks /etc/security/serverKeys/zeppelin-truststore
RUN mkdir -p /persisted_notebook

RUN echo "* * * * * cp -f -p -r /opt/zeppelin/notebook/. /persisted_notebook/"  >> zeppelincron \
  && crontab zeppelincron \
  && rm zeppelincron

### Dumb init ###
RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64 && \
    echo "37f2c1f0372a45554f1b89924fbb134fc24c3756efaedf11e07f599494e0eff9  /usr/local/bin/dumb-init" | sha256sum -c - && \
    chmod 755 /usr/local/bin/dumb-init

CMD ["/opt/zeppelin/bin/zeppelin.sh"]

COPY files/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
