export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export JAVA_VERSION=8.131
export SPARK_SUBMIT_OPTIONS="--files /etc/cluster/hadoop/core-site.xml,/etc/cluster/hbase/hbase-site.xml,/etc/cluster/hadoop/hdfs-site.xml,/etc/cluster/hive/hive-site.xml,/etc/cluster/hadoop/yarn-site.xml,/etc/cluster/hadoop/mapred-site.xml"
export HADOOP_CONF_DIR="/etc/cluster/hadoop"
export ZEPPELIN_INTERPRETER_OUTPUT_LIMIT=102400000
export ZEPPELIN_JAVA_OPTS="-Djavax.security.auth.useSubjectCredsOnly=false -Djava.security.krb5.conf=/etc/krb5.conf"
