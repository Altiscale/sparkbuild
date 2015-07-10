#!/bin/sh -x

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
testcase_shell_file_01=$curr_dir/pysparkshell_examples.txt
spark_home=$SPARK_HOME

if [ "x${spark_home}" = "x" ] ; then
  spark_home=/opt/spark
  echo "ok - applying default location /opt/spark"
fi
spark_test_dir="$spark_home/test_spark"

source $spark_home/test_spark/init_spark.sh

spark_version=$SPARK_VERSION

if [ ! -f "$testcase_shell_file_01"  ] ; then
  echo "fail - missing testcase for spark, can't continue, exiting"
  exit -2
fi

pushd `pwd`
cd $spark_home
hdfs dfs -mkdir -p spark/test/
hdfs dfs -put $spark_home/README.md spark/test/

# Leverage a simple use case here
hdfs dfs -put "$spark_test_dir/src/main/resources/spam_sample.txt" spark/test/
hdfs dfs -put "$spark_test_dir/src/main/resources/normal_sample.txt" spark/test/

echo "ok - testing spark REPL shell with various algorithm"
hadoop_snappy_jar=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "snappy-java-*.jar")
hadoop_lzo_jar=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "hadoop-lzo-*.jar")
# The guava JAR here does not match the Spark's pom.xml which is looking for version 14.0.1
# Hive comes with Guava 11.0.2
guava_jar=$(find $HIVE_HOME/lib/ -type f -name "guava-*.jar")
spark_opts_extra="$spark_opts_extra --jars $hadoop_lzo_jar,$hadoop_snappy_jar,$guava_jar"

spark_event_log_dir=$(grep 'spark.eventLog.dir' /etc/spark/spark-defaults.conf | tr -s ' ' '\t' | cut -f2)

# Launch a pyspark shell prompt for ppl to use
# ./bin/pyspark --master yarn --deploy-mode client --queue research --driver-memory 512M --conf spark.eventLog.dir=${spark_event_log_dir}$USER/ $spark_opts_extra
# queue_name="--queue interactive"
queue_name=""
./bin/pyspark --master yarn --deploy-mode client --driver-memory 512M --conf spark.eventLog.dir=${spark_event_log_dir}$USER/ $spark_opts_extra $queue_name

popd

exit 0


