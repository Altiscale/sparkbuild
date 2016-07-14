#!/bin/bash

# Run the test case as spark
# We will use beeline to test it via the JDBC driver
# /bin/su - spark -c "./test_spark/test_spark_thriftserver2.sh"

# Load default values from Chef
[ -f /etc/sysconfig/sparktsd-1.6.2 ] && . /etc/sysconfig/sparktsd-1.6.2

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
spark_conf=${SPARK_CONF_DIR:-"$SPARKTS_DEFAULT_CONFIG"}

source $spark_conf/spark-env.sh

spark_version=${SPARK_VERSION:-"1.6.2"}
spark_home=${SPARK_HOME:="/opt/alti-spark-$spark_version"}
scala_version=${SPARK_SCALA_VERSION:-"2.10"}
spark_test_dir="$spark_home/test_spark"

spark_ts2_listen_port=${SPARKTS_DEFAULT_PORT:-48600}
running_user=`whoami`
test_user="sparkts"

source $spark_home/test_spark/init_spark.sh

sparkts_default_hostname=$(hostname)
sparkts_hostname=$sparkts_default_hostname

beeline -u "jdbc:hive2://${sparkts_hostname}:$spark_ts2_listen_port" -n $test_user -p "" -e "show tables;"
ret=$?
if [ $ret -ne "0" ] ; then
  >&2 echo "fail - interacting with Hive metadata failed to show tables, exiting!"
  exit -4
fi

beeline -u "jdbc:hive2://${sparkts_hostname}:$spark_ts2_listen_port" -n $test_user  -p "" -e "SELECT COUNT(*) FROM spark_hive_test_yarn_cluster_table;"
ret=$?
if [ $ret -ne "0" ] ; then
  >&2 echo "fail - querying Hive tables failed, exiting!"
  exit -5
fi

table_uuid=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
db_name="spark_test_db_${table_uuid}"
table_name="spark_hive_test_table_${table_uuid}"
new_table_name="new_spark_hive_test_table_${table_uuid}"
orc_table_name="orc_spark_hive_test_table_${table_uuid}"
parquet_table_name="parquet_spark_hive_test_table_${table_uuid}"

test_create_database_sql1="CREATE DATABASE IF NOT EXISTS ${db_name}"
test_create_table_sql1="CREATE TABLE $table_name (key INT, value STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE"
test_alter_table_sql1="ALTER TABLE $table_name RENAME TO $new_table_name"
test_describe_table_sql1="DESCRIBE FORMATTED $new_table_name"
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
test_drop_database_sql1="DROP DATABASE IF EXISTS ${db_name}"

beeline -u "jdbc:hive2://${sparkts_hostname}:$spark_ts2_listen_port" \
        -n $test_user \
        -p "" \
        -e "$test_create_database_sql1; USE $db_name; $test_create_table_sql1 ; $test_alter_table_sql1 ; $test_describe_table_sql1; $test_truncate_table_sql1 ; $test_load_data_sql1 ; $test_create_orc_sql1; $test_create_parquet_sql1; $test_select_sql1 ; $test_select_orc_sql1; $test_select_parquet_sql1; $test_drop_table_sql1 ; $test_drop_orc_table_sql1; $test_drop_parquet_table_sql1; $test_drop_database_sql1; "
ret=$?
if [ $ret -ne "0" ] ; then
  >&2 echo "fail - executing DDL statement with Hive failed, exiting!"
  exit -6
fi

exit 0
