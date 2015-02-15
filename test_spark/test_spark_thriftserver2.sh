#!/bin/sh -x

# Run the test case as spark
# We will use beeline to test it via the JDBC driver
# /bin/su - spark -c "./test_spark/test_spark_thriftserver2.sh"


curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`

if [ -f "/etc/spark/spark-env.sh" ] ; then
  source /etc/spark/spark-env.sh
fi
kerberos_enable=false
spark_home=$SPARK_HOME
spark_version=$SPARK_VERSION
spark_ts2_listen_port=20000
# Check RPM installation.

spark_installed=$(rpm -qa | grep alti-spark | grep -v test | wc -l)
if [ "x${spark_installed}" = "x0" ] ; then
  >&2 echo "fail - spark not installed, can't continue, exiting"
  exit -1
elif [ "x${spark_installed}" = "x1" ] ; then
  echo "ok - detect one version of spark installed"
  echo "ok - $(rpm -q $(rpm -qa | grep alti-spark)) installed"
else
  >&2 echo "error - detected more than 1 spark installed, please remove one version, currently, testcase doesn't support mutiple version"
  exit -1
fi

if [ "x${spark_home}" = "x" ] ; then
  spark_home=/opt/spark
  echo "ok - applying default location /opt/spark"
  if [ -L "$spark_home" && -d "$spark_home" ] ; then
    >&2 echo "fail - $spark_home does not exist, can't continue, exiting! check spark installation."
    exit -1
  fi
fi

if [ "x${spark_version}" = "x" ] ; then
  if [ "x${SPARK_VERSION}" = "x" ] ; then
    >&2 echo "fail - SPARK_VERSION not set, can't continue, exiting!!!"
    exit -1
  else
    spark_version=$SPARK_VERSION
  fi
fi

source $spark_home/test_spark/init_spark.sh

pushd `pwd`
cd $spark_home/sbin/

echo "ok - starting thriftserver"

ret=$(./start-thriftserver.sh --hiveconf hive.server2.thrift.port=$spark_ts2_listen_port --hiveconf hive.server2.thrift.bind.host=$(hostname) --master yarn-client --queue research --executor-memory 1G --num-executors 4 --executor-cores 2 --driver-memory 1G --conf spark.kryoserializer.buffer.mb=64 --conf spark.locality.wait=10000 --conf spark.shuffle.manager=sort --conf spark.shuffle.consolidateFiles=true=true --conf spark.rdd.compress=true --conf spark.storage.memoryFraction=0.6 --conf spark.sql.inMemoryColumnarStorage.compressed=true --conf spark.sql.inMemoryColumnarStorage.batchSize=10240)
if [ $? -ne "0" ] ; then
  >&2 echo "fail - can't start thriftserver, something went wrong, see $ret"
  exit -3
fi

daemon_str=$(echo $ret | grep -o '/opt/.*')
cat $daemon_str

# Shouldn't take longer then 60 seconds, it took ~ 3-5 seconds on the VPC spec
sleep 60

log_check_ts2="true"
nc_check_ts2="true"
# TBD: This is not a good way to check if it is up and running, however, it's a start. Can check PID, etc as well.
start_log_line=$(grep -n "Starting SparkContext" /home/spark/Hadooplogs/spark/logs/spark.log | tail -n 1 | cut -d":" -f1)
if [ "x${start_log_line}" = "x" ] ; then
  >&2 echo "warn - log rotated so fast? can't find the starting string to search for."
else
  ts2_ret_str=$(tail -n +${start_log_line} /home/spark/Hadooplogs/spark/logs/spark.log | grep -i 'ThriftBinaryCLIService listening on')
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

if [ "x${log_check_ts2}" = "false" -a "x${log_check_ts2}" = "false" ] ; then
  >&2 echo "fail - both log check and port check failed, Spark ThriftServer2 is not running, stopping it manuall, and please check!"
  ./stop-thriftserver.sh 
  exit -5
fi

# TBD: A quick test to see if Spark ThriftServer2 is able to talk to Hive metastore to list tables
jdbc_ret=$(beeline -u "jdbc:hive2://$(hostname):$spark_ts2_listen_port" -n alti-test-01 -p "" -e "show tables;" 2>&1)
error_str=$(echo $jdbc_ret | grep -io "Error:" | head -n 1 | tr [:upper:] [:lower:])
if [ "x${error_set}" = "xerror:" ] ; then
  >&2 echo "fail - beeline can't get Hive metadata via Spark ThriftServer2 due to $jdbc_ret"
fi

# TBD: create a simple table via Hive command, and see if Spark TS2 can see it and query it
# TBD: To query a single tables with results


# Done testing, stop the service
./stop-thriftserver.sh 

popd

reset

exit 0


