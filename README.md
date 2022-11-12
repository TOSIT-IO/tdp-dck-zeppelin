# Zeppelin 0.10.0 #

## Prerequisites ##

Get Hadoop, hive, hbase and spark2 confs (didn't include spark 3 for the moment)
```bash
CURRENT_BASE_DIR=$(echo $PWD)
cd ../tdp-getting-started
vagrant scp edge-01.tdp:/etc/hadoop/conf/* ${CURRENT_BASE_DIR}/files/hadoop/
vagrant scp edge-01.tdp:/etc/hbase/conf/* ${CURRENT_BASE_DIR}/files/hbase/
vagrant scp edge-01.tdp:/etc/hive/conf/* ${CURRENT_BASE_DIR}/files/hive/
vagrant scp edge-01.tdp:/etc/spark/conf/* ${CURRENT_BASE_DIR}/files/spark/
```
Get the hosts and kerberos files of your TDP cluster
```bash
vagrant scp edge-01.tdp:/etc/ssl/certs/truststore.jks ${CURRENT_BASE_DIR}/files/truststore.jks
vagrant scp edge-01.tdp:/etc/hosts ${CURRENT_BASE_DIR}/files/hosts
vagrant scp edge-01.tdp:/etc/krb5.conf ${CURRENT_BASE_DIR}/files/krb5.conf
vagrant scp edge-01.tdp:/home/tdp_user/tdp_user.keytab ${CURRENT_BASE_DIR}/__conf-zeppelin-0.10.0-USER/sandbox/keytabs/tdp_user.keytab
```
Create a tarball:
```bash
cd ${CURRENT_BASE_DIR}/files
tar cvzf clients-config.tar.gz hadoop hbase hive spark
```

## Configure Livy server ##

Add these confs:

```bash
[root@edge-01 ~]# vim /etc/livy/conf.server/livy.conf
...
livy.server.yarn.app-lookup-timeout=300s
livy.rsc.server.connect.timeout=200s
```

## Build this Zeppelin Docker image ##

```bash
cd ${CURRENT_BASE_DIR}
./build-zeppelin-for-tdp.sh
```

## Start zeppelin ##

```bash
cd __conf-zeppelin-0.10.0-USER/sandbox/
docker-compose up -d
```

## Open zeppelin ##

https://localhost:8181

## Test ##

A special livy interpreter called livy2_perso is configured.\
A working note is also configured.

```bash
%livy2_perso.conf
zeppelin.livy.principal tdp_user@REALM.TDP
zeppelin.livy.keytab /etc/security/keytabs/tdp_user.keytab
livy.spark.yarn.queue default
```

Start a spark context
```bash
sc
sc.version
sc.getConf.getAll.foreach(println)
```

## TDP connection ##

This zeppelin is portable, it interracts with a TDP cluster through livy, with SSL and Kerberos.

## Important Information ##

This Zeppelin is not multi-tenant: An instance must be runned per user.

## Security choise ##

Nginx is embedded in the Docker image for SSL, for the Zeppelin frontend.\
htpasswd is embedded in the Docker image for authentification concerns, for the Zeppelin frontend.\
\
Then, Zeppelin can run in Anonymous, without authentification, without SSL.\
For portability and for the use of notebooks and interpreters, it is much simpler this way.

## Authentification ##

Current auth file is the following :
```bash
__conf-zeppelin-0.10.0-USER/sandbox/conf-nginx/conf.d/tdp_user.htpasswd
```
At Runtime it ends here:
```bash
/etc/nginx/conf.d/tdp_user.htpasswd
```

## SSL ##

Self-signed certificate is generated at build-time.\
To change it, follow these steps:

```bash
cd __conf-zeppelin-0.10.0-USER/sandbox/conf-nginx/certs/
vim nginx-selfsigned.crt 
-----BEGIN CERTIFICATE-----
...
```

```bash
cd __conf-zeppelin-0.10.0-USER/sandbox/conf-nginx/private/
vim nginx-selfsigned.key 
-----BEGIN CERTIFICATE-----
...
```

## User Data ##

A folder is dedicated for importing/exporting files in the image at runtime
```bash
cd __conf-zeppelin-0.10.0-USER/sandbox/data/
...
```
In the image, it will end up in /data

## Hadoop User Keytab ##

A folder is dedicated for storing the Hadoop user keytab :
```bash
cd __conf-zeppelin-0.10.0-USER/sandbox/keytabs/
...
```
In the image, it will end up in /etc/security/keytabs

## Backups of Notebooks, interpretors and Zeppelin confs ##

Everything is handled.\
Persisted folder is
```bash
__conf-zeppelin-0.10.0-USER/sandbox/notebook
```
