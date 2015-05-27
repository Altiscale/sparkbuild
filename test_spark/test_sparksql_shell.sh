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

if [ ! -d $spark_home ] ; then
  echo "fail - $spark_home doesn't exist, can't continue, is spark installed correctly?"
  exit -1
fi

source $spark_home/test_spark/init_spark.sh

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
  echo "fail - $spark_test_dir/${app_name}-${app_ver}.jar test jar does not exist, cannot continue testing, failing!"
  exit -3
fi

mysql_jars=$(find /opt/mysql-connector/ -type f -name "mysql-*.jar")
spark_opts_extra=
for i in `find $hive_home/lib/ -type f -name "datanucleus*.jar"`
do
  spark_opts_extra="$spark_opts_extra --jars $i"
done
hadoop_snappy_jar=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "snappy-java-*.jar")
hadoop_lzo_jar=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "hadoop-lzo-*.jar")
spark_opts_extra="$spark_opts_extra --jars $mysql_jars,$hadoop_lzo_jar,$hadoop_snappy_jar"

spark_files=$(find $hive_home/lib/ -type f -name "datanucleus*.jar" | tr -s '\n' ',')
spark_files="$spark_files$mysql_jars,/etc/spark/hive-site.xml"

spark_event_log_dir=$(grep 'spark.eventLog.dir' /etc/spark/spark-defaults.conf | tr -s ' ' '\t' | cut -f2)

./bin/spark-sql --verbose --queue research --conf spark.eventLog.dir=${spark_event_log_dir}$USER/ --driver-java-options "-XX:MaxPermSize=8192M -Djava.library.path=/opt/hadoop/lib/native/" --driver-class-path hive-site.xml --master yarn --deploy-mode client --driver-memory 1G --executor-memory 1G --executor-cores 2 $spark_opts_extra 

if [ $? -ne "0" ] ; then
  echo "fail - testing shell for SparkSQL on HiveQL/HiveContext failed!!"
  exit -4
fi

popd

exit 0


