#!/bin/sh -x

# Run the test case as spark
# We will use beeline to test it via the JDBC driver
# /bin/su - spark -c "./test_spark/test_spark_thriftserver2.sh"


curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
spark_home=$SPARK_HOME
spark_logs=""

if [ "x${spark_home}" = "x" ] ; then
  spark_home=/opt/spark
  echo "ok - applying default location /opt/spark"
  if [ -L "$spark_home" && -d "$spark_home" ] ; then
    >&2 echo "fail - $spark_home does not exist, can't continue, exiting! check spark installation."
    exit -1
  fi
fi

source $spark_home/test_spark/init_spark.sh

spark_version=$SPARK_VERSION
spark_ts2_listen_port=20000
running_user=`whoami`
# This needs to align with /etc/spark/log4j.properties
spark_logs=$spark_home/logs/$running_user/spark.log

if [ "x${spark_version}" = "x" ] ; then
  if [ "x${SPARK_VERSION}" = "x" ] ; then
    >&2 echo "fail - SPARK_VERSION not set, can't continue, exiting!!!"
    exit -1
  else
    spark_version=$SPARK_VERSION
  fi
fi


# Just inherit what is defined in spark-daemon.sh and load-spark-env.sh and /etc/spark/spark-env.sh
# if [ "$SPARK_IDENT_STRING" = "" ]; then
#   export SPARK_IDENT_STRING="$USER"
# fi
if [ "$SPARK_PID_DIR" = "" ]; then
  SPARK_PID_DIR=/tmp
fi

pushd `pwd`
cd $spark_home/sbin/
mysql_jars=$(find /opt/mysql-connector/ -type f -name "mysql-*.jar")
spark_opts_extra=
for i in `find $hive_home/lib/ -type f -name "datanucleus*.jar"`
do
  spark_opts_extra="$spark_opts_extra $i"
done
hadoop_snappy_jar=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "snappy-java-*.jar")
hadoop_lzo_jar=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "hadoop-lzo-*.jar")
spark_opts_extra=$(echo "$spark_opts_extra $mysql_jars,$hadoop_lzo_jar,$hadoop_snappy_jar" | tr -s ' ' ' ' | tr -s ' ' ',')

spark_files=$(find $hive_home/lib/ -type f -name "datanucleus*.jar" | tr -s '\n' ',')
spark_files="$spark_files$mysql_jars,/etc/spark/hive-site.xml"


spark_event_log_dir=$(grep 'spark.eventLog.dir' /etc/spark/spark-defaults.conf | tr -s ' ' '\t' | cut -f2)

echo "ok - starting thriftserver"

ret=$(./start-thriftserver.sh --jars $spark_opts_extra --files $spark_files --hiveconf hive.server2.thrift.port=$spark_ts2_listen_port --hiveconf hive.server2.thrift.bind.host=$(hostname) --master yarn-client --queue research --executor-memory 1G --num-executors 4 --executor-cores 2 --driver-memory 1G --conf spark.locality.wait=10000 --conf spark.shuffle.manager=sort --conf spark.shuffle.consolidateFiles=true --conf spark.rdd.compress=true --conf spark.storage.memoryFraction=0.6 --conf spark.sql.inMemoryColumnarStorage.compressed=true --conf spark.sql.inMemoryColumnarStorage.batchSize=10240 --conf spark.eventLog.dir=${spark_event_log_dir}$USER/)
if [ $? -ne "0" ] ; then
  >&2 echo "fail - can't start thriftserver, something went wrong, see $ret"
  exit -3
fi

daemon_str=$(echo $ret | grep -o '/opt/.*')
cat $daemon_str
spark_ts2_pid_str=$SPARK_PID_DIR/$(echo $(basename $daemon_str) | sed "s/-$(hostname).out$/\.pid/")

# Shouldn't take longer then 60 seconds, it took ~ 3-5 seconds on the VPC spec
sleep 60

if [ -f $spark_ts2_pid_str ] ; then
  echo "ok - found spark PID file at $spark_ts2_pid_str"
else
  >&2 echo "warn - PID file $spark_ts2_pid_str not found, did the location change? or something went wrong?"
fi

ts2_yarn_app_id=""
log_check_ts2="true"
pid_check_ts2="true"
nc_check_ts2="true"
# TBD: This is not a good way to check if it is up and running, however, it's a start. Can check PID, etc as well.
start_log_line=$(grep -n "Starting SparkContext" $spark_logs | tail -n 1 | cut -d":" -f1)
if [ "x${start_log_line}" = "x" ] ; then
  >&2 echo "warn - log rotated so fast? can't find the starting string to search for."
else
  ts2_ret_str=$(tail -n +${start_log_line} $spark_logs | grep -i 'ThriftBinaryCLIService listening on')
  ts2_yarn_app_id=$(tail -n +${start_log_line} $spark_logs | grep -io 'Submitted application .*' | tail -n 1 | cut -d" " -f3)
  if [ "x${ts2_ret_str}" = "x" ] ; then
    >&2 echo "fail - something is wrong, can't detect service listening string 'ThriftBinaryCLIService listening on', the service is taking longer then 60 seconds to start? This is odd on a fresh VPC, please manually check Spark TS2!"
    >&2 echo "fail - stopping spark thriftserver2 due to unexpected performance or error!"
    log_check_ts2="false"
  fi
fi

# Use netstat since this is installed in all default Linux box. nc/telnet are not default utilities for PROD server
nc_ret=$(netstat -lt | grep $spark_ts2_listen_port)
if [ "x${nc_ret}" = "x" ] ; then
  nc_check_ts2="false"
fi

spark_pid=$(cat $spark_ts2_pid_str | tr -d '\n')
pid_ret=$(ps -p $spark_pid > /dev/null)
if [ "x${pid_ret}" = "x0" ] ; then
  pid_check_ts2="false"
  >&2  echo "fail - Spark ThriftServer2 PID $spark_pid NOT found from file $spark_ts2_pid_str, Spark TS2 not running!"
else
  echo "ok - Spark ThriftServer2 PID $spark_pid found"
fi

if [ "x${log_check_ts2}" = "false" -a "x${log_check_ts2}" = "false" -a "x${pid_check_ts2}" = "xfalse" ] ; then
  >&2 echo "fail - all pid check, log check and port check failed, Spark ThriftServer2 is not running, stopping it, and please check!"
  >&2 echo "fail - printing potential logs from YARN from applicationId $ts2_yarn_app_id"
  >&2 yarn logs -applicationId $ts2_yarn_app_id
  ./stop-thriftserver.sh
  exit -5
fi

# TBD: A quick test to see if Spark ThriftServer2 is able to talk to Hive metastore to list tables
jdbc_ret=$(beeline -u "jdbc:hive2://$(hostname):$spark_ts2_listen_port" -n alti-test-01 -p "" -e "show tables;" 2>&1)
error_str=$(echo $jdbc_ret | grep -io "Error:" | head -n 1 | tr [:upper:] [:lower:])
if [ "x${error_str}" = "xerror:" ] ; then
  >&2 echo "fail - beeline can't get Hive metadata via Spark ThriftServer2 due to $jdbc_ret"
else
  echo "ok - query Hive metastore successfully, we see: $jdbc_ret"
fi

# This table spark_hive_test_yarn_cluster_table should be created prior to this test case
# If not, then your Spark is not well tested nor deployed correctly, BE AWARE.
jdbc_ret=$(beeline -u "jdbc:hive2://$(hostname):$spark_ts2_listen_port" -n alti-test-01 -p "" -e "SELECT COUNT(*) FROM spark_hive_test_yarn_cluster_table;" 2>&1)
error_str=$(echo $jdbc_ret | grep -io "Error:" | head -n 1 | tr [:upper:] [:lower:])
if [ "x${error_str}" = "xerror:" ] ; then
  >&2 echo "fail - beeline can't query hive table spark_hive_test_yarn_cluster_table via Spark ThriftServer2 due to $jdbc_ret"
else
  echo "ok - query Hive table spark_hive_test_yarn_cluster_table successfully, we see: $jdbc_ret"
fi

# Done testing, stop the service. Not expecting a lot of data from YARN log
./stop-thriftserver.sh
yarn_ret=$(2>/dev/null yarn application -status $ts2_yarn_app_id | grep 'State : FINISHED' | tr -d '\t' | tr -d ' ' | tr [:upper:] [:lower:] | head -n 1)
if [ "x${yarn_ret}" = "xstate:finished" ] ; then
  echo "ok - test completed, printing last 100 lines from YARN log for record"
  yarn logs -applicationId $ts2_yarn_app_id | tail -n 100
else
  >&2 echo "fail - Spark TS2 YARN application did not end with State FINISHED, something is wrong, printing all logs for debugging!"
  yarn logs -applicationId $ts2_yarn_app_id
fi

popd

exit 0


