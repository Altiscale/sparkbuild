#!/bin/bash -x

kerberos_enable="false"

# Create HDFS folders for Spark Event logs
# Doesn't matter who runs it.
# TBD: Move to Chef, and support Kerberos since HADOOP_USER_NAME will
# be invalid after enabling Kerberos.
spark_conf="/etc/spark/spark-defaults.conf"

if [ ! -f $spark_conf ] ; then
  echo "fatal - spark config not found, installation not complete, exiting!!!"
  exit -1
fi

event_log_dir=$(grep 'spark.history.fs.logDirectory' $spark_conf | tr -s ' ' '\t' | cut -f2)
user_dir=/user/spark

if [ "x${kerberos_enable}" = "xfalse" ] ; then
  HADOOP_USER_NAME=hdfs hdfs dfs -mkdir -p $event_log_dir
  HADOOP_USER_NAME=hdfs hdfs dfs -chmod 1777 $event_log_dir
  HADOOP_USER_NAME=hdfs hdfs dfs -chown -R spark:hadoop $event_log_dir

  HADOOP_USER_NAME=hdfs hdfs dfs -mkdir -p $user_dir
  HADOOP_USER_NAME=hdfs hdfs dfs -chown spark:users $user_dir
fi

