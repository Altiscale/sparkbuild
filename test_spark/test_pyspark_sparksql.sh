#!/bin/sh -x

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`

spark_home=$SPARK_HOME
spark_conf=""
spark_version=$SPARK_VERSION
spark_test_dir="$spark_home/test_spark"

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
if [ ! -f "$spark_test_dir/pom.xml" ] ; then
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

mysql_jars=$(find /opt/mysql-connector/ -type f -name "mysql-*.jar")
hadoop_snappy_jar=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "snappy-java-*.jar")
hadoop_lzo_jar=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "hadoop-lzo-*.jar")
spark_opts_extra=" --jars $hadoop_lzo_jar,$hadoop_snappy_jar"
spark_files=$(find $hive_home/lib/ -type f -name "datanucleus*.jar" | tr -s '\n' ',')
spark_files="$spark_files$mysql_jars,${spark_conf}/hive-site.xml"

spark_event_log_dir=$(grep 'spark.eventLog.dir' ${spark_conf}/spark-defaults.conf | tr -s ' ' '\t' | cut -f2)

# pyspark only supports yarn-client mode now
# queue_name="--queue interactive"
queue_name=""
./bin/spark-submit --verbose --master yarn --deploy-mode client --driver-class-path $hadoop_lzo_jar:$hadoop_snappy_jar $queue_name $spark_opts_extra $queue_name --conf spark.eventLog.dir=${spark_event_log_dir}$USER/ --files $spark_files --py-files $spark_home/test_spark/src/main/python/pyspark_hql.py $spark_home/test_spark/src/main/python/pyspark_hql.py

if [ $? -ne "0" ] ; then
  >&2 echo "fail - testing shell for Python SparkSQL on HiveQL/HiveContext failed!!"
  exit -4
fi

popd

reset

exit 0


