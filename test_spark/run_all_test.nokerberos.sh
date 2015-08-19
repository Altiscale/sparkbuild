#!/bin/sh -x

iam=`whoami`
if [ "$iam" = "root" ] ; then
  >&2 echo "fail - you can't run test case as root!!! exiting!"
  exit -1
fi

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"
all_nonkerberos_testcase=(test_spark_submit.sh test_spark_shell_graphx.sh test_spark_shell_mllib_clustering.sh test_spark_shell_mllib_classification.sh test_spark_shell_mllib_regression.sh test_spark_shell_mllib_tree.sh test_spark_sql.sh test_pyspark_sparksql.sh test_pyspark_shell.sh test_spark_hql.sh test_spark_hql.kerberos.sh test_sparksql_shell.sh)
all_kerberos_testcase=(test_spark_submit.sh test_spark_shell_graphx.sh test_spark_shell_mllib_clustering.sh test_spark_shell_mllib_classification.sh test_spark_shell_mllib_regression.sh test_spark_shell_mllib_tree.sh test_spark_sql.sh test_pyspark_sparksql.sh test_pyspark_shell.sh test_spark_hql.kerberos.sh test_sparksql_shell.sh)

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`

spark_home=$SPARK_HOME
spark_version=$SPARK_VERSION

if [ "x${spark_home}" = "x" ] ; then
  spark_home=/opt/spark
  echo "ok - applying default location /opt/spark"
  if [[ ! -L "$spark_home" && ! -d "$spark_home" ]] ; then
    >&2 echo "fail - $spark_home does not exist, can't continue, exiting! check spark installation."
    exit -1
  fi
fi

if [ ! -d "$spark_home/test_spark/" ] ; then
  >&2 echo "fail - missing $spark_home/test_spark/, can't continue! Exiting!"
  >&2 echo "fail - this script is designed for Spark general testcase only and requires test_spark directory in $spark_home"
  >&2 echo "fail - you may create your own $spark_home/test_spark/ to reuse this script"
  exit -1
fi

source $spark_home/test_spark/init_spark.sh

if [ "x${spark_version}" = "x" ] ; then
  if [ "x${SPARK_VERSION}" = "x" ] ; then
    >&2 echo "fail - SPARK_VERSION not set, can't continue, exiting!!!"
    exit -1
  else
    spark_version=$SPARK_VERSION
  fi
fi


pushd `pwd`
  cd $spark_home
  pushd $spark_home/test_spark/
  for testcase in ${all_nonkerberos_testcase[*]}
  do
    echo "ok - ############################################"
    echo "ok - executing testcase $testcase"
    echo "ok - ############################################"
    ./$testcase
    if [ $? -ne "0" ] ; then
      >&2 echo "fail - testcase $testcase failed!!!"
      exit -3
    else
      echo "ok - $testcase successsfully completed"
    fi
  done
  popd
popd

exit 0


