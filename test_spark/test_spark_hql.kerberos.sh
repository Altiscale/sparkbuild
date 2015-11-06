#!/bin/sh -x

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
spark_home=$SPARK_HOME

if [ "x${spark_home}" = "x" ] ; then
  # rpm -ql $(rpm -qa --last | grep alti-spark | sort | head -n 1 | cut -d" " -f1) | grep -e '^/opt/alti-spark' | cut -d"/" -f1-3
  spark_home=/opt/spark
  if [ ! -f "$curr_dir/pom.xml" ] ; then
    spark_test_dir=$spark_home/test_spark/
  fi
  echo "ok - applying default location /opt/spark"
fi

source $spark_home/test_spark/init_spark.sh

spark_version=$SPARK_VERSION
spark_test_dir=$spark_home/test_spark/

if [ "x${HIVE_HOME}" = "x" ] ; then
  HIVE_HOME=/opt/hive
fi

if [ -f "$curr_dir/pom.xml" ] ; then
  spark_test_dir=$curr_dir
fi

pushd `pwd`
cd $spark_home
# Deploy the test data we need from the current user that is running the test case
# User does not share test data with other users
hdfs dfs -mkdir -p spark/test/resources
hdfs dfs -put /opt/spark/examples/src/main/resources/kv1.txt spark/test/resources/

# Perform sanity check on required files in test case
if [ ! -f "$spark_home/examples/src/main/resources/kv1.txt" ] ; then
  echo "fail - missing test data $spark_home/examples/src/main/resources/kv1.txt to load, did the examples directory structure changed?"
  exit -3
fi

echo "ok - testing spark SQL shell with simple queries"

app_name=`grep "<artifactId>.*</artifactId>" $spark_test_dir/pom.xml | cut -d">" -f2- | cut -d"<" -f1  | head -n 1`
app_ver=`grep "<version>.*</version>" $spark_test_dir/pom.xml | cut -d">" -f2- | cut -d"<" -f1 | head -n 1`

if [ ! -f "$spark_test_dir/${app_name}-${app_ver}.jar" ] ; then
  echo "fail - $spark_test_dir/${app_name}-${app_ver}.jar test jar does not exist, cannot continue testing, failing!"
  exit -3
fi

mysql_jars=$(find /opt/mysql-connector/ -type f -name "mysql-*.jar")
hadoop_snappy_jar=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "snappy-java-*.jar")
hadoop_lzo_jar=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "hadoop-lzo-*.jar")
guava_jar=$(find $HIVE_HOME/lib/ -type f -name "guava-*.jar")
datanucleus_files=$(find $HIVE_HOME/lib/ -type f -name "datanucleus*.jar" | tr -s '\n' ',')
spark_opts_extra="/etc/spark/hive-site.xml,${datanucleus_files}$mysql_jars,$hadoop_lzo_jar,$hadoop_snappy_jar,$guava_jar"
# spark_files="${datanucleus_files}$mysql_jars,/etc/spark/hive-site.xml"

spark_event_log_dir=$(grep 'spark.eventLog.dir' /etc/spark/spark-defaults.conf | tr -s ' ' '\t' | cut -f2)

# queue_name="--queue interactive"
queue_name=""
./bin/spark-submit --verbose --master yarn --deploy-mode client --driver-memory 512M --executor-memory 2048M --executor-cores 3 --conf spark.eventLog.dir=${spark_event_log_dir}$USER/ --driver-java-options "-XX:MaxPermSize=1024M -Djava.library.path=/opt/hadoop/lib/native/" --driver-class-path hive-site.xml $queue_name --jars $spark_opts_extra --class SparkSQLTestCase2HiveContextYarnClusterApp $spark_test_dir/${app_name}-${app_ver}.jar

if [ $? -ne "0" ] ; then
  echo "fail - testing shell for SparkSQL on HiveQL/HiveContext failed!!"
  exit -4
fi

popd

reset

exit 0


