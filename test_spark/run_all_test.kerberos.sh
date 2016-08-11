#!/bin/sh -x

iam=`whoami`
if [ "$iam" = "root" ] ; then
  >&2 echo "fail - you can't run test case as root!!! exiting!"
  exit -1
fi

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"
all_nonkerberos_testcase=(test_spark_submit.sh test_spark_shell_graphx.sh test_spark_shell_mllib_clustering.sh test_spark_shell_mllib_classification.sh test_spark_shell_mllib_regression.sh test_spark_shell_mllib_tree.sh test_spark_sql.sh test_pyspark_sparksql.sh test_pyspark_shell.sh test_spark_hql.sh test_spark_hql.kerberos.sh test_sparksql_function.sh test_sparksql_window_function.sh)
all_kerberos_testcase=(test_spark_submit.sh test_spark_shell_graphx.sh test_spark_shell_mllib_clustering.sh test_spark_shell_mllib_classification.sh test_spark_shell_mllib_regression.sh test_spark_shell_mllib_tree.sh test_spark_sql.sh test_pyspark_sparksql.sh test_pyspark_shell.sh test_spark_hql.kerberos.sh test_sparksql_function.sh test_sparksql_window_function.sh)

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`

export SPARK_VERSION="1.5.2"
# Change this to your own home directory if necessary
export SPARK_HOME="/opt/alti-spark-$SPARK_VERSION"
# You can specify different settings for the same test case via SPARK_CONF_DIR
export SPARK_CONF_DIR=${SPARK_CONF_DIR:-"/etc/alti-spark-$SPARK_VERSION"}
if [ ! -d "$SPARK_CONF_DIR" ] ; then
  >&2 echo "fail - Spark $SPARK_VERSION installation is broken, missing files or directory from $SPARK_CONF_DIR"
  exit -1
fi

if [[ ! -L "$SPARK_HOME" && ! -d "$SPARK_HOME" ]] ; then
  >&2 echo "fail - $SPARK_HOME does not exist, can't continue, exiting! check spark installation."
  exit -1
fi

if [ ! -d "$SPARK_HOME/test_spark" ] ; then
  >&2 echo "fail - missing $SPARK_HOME/test_spark, can't continue! Exiting!"
  >&2 echo "fail - this script is designed for Spark general testcase only and requires test_spark directory in $SPARK_HOME"
  >&2 echo "fail - you may create your own $SPARK_HOME/test_spark to reuse this script"
  exit -1
fi

source $SPARK_HOME/test_spark/init_spark.sh
source $SPARK_HOME/test_spark/deploy_hive_jar.sh

pushd `pwd`
  cd $SPARK_HOME
  pushd $SPARK_HOME/test_spark
  for testcase in ${all_kerberos_testcase[*]}
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
