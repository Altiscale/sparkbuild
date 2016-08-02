#!/bin/sh

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"
spark_home=${SPARK_HOME:='/opt/spark'}
if [ ! -d "$spark_home" ] ; then
  >&2 echo "fail - $spark_home does not exist, please check you Spark installation or SPARK_HOME env variable, exinting!"
  exit -2
else
  echo "ok - applying Spark home $spark_home"
fi

source $spark_home/test_spark/init_spark.sh
source $spark_home/test_spark/deploy_hive_jar.sh

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
spark_test_dir="$spark_home/test_spark"

hive_home=${HIVE_HOME:-"/opt/hive"}

if [ ! -f "$spark_test_dir/pom.xml" ] ; then
  echo "warn - correcting test directory from $spark_test_dir to $curr_dir"
  spark_test_dir=$curr_dir
fi

pushd `pwd`
cd $spark_home
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

spark_event_log_dir=$(grep 'spark.eventLog.dir' ${spark_conf}/spark-defaults.conf | tr -s ' ' '\t' | cut -f2)

# queue_name="--queue interactive"
queue_name=""

# if /etc/spark/spark-env.sh already defined the SPARK_DIST_CLASSPATH for you for the spark-hive
# or spark-hive-thriftserver name in the executor classpath, the spark.executor.extraClassPath here is redundant.
# The spark.executor.extraClassPath here is just for demonstration, and explicitly telling people you 
# need to be aware of this for the executor classpath
./bin/spark-submit --verbose \
  --master yarn --deploy-mode client \
  --jars $spark_conf/hive-site.xml,$sparksql_hivejars \
  --driver-memory 512M --executor-memory 2048M --executor-cores 3 \
  --driver-class-path $spark_conf/hive-site.xml:$spark_conf/yarnclient-driver-log4j.properties $queue_name \
  --archives hdfs:///user/$USER/apps/$(basename $(readlink -f $HIVE_HOME))-lib.zip#hive \
  --conf spark.yarn.am.extraJavaOptions="-Djava.library.path=/opt/hadoop/lib/native/" \
  --conf spark.driver.extraJavaOptions="-Dlog4j.configuration=yarnclient-driver-log4j.properties -Djava.library.path=/opt/hadoop/lib/native/" \
  --conf spark.eventLog.dir=${spark_event_log_dir}/$USER \
  --conf spark.sql.warehouse.dir=file:///tmp/$USER/spark-warehouse \
  --class SparkSQLTestCase2HiveContextYarnClientApp \
  $spark_test_dir/${app_name}-${app_ver}.jar $spark_home/examples/src/main/resources/kv1.txt spark_hive_test_yarn_client_table

if [ $? -ne "0" ] ; then
  >&2 echo "fail - testing $0 for SparkSQL on HiveQL/HiveContext failed!!"
  exit -4
fi

popd

reset

exit 0


