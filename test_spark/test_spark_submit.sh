#!/bin/sh -x

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`

kerberos_enable=false
spark_home=$SPARK_HOME
spark_version=1.2.0

# Check RPM installation.

spark_installed=$(rpm -qa | grep alti-spark | grep -v test | wc -l)
if [ "x${spark_installed}" = "x0" ] ; then
  echo "fail - spark not installed, can't continue, exiting"
  exit -1
elif [ "x${spark_installed}" = "x1" ] ; then
  echo "ok - detect one version of spark installed"
  echo "ok - $(rpm -q $(rpm -qa | grep alti-spark)) installed"
else
  echo "error - detected more than 1 spark installed, please remove one version, currently, testcase doesn't support mutiple version"
  exit -1
fi

if [ "x${spark_home}" = "x" ] ; then
  # rpm -ql $(rpm -qa --last | grep alti-spark | sort | head -n 1 | cut -d" " -f1) | grep -e '^/opt/alti-spark' | cut -d"/" -f1-3
  spark_home=/opt/spark
  echo "ok - applying default location /opt/spark"
fi

if [ ! -d $spark_home ] ; then
  echo "fail - SPARK_HOME doesn't exist, can't continue, is spark installed?"
  exit -1
fi

source $spark_home/test_spark/init_spark.sh

pushd `pwd`
cd $spark_home

echo "ok - testing spark REPL shell with various algorithm"

SPARK_EXAMPLE_JAR=$(find ${spark_home}/examples/target/spark-examples_*-${spark_version}.jar)

if [ ! -f "${SPARK_EXAMPLE_JAR}" ] ; then
  echo "fail - cannot detect example jar for this $spark_version $spark_installed build!"
  exit -2
fi

./bin/spark-submit --verbose --master yarn --deploy-mode cluster --class org.apache.spark.examples.SparkPi "${SPARK_EXAMPLE_JAR}"

if [ $? -ne "0" ] ; then
  echo "fail - testing shell for various algorithm failed!"
  exit -3
fi

popd

reset

exit 0


