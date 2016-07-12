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

if [ -f "$curr_dir/pom.xml" ] ; then
  spark_test_dir=$curr_dir
elif [ ! -f "$curr_dir/pom.xml" ] ; then
  spark_test_dir=$spark_home/test_spark/
fi

pushd `pwd`
cd $spark_home
hdfs dfs -mkdir -p spark/test/resources
hdfs dfs -copyFromLocal $spark_home/examples/src/main/resources/* spark/test/resources/

echo "ok - testing spark SQL shell with simple queries"

app_name=`grep "<artifactId>.*</artifactId>" ${spark_test_dir}/pom.xml | cut -d">" -f2- | cut -d"<" -f1  | head -n 1`
app_ver=`grep "<version>.*</version>" ${spark_test_dir}/pom.xml | cut -d">" -f2- | cut -d"<" -f1 | head -n 1`

if [ ! -f "$spark_test_dir/${app_name}-${app_ver}.jar" ] ; then
  >&2 echo "fail - $spark_test_dir/${app_name}-${app_ver}.jar test jar does not exist, cannot continue testing, failing!"
  exit -3
fi

spark_event_log_dir=$(grep 'spark.eventLog.dir' ${spark_conf}/spark-defaults.conf | tr -s ' ' '\t' | cut -f2)

# queue_name="--queue interactive"
queue_name=""
./bin/spark-submit --verbose \
  --master yarn --deploy-mode cluster \
  --driver-java-options "-Djava.library.path=/opt/hadoop/lib/native/" \
  --conf spark.yarn.dist.files=$spark_conf/yarnclient-driver-log4j.properties,$spark_conf/executor-log4j.properties \
  --conf spark.yarn.am.extraJavaOptions="-Djava.library.path=$HADOOP_HOME/lib/native/" \
  --conf spark.driver.extraJavaOptions="-Dlog4j.configuration=yarnclient-driver-log4j.properties -Djava.library.path=$HADOOP_HOME/lib/native/" \
  --conf spark.executor.extraJavaOptions="-Dlog4j.configuration=executor-log4j.properties -XX:+PrintReferenceGC -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintAdaptiveSizePolicy -Djava.library.path=$HADOOP_HOME/lib/native/" \
  --conf spark.eventLog.dir=${spark_event_log_dir}/$USER $queue_name \
  --class SparkSQLTestCase1SQLContextApp \
  $spark_test_dir/${app_name}-${app_ver}.jar

if [ $? -ne "0" ] ; then
  >&2 echo "fail - testing $0 for SparkSQL SQLContext failed!!"
  exit -4
fi

popd

exit 0


