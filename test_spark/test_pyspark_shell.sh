#!/bin/sh

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"

# Default SPARK_HOME location is already checked by init_spark.sh
spark_home=${SPARK_HOME:='/opt/spark'}
if [ ! -d "$spark_home" ] ; then
  >&2 echo "fail - $spark_home does not exist, please check you Spark installation or SPARK_HOME env variable, exinting!"
  exit -2
else
  echo "ok - applying Spark home $spark_home"
fi

source $spark_home/test_spark/init_spark.sh

# Default SPARK_CONF_DIR is already checked by init_spark.sh
spark_conf=${SPARK_CONF_DIR:-"/etc/spark"}
if [ ! -d "$spark_conf" ] ; then
  >&2 echo "fail - $spark_conf does not exist, please check you Spark installation or your SPARK_CONF_DIR env value, exiting!"
  exit -2
else
  echo "ok - applying spark config directory $spark_conf"
fi

spark_version=$SPARK_VERSION
if [ "x${spark_version}" = "x" ] ; then
  >&2 echo "fail - SPARK_VERSION can not be identified or not defined, please review SPARK_VERSION env variable? Exiting!"
  exit -2
fi

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
testcase_shell_file_01=$curr_dir/pysparkshell_examples.txt
spark_version=$SPARK_VERSION
spark_test_dir="$spark_home/test_spark"

if [ ! -f "$testcase_shell_file_01"  ] ; then
  >&2 echo "fail - missing testcase for spark, can't continue, exiting"
  exit -2
fi

if [ ! -d "$spark_test_dir" ] ; then
  echo "warn - correcting test directory from $spark_test_dir to $curr_dir"
  spark_test_dir=$curr_dir
fi

pushd `pwd`
cd $spark_home
hdfs dfs -mkdir -p spark/test/
hdfs dfs -put $spark_home/README.md spark/test/

# Leverage a simple use case here
hdfs dfs -put "$spark_test_dir/src/main/resources/spam_sample.txt" spark/test/
hdfs dfs -put "$spark_test_dir/src/main/resources/normal_sample.txt" spark/test/

echo "ok - testing PySpark REPL shell with various algorithm"

sparksql_hivejars="$spark_home/sql/hive/target/spark-hive_${SPARK_SCALA_VERSION}-${spark_version}.jar"
hive_jars_colon=$sparksql_hivejars:$(find $HIVE_HOME/lib/ -type f -name "*.jar" | tr -s '\n' ':')
hive_jars=$sparksql_hivejars,$(find $HIVE_HOME/lib/ -type f -name "*.jar" | tr -s '\n' ',')

spark_event_log_dir=$(grep 'spark.eventLog.dir' /etc/spark/spark-defaults.conf | tr -s ' ' '\t' | cut -f2)

# queue_name="--queue interactive"
queue_name=""
./bin/spark-submit --verbose \
  --master yarn --deploy-mode client \
  $queue_name \
  --driver-class-path /etc/spark/hive-site.xml:$hive_jars_colon \
  --conf spark.eventLog.dir=${spark_event_log_dir}/$USER \
  --conf spark.yarn.dist.files=/etc/spark/hive-site.xml,$hive_jars \
  --py-files $spark_home/test_spark/src/main/python/pyspark_shell_examples.py \
  $spark_home/test_spark/src/main/python/pyspark_shell_examples.py

if [ $? -ne "0" ] ; then
  >&2 echo "fail - testing $0 shell for various MLLib algorithm failed!"
  exit -3
fi

popd

reset

exit 0
