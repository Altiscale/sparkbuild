#!/bin/sh -x

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
testcase_shell_file_01="$curr_dir/sparkshell_examples.grapx.txt"
spark_home=${SPARK_HOME:='/opt/spark'}
spark_conf=""
spark_version=$SPARK_VERSION

source $spark_home/test_spark/init_spark.sh

# Default SPARK_HOME location is already checked by init_spark.sh
if [ "x${spark_home}" = "x" ] ; then
  spark_home=${spark_home}
  echo "ok - applying default location $spark_home"
elif [ ! -d "$spark_home" ] ; then
  >&2 echo "fail - $spark_home does not exist, please check you Spark installation, exinting!"
  exit -2
else
  echo "ok - applying Spark home $spark_home"
fi
# Default SPARK_CONF_DIR is already checked by init_spark.sh
spark_conf=$SPARK_CONF_DIR
if [ "x${spark_conf}" = "x" ] ; then
  spark_conf=/etc/spark
elif [ ! -d "$spark_conf" ] ; then
  >&2 echo "fail - $spark_conf does not exist, please check you Spark installation or your SPARK_CONF_DIR env, exiting!"
  exit -2
else
  echo "ok - applying spark config directory $spark_conf"
fi
echo "ok - applying Spark conf $spark_conf"
 
spark_version=$SPARK_VERSION
if [ "x${spark_version}" = "x" ] ; then
  >&2 echo "fail - spark_version can not be identified, is end SPARK_VERSION defined? Exiting!"
  exit -2
fi

if [ ! -f "$testcase_shell_file_01"  ] ; then
  >&2 echo "fail - missing testcase for spark, can't continue, exiting"
  exit -2
fi

pushd `pwd`
cd $spark_home
hdfs dfs -mkdir -p spark/test/graphx/followers
hdfs dfs -put ${spark_home}/graphx/data/followers.txt spark/test/graphx/followers/
hdfs dfs -put ${spark_home}/graphx/data/users.txt spark/test/graphx/followers/

echo "ok - testing spark REPL shell with various algorithm"
# The guava JAR here does not match the Spark's pom.xml which is looking for version 14.0.1
# Hive comes with Guava 11.0.2
spark_opts_extra=""

spark_event_log_dir=$(grep 'spark.eventLog.dir' ${spark_conf}/spark-defaults.conf | tr -s ' ' '\t' | cut -f2)

# queue_name="--queue interactive"
queue_name=""
./bin/spark-shell --verbose --master yarn --deploy-mode client --driver-memory 1536M --conf spark.eventLog.dir=${spark_event_log_dir}$USER/ $spark_opts_extra $queue_name << EOT
`cat $testcase_shell_file_01`
EOT

if [ $? -ne "0" ] ; then
  >&2 echo "fail - testing shell for various algorithm failed!"
  exit -3
fi

popd

reset

exit 0


