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

SPARK_EXAMPLE_JAR=$(find ${spark_home}/examples/target/spark-examples_*-${spark_version}.jar)

if [ ! -f "${SPARK_EXAMPLE_JAR}" ] ; then
  >&2 echo "fail - cannot detect example jar for this $spark_version $spark_installed build!"
  exit -2
fi

spark_event_log_dir=$(grep 'spark.eventLog.dir' ${spark_conf}/spark-defaults.conf | tr -s ' ' '\t' | cut -f2)

# To enable Spark Shuffle and dynamic container, we need to add the following config
# For this examples
# spark.shuffle.service.enabled true
# spark.dynamicAllocation.enabled      true
# spark.dynamicAllocation.executorIdleTimeout 60
# spark.dynamicAllocation.cachedExecutorIdleTimeout 120
# spark.dynamicAllocation.maxExecutors 6
# spark.dynamicAllocation.minExecutors 1
# spark.dynamicAllocation.schedulerBacklogTimeout 10
# Don't define the following properties, this will honor spark.dynamicAllocation.minExecutors
# spark.dynamicAllocation.initialExecutors

spark_shuffle_conf="--conf spark.shuffle.service.enabled=true --conf spark.dynamicAllocation.enabled=true --conf spark.dynamicAllocation.executorIdleTimeout=60 --conf spark.dynamicAllocation.cachedExecutorIdleTimeout=120 --conf spark.dynamicAllocation.maxExecutors=6 --conf spark.dynamicAllocation.minExecutors=1 --conf spark.dynamicAllocation.schedulerBacklogTimeout=10"

# queue_name="--queue interactive"
queue_name=""
# The Pi example, to see additional containers being allocated, try a higher number then 3000
# You should see it expands from 1 (min) executor to 5 (max) executors in our example.
./bin/spark-submit --verbose \
  --master yarn --deploy-mode cluster $queue_name \
  $spark_shuffle_conf \
  --conf spark.eventLog.dir=${spark_event_log_dir}/$USER \
  --class org.apache.spark.examples.SparkPi \
  "${SPARK_EXAMPLE_JAR}" 3000

if [ $? -ne "0" ] ; then
  >&2 echo "fail - testing $0 spark shuffle with SparkPi failed!"
  exit -3
fi

popd

# Desired output what you will see from the dynamic container allocation, for example
# the spark job YARN app id is application_1458335196063_0024, you can see the following in the yarn AM log
#
# $ yarn logs -applicationId application_1458335196063_0024 | grep spark.ExecutorAllocationManager   
# 16/03/18 22:23:49 INFO client.RMProxy: Connecting to ResourceManager at rm-alee-ci-3702.test.altiscale.com/10.252.7.39:8032
# 16/03/18 22:14:02 INFO spark.ExecutorAllocationManager: New executor 1 has registered (new total is 1)
# 16/03/18 22:14:13 INFO spark.ExecutorAllocationManager: Requesting 1 new executor because tasks are backlogged (new desired total will be 2)
# 16/03/18 22:14:23 INFO spark.ExecutorAllocationManager: Requesting 2 new executors because tasks are backlogged (new desired total will be 4)
# 16/03/18 22:14:25 INFO spark.ExecutorAllocationManager: New executor 2 has registered (new total is 2)
# 16/03/18 22:14:33 INFO spark.ExecutorAllocationManager: Requesting 2 new executors because tasks are backlogged (new desired total will be 6)
# 16/03/18 22:14:40 INFO spark.ExecutorAllocationManager: New executor 4 has registered (new total is 3)
# 16/03/18 22:14:41 INFO spark.ExecutorAllocationManager: New executor 3 has registered (new total is 4)
# 16/03/18 22:14:53 INFO spark.ExecutorAllocationManager: New executor 6 has registered (new total is 5)
# 16/03/18 22:14:54 INFO spark.ExecutorAllocationManager: New executor 5 has registered (new total is 6)
# 16/03/18 22:15:38 INFO spark.ExecutorAllocationManager: Lowering target number of executors to 1 (previously 6) because not all requested executors are actually needed

exit 0
