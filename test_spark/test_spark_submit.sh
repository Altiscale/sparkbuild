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

pushd `pwd`
cd $spark_home

echo "ok - testing spark REPL shell with various algorithm"

SPARK_EXAMPLE_JAR=$(find ${spark_home}/lib/spark-examples_${SPARK_SCALA_VERSION}.jar)

if [ ! -f "${SPARK_EXAMPLE_JAR}" ] ; then
  >&2 echo "fail - cannot detect example jar for this $spark_version $spark_installed build!"
  exit -2
fi

spark_event_log_dir=$(grep 'spark.eventLog.dir' ${spark_conf}/spark-defaults.conf | tr -s ' ' '\t' | cut -f2)

# queue_name="--queue interactive"
queue_name=""
./bin/spark-submit --verbose \
  --master yarn --deploy-mode cluster $queue_name \
  --conf spark.eventLog.dir=${spark_event_log_dir}/$USER \
  --conf spark.driver.extraJavaOptions="-Dlog4j.configuration=yarncluster-driver-log4j.properties" \
  --conf spark.driver.extraClassPath=yarncluster-driver-log4j.properties \
  --conf spark.executor.extraJavaOptions="-Dlog4j.configuration=executor-log4j.properties -XX:+PrintReferenceGC -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintAdaptiveSizePolicy -Djava.library.path=/opt/hadoop/lib/native/" \
  --class org.apache.spark.examples.SparkPi \
  "${SPARK_EXAMPLE_JAR}"

if [ $? -ne "0" ] ; then
  >&2 echo "fail - testing $0 for various algorithm failed!"
  exit -3
fi

popd

exit 0


