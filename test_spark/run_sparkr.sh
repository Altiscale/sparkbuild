#!/bin/sh -x

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
spark_home=$SPARK_HOME

testcase_sparkr_file_01=$curr_dir/sparkr.test.txt

if [ "x${spark_home}" = "x" ] ; then
  spark_home=/opt/spark
  echo "ok - applying default location /opt/spark"
fi

if [ ! -f "$testcase_sparkr_file_01"  ] ; then
  echo "fail - missing testcase for sparkR, can't continue, exiting"
  exit -2
fi

source $spark_home/test_spark/init_spark.sh

spark_version=$SPARK_VERSION

pushd `pwd`
cd $spark_home
hdfs dfs -mkdir -p /user/$USER/spark/test/sparkr/
hdfs dfs -put examples/src/main/resources/people.json /user/$USER/spark/test/sparkr/

echo "ok - testing spark REPL shell with various algorithm"
hadoop_snappy_jar=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "snappy-java-*.jar")
hadoop_lzo_jar=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "hadoop-lzo-*.jar")
# The guava JAR here does not match the Spark's pom.xml which is looking for version 14.0.1
# Hive comes with Guava 11.0.2
guava_jar=$(find $HIVE_HOME/lib/ -type f -name "guava-*.jar")
spark_opts_extra="--jars $hadoop_lzo_jar,$hadoop_snappy_jar,$guava_jar"

spark_event_log_dir=$(grep 'spark.eventLog.dir' /etc/spark/spark-defaults.conf | tr -s ' ' '\t' | cut -f2)

# ./bin/spark-shell --verbose --master yarn --deploy-mode client --queue research --driver-memory 1024M --conf spark.eventLog.dir=${spark_event_log_dir}$USER/ $spark_opts_extra << EOT
# queue_name="--queue interactive"
queue_name=""
# Only yarn-client or local mode available (yarn-cluster mode not available)
# Please make sure Workbench has sufficient memory for your tasks/jobs
./bin/sparkR --verbose --driver-memory 1024M --master yarn --deploy-mode client --conf spark.eventLog.dir=${spark_event_log_dir}$USER/ $spark_opts_extra $queue_name

if [ $? -ne "0" ] ; then
  echo "fail - testing SparkR shell for various algorithm failed!"
  exit -3
fi

popd

exit 0


