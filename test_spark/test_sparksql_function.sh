#!/bin/sh -x

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
spark_home=$SPARK_HOME
spark_conf=""

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

. $spark_home/test_spark/init_spark.sh

spark_conf=$SPARK_CONF_DIR

if [ "x${spark_conf}" = "x" ] ; then
  spark_conf=/etc/spark
fi
echo "ok - applying Spark conf $spark_conf"


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
hadoop_snappy_jar=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "snappy-java-*.jar")
hadoop_lzo_jar=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "hadoop-lzo-*.jar")
guava_jar=$(find $HIVE_HOME/lib/ -type f -name "guava-*.jar")
spark_files=$(find $hive_home/lib/ -type f -name "datanucleus*.jar" | tr -s '\n' ',')
spark_opts_extra="${spark_files}$mysql_jars,$hadoop_lzo_jar,$hadoop_snappy_jar,$guava_jar"

spark_files="$spark_files$mysql_jars,${spark_conf}/hive-site.xml"

spark_event_log_dir=$(grep 'spark.eventLog.dir' ${spark_conf}/spark-defaults.conf | tr -s ' ' '\t' | cut -f2)

table_uuid=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
db_name="spark_test_db_${table_uuid}"
table_name="spark_hive_test_table_${table_uuid}"
new_table_name="new_spark_hive_test_table_${table_uuid}"
orc_table_name="orc_spark_hive_test_table_${table_uuid}"
parquet_table_name="parquet_spark_hive_test_table_${table_uuid}"

test_create_database_sql1="CREATE DATABASE IF NOT EXISTS ${db_name}"
test_create_table_sql1="CREATE TABLE $table_name (key INT, value STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE"
test_alter_table_sql1="ALTER TABLE $table_name RENAME TO $new_table_name"
test_truncate_table_sql1="TRUNCATE TABLE $new_table_name"
test_load_data_sql1="LOAD DATA LOCAL INPATH '${spark_test_dir}/test_data/sparksql_testdata2.csv' INTO TABLE $new_table_name"
test_select_sql1="SELECT SUM(key) FROM $new_table_name"
# Only works with Hive 1.2.x. Bug on Hive 0.13.1
test_create_orc_sql1="CREATE TABLE $orc_table_name STORED AS ORC AS SELECT key,value FROM $new_table_name"
test_create_parquet_sql1="CREATE TABLE $parquet_table_name STORED AS PARQUET AS SELECT * FROM $new_table_name"
test_select_orc_sql1="SELECT SUM(key) FROM $orc_table_name"
test_select_parquet_sql1="SELECT SUM(key) FROM $parquet_table_name"
test_drop_table_sql1="DROP TABLE $new_table_name"
test_drop_orc_table_sql1="DROP TABLE $orc_table_name"
test_drop_parquet_table_sql1="DROP TABLE $parquet_table_name"

hadoop_ver=$(hadoop version | head -n 1 | grep -o 2.*.* | tr -d '\n')
echo "ok - detected hadoop version $hadoop_ver for testing. CTAS does not work on Hive 0.13.1"
# queue_name="--queue interactive"
queue_name=""
sql_ret_code=""
if [ "x${hadoop_ver}" = "x2.4.1" ] ; then
  ./bin/spark-sql --verbose --master yarn --deploy-mode client --driver-memory 512M --executor-memory 1G --executor-cores 2 --conf spark.eventLog.dir=${spark_event_log_dir}$USER/ --driver-java-options "-XX:MaxPermSize=1024M -Djava.library.path=/opt/hadoop/lib/native/" --driver-class-path hive-site.xml --files $spark_files --jars $spark_opts_extra $queue_name -e "$test_create_database_sql1; USE $db_name; $test_create_table_sql1 ; $test_alter_table_sql1 ; $test_truncate_table_sql1 ; $test_load_data_sql1 ; $test_select_sql1 ; $test_drop_table_sql1 ; "
  sql_ret_code=$?
elif [ "x${hadoop_ver}" = "x2.7.1" ] ; then
  ./bin/spark-sql --verbose --master yarn --deploy-mode client --driver-memory 512M --executor-memory 1G --executor-cores 2 --conf spark.eventLog.dir=${spark_event_log_dir}$USER/ --driver-java-options "-XX:MaxPermSize=1024M -Djava.library.path=/opt/hadoop/lib/native/" --driver-class-path hive-site.xml --files $spark_files --jars $spark_opts_extra $queue_name -e "$test_create_database_sql1; USE $db_name; $test_create_table_sql1 ; $test_alter_table_sql1 ; $test_truncate_table_sql1 ; $test_load_data_sql1 ; $test_create_orc_sql1; $test_create_parquet_sql1; $test_select_sql1 ; $test_select_orc_sql1; $test_select_parquet_sql1; $test_drop_table_sql1 ; $test_drop_orc_table_sql1; $test_drop_parquet_table_sql1; "
  sql_ret_code=$?
else
  echo "fatal - hadoop version not supported, neither 2.7.1 nor 2.4.1"
  exit -5
fi

if [ $? -ne "0" ] ; then
  echo "fail - testing shell for SparkSQL on HiveQL/HiveContext failed!!"
  exit -4
fi

popd

exit 0


