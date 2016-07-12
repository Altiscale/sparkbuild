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
spark_version=$SPARK_VERSION
spark_test_dir="$spark_home/test_spark"

if [ ! -d "$spark_test_dir" ] ; then
  echo "warn - correcting test directory from $spark_test_dir to $curr_dir"
  spark_test_dir=$curr_dir
fi

pushd `pwd`
cd $spark_home
hdfs dfs -mkdir -p spark/test/resources
hdfs dfs -copyFromLocal ${spark_home}/examples/src/main/resources/* spark/test/resources/

# Perform sanity check on required files in test case
if [ ! -f "$spark_home/examples/src/main/resources/kv1.txt" ] ; then
  >&2 echo "fail - missing test data $spark_home/examples/src/main/resources/kv1.txt to load, did the examples directory structure changed?"
  exit -3
fi

echo "ok - testing spark SQL shell with simple queries"

app_name=`grep "<artifactId>.*</artifactId>" $spark_test_dir/pom.xml | cut -d">" -f2- | cut -d"<" -f1  | head -n 1`
app_ver=`grep "<version>.*</version>" $spark_test_dir/pom.xml | cut -d">" -f2- | cut -d"<" -f1 | head -n 1`

if [ ! -f "$spark_test_dir/${app_name}-${app_ver}.jar" ] ; then
  >&2 echo "fail - $spark_test_dir/${app_name}-${app_ver}.jar test jar does not exist, cannot continue testing, failing!"
  exit -3
fi

sparksql_hivejars="$spark_home/lib/spark-hive_${SPARK_SCALA_VERSION}.jar"
hive_jars_colon=$sparksql_hivejars:$(find $HIVE_HOME/lib/ -type f -name "*.jar" | tr -s '\n' ':')
hive_jars=$sparksql_hivejars,$(find $HIVE_HOME/lib/ -type f -name "*.jar" | tr -s '\n' ',')
spark_event_log_dir=$(grep 'spark.eventLog.dir' ${spark_conf}/spark-defaults.conf | tr -s ' ' '\t' | cut -f2)

# pyspark only supports yarn-client mode now
# queue_name="--queue interactive"
queue_name=""
./bin/spark-submit --verbose \
  --master yarn --deploy-mode client $queue_name \
  --driver-class-path $spark_conf/hive-site.xml:$spark_conf/yarnclient-driver-log4j.properties:$hive_jars_colon \
  --conf spark.eventLog.dir=${spark_event_log_dir}/$USER \
  --conf spark.yarn.dist.files=$spark_conf/hive-site.xml,$spark_conf/executor-log4j.properties,$hive_jars \
  --conf spark.yarn.am.extraJavaOptions="-Djava.library.path=$HADOOP_HOME/lib/native/" \
  --conf spark.driver.extraJavaOptions="-Dlog4j.configuration=yarnclient-driver-log4j.properties -Djava.library.path=$HADOOP_HOME/lib/native/" \
  --conf spark.executor.extraJavaOptions="-Dlog4j.configuration=executor-log4j.properties -XX:+PrintReferenceGC -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintAdaptiveSizePolicy -Djava.library.path=$HADOOP_HOME/lib/native/" \
  --py-files $spark_home/test_spark/src/main/python/pyspark_hql.py \
  $spark_home/test_spark/src/main/python/pyspark_hql.py

if [ $? -ne "0" ] ; then
  >&2 echo "fail - testing shell for Python SparkSQL on HiveQL/HiveContext failed!!"
  exit -4
fi

popd

reset

exit 0


