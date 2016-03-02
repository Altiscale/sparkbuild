#!/bin/sh -x

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
spark_home=${SPARK_HOME:='/opt/spark'}
spark_conf=$SPARK_CONF_DIR

source $spark_home/test_spark/init_spark.sh

# Default SPARK_HOME location is already checked by init_spark.sh
if [ "x${spark_home}" = "x" ] ; then
  spark_home=/opt/spark
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

spark_test_dir=$spark_home/test_spark/

hive_home=$HIVE_HOME
if [ "x${hive_home}" = "x" ] ; then
  hive_home=/opt/hive
fi

if [ -f "$curr_dir/pom.xml" ] ; then
  spark_test_dir=$curr_dir
fi

pushd `pwd`
cd $spark_home

echo "ok - testing spark SQL shell with simple queries"

app_name=`grep "<artifactId>.*</artifactId>" $spark_test_dir/pom.xml | cut -d">" -f2- | cut -d"<" -f1  | head -n 1`
app_ver=`grep "<version>.*</version>" $spark_test_dir/pom.xml | cut -d">" -f2- | cut -d"<" -f1 | head -n 1`

if [ ! -f "$spark_test_dir/${app_name}-${app_ver}.jar" ] ; then
  >&2 echo "fail - $spark_test_dir/${app_name}-${app_ver}.jar test jar does not exist, cannot continue testing, failing!"
  exit -3
fi

hive_jars=$(find $HIVE_HOME/lib/ -type f -name "*.jar" | tr -s '\n' ',')
hive_jars_colon=$(find $HIVE_HOME/lib/ -type f -name "*.jar" | tr -s '\n' ':')

spark_event_log_dir=$(grep 'spark.eventLog.dir' /etc/spark/spark-defaults.conf | tr -s ' ' '\t' | cut -f2)

# queue_name="--queue interactive"
queue_name=""
./bin/spark-sql --verbose --master yarn --deploy-mode client --driver-memory 512M --executor-memory 1G --executor-cores 2 --conf spark.eventLog.dir=${spark_event_log_dir}/$USER --conf spark.yarn.dist.files=/etc/spark/hive-site.xml,$hive_jars --driver-java-options "-XX:MaxPermSize=1024M -Djava.library.path=/opt/hadoop/lib/native/" --driver-class-path hive-site.xml:$hive_jars_colon $queue_name

if [ $? -ne "0" ] ; then
  >&2 echo "fail - testing shell for SparkSQL on HiveQL/HiveContext failed!!"
  exit -4
fi

popd

exit 0


