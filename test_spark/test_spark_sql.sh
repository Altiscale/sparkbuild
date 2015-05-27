#!/bin/sh -x

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`

spark_home=$SPARK_HOME
spark_test_dir=$spark_home/test_spark/

if [ -f "$curr_dir/pom.xml" ] ; then
  spark_test_dir=$curr_dir
fi

if [ "x${spark_home}" = "x" ] ; then
  spark_home=/opt/spark
  if [ ! -f "$curr_dir/pom.xml" ] ; then
    spark_test_dir=$spark_home/test_spark/
  fi
  echo "ok - applying default location /opt/spark"
fi

source $spark_home/test_spark/init_spark.sh

if [ ! -d $spark_home ] ; then
  echo "fail - $spark_home doesn't exist, can't continue, is spark installed correctly?"
  exit -1
fi

pushd `pwd`
cd $spark_home
hdfs dfs -mkdir -p spark/test/resources
hdfs dfs -copyFromLocal /opt/spark/examples/src/main/resources/* spark/test/resources/

echo "ok - testing spark SQL shell with simple queries"

app_name=`grep "<artifactId>.*</artifactId>" pom.xml | cut -d">" -f2- | cut -d"<" -f1  | head -n 1`
app_ver=`grep "<version>.*</version>" pom.xml | cut -d">" -f2- | cut -d"<" -f1 | head -n 1`

if [ ! -f "$spark_test_dir/${app_name}-${app_ver}.jar" ] ; then
  echo "fail - $spark_test_dir/${app_name}-${app_ver}.jar test jar does not exist, cannot continue testing, failing!"
  exit -3
fi

spark_event_log_dir=$(grep 'spark.eventLog.dir' /etc/spark/spark-defaults.conf | tr -s ' ' '\t' | cut -f2)

./bin/spark-submit --queue research --verbose --master yarn --deploy-mode cluster --driver-java-options "-Djava.library.path=/opt/hadoop/lib/native/" --conf spark.eventLog.dir=${spark_event_log_dir}$USER/ --class SparkSQLTestCase1SQLContextApp $spark_test_dir/${app_name}-${app_ver}.jar

if [ $? -ne "0" ] ; then
  echo "fail - testing shell for SparkSQL SQLContext failed!!"
  exit -4
fi

popd

exit 0


