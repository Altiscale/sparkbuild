#!/bin/sh -x

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
spark_home=$SPARK_HOME

if [ "x${spark_home}" = "x" ] ; then
  spark_home=/opt/spark
  echo "ok - applying default location /opt/spark"
fi

source $spark_home/test_spark/init_spark.sh

spark_version=$SPARK_VERSION

pushd `pwd`
cd $spark_home



echo "ok - testing spark REPL shell with various algorithm"
hadoop_snappy_jar=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "snappy-java-*.jar")
hadoop_lzo_jar=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "hadoop-lzo-*.jar")
# The guava JAR here does not match the Spark's pom.xml which is looking for version 14.0.1
# Hive comes with Guava 11.0.2
guava_jar=$(find $HIVE_HOME/lib/ -type f -name "guava-*.jar")
spark_opts_extra="--jars $hadoop_lzo_jar,$hadoop_snappy_jar,$guava_jar"

spark_event_log_dir=$(grep 'spark.eventLog.dir' /etc/spark/spark-defaults.conf | tr -s ' ' '\t' | cut -f2)

# SPARK-6797, SparkR does not support YARN (yarn-client, yarn-cluster) mode in Spark 1.4.
# Use localmode here. Make sure Workbench has sufficient memory if this is the case.

./bin/sparkR --verbose --driver-memory 1024M --conf spark.eventLog.dir=${spark_event_log_dir}$USER/ $spark_opts_extra

if [ $? -ne "0" ] ; then
  echo "fail - testing SparkR shell for various algorithm failed!"
  exit -3
fi

popd

exit 0


