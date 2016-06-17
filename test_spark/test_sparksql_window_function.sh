#!/bin/sh -x

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
spark_test_dir=""

hive_home=$HIVE_HOME
if [ "x${hive_home}" = "x" ] ; then
  hive_home=/opt/hive
fi

if [ ! -f "$spark_test_dir/pom.xml" ] ; then
  echo "warn - correcting test directory from $spark_test_dir to $curr_dir"
  spark_test_dir=$curr_dir
fi

pushd `pwd`
cd $spark_home

echo "ok - Testing windowing function with spark-sql"

app_name=`grep "<artifactId>.*</artifactId>" $spark_test_dir/pom.xml | cut -d">" -f2- | cut -d"<" -f1  | head -n 1`
app_ver=`grep "<version>.*</version>" $spark_test_dir/pom.xml | cut -d">" -f2- | cut -d"<" -f1 | head -n 1`

if [ ! -f "$spark_test_dir/${app_name}-${app_ver}.jar" ] ; then
  >&2 echo "fail - $spark_test_dir/${app_name}-${app_ver}.jar test jar does not exist, cannot continue testing, failing!"
  exit -3
fi

spark_event_log_dir=$(grep 'spark.eventLog.dir' ${spark_conf}/spark-defaults.conf | tr -s ' ' '\t' | cut -f2)

table_uuid=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
db_name="spark_test_db_${table_uuid}"
echo "[Window] dn_name=$db_name"
table_name="test_windowing_${table_uuid}"
echo "[Window] table_name=$table_name"

create_database_sql="CREATE DATABASE IF NOT EXISTS ${db_name}"
create_table_sql="CREATE TABLE $table_name (name STRING, country STRING, revenue INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE"
load_data_sql="LOAD DATA LOCAL INPATH '${spark_test_dir}/test_data/sales' INTO TABLE $table_name"

test_window_sql1="SELECT * FROM ( 
              SELECT name, country, revenue,
              RANK() over 
                  (PARTITION BY country
                  ORDER BY revenue DESC) as rank
              FROM $table_name) t
              WHERE rank=1;"

test_window_sql2="SELECT name, country, revenue, PERCENT_RANK() over (PARTITION by country ORDER BY revenue DESC) AS percent_rank FROM $table_name;"

drop_table_sql="DROP TABLE $table_name"
drop_database_sql="DROP DATABASE IF EXISTS ${db_name}"

hadoop_ver=$(hadoop version | head -n 1 | grep -o 2.*.* | tr -d '\n')
sparksql_hivejars="$spark_home/sql/hive/target/spark-hive_${SPARK_SCALA_VERSION}-${spark_version}.jar"
sparksql_hivethriftjars="$spark_home/sql/hive-thriftserver/target/spark-hive-thriftserver_${SPARK_SCALA_VERSION}-${spark_version}.jar"
hive_jars=$sparksql_hivejars,$sparksql_hivethriftjars,$(find $HIVE_HOME/lib/ -type f -name "*.jar" | tr -s '\n' ',')
hive_jars_colon=$sparksql_hivejars:$sparksql_hivethriftjars:$(find $HIVE_HOME/lib/ -type f -name "*.jar" | tr -s '\n' ':')

echo "ok - detected hadoop version $hadoop_ver for testing. CTAS does not work on Hive 0.13.1"
# queue_name="--queue interactive"
queue_name=""
sql_ret_code=""
# Also demonstrate how to migrate command from Spark 1.4/1.5 to 1.6+
if [ "x${hadoop_ver}" = "x2.4.1" ] ; then
  ./bin/spark-sql --verbose --master yarn --deploy-mode client --driver-memory 512M --executor-memory 1G --executor-cores 2 --conf spark.eventLog.dir=${spark_event_log_dir}/$USER --conf spark.yarn.dist.files=/etc/spark/hive-site.xml,$hive_jars --driver-java-options "-XX:MaxPermSize=1024M -Djava.library.path=/opt/hadoop/lib/native/" --driver-class-path hive-site.xml:$hive_jars_colon $queue_name -e "$create_database_sql; USE $db_name; $create_table_sql ; $load_data_sql ; $test_window_sql1 ; $test_window_sql2 ; $drop_table_sql ; $drop_database_sql ; "
  sql_ret_code=$?
elif [ "x${hadoop_ver}" = "x2.7.1" ] ; then
  ./bin/spark-sql --verbose --master yarn --deploy-mode client --driver-memory 512M --executor-memory 1G --executor-cores 2 --conf spark.eventLog.dir=${spark_event_log_dir}/$USER --conf spark.yarn.dist.files=/etc/spark/hive-site.xml,$hive_jars --conf spark.executor.extraClassPath=$(basename $sparksql_hivejars):$(basename $sparksql_hivethriftjars) --driver-java-options "-XX:MaxPermSize=1024M -Djava.library.path=/opt/hadoop/lib/native/" --driver-class-path hive-site.xml:$hive_jars_colon $queue_name -e "$create_database_sql; USE $db_name; $create_table_sql ; $load_data_sql ; $test_window_sql1 ; $test_window_sql2 ; $drop_table_sql ; $drop_database_sql ;"
  sql_ret_code=$?
else
  echo "fatal - hadoop version not supported, neither 2.7.1 nor 2.4.1"
  exit -5
fi

if [ "$sql_ret_code" -ne "0" ] ; then
  >&2 echo "fail - testing $0 SparkSQL Windowing Function on HiveQL/HiveContext failed!!"
  exit -4
fi

popd

exit 0


