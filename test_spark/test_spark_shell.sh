#!/bin/sh -x

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`

kerberos_enable=false
spark_home=$SPARK_HOME

testcase_shell_file_01=$curr_dir/sparkshell_examples.txt
testcase_shell_file_02=$curr_dir/sparksql_examples.txt

# Check RPM installation.

spark_installed=$(rpm -qa | grep alti-spark | wc -l)
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

# Create HDFS folders for Spark Event logs
# Doesn't matter who runs it.
# TBD: Move to Chef, and support Kerberos since HADOOP_USER_NAME will
# be invalid after enabling Kerberos.

if [ "x${kerberos_enable}" = "xfalse" ] ; then
  HADOOP_USER_NAME=hdfs hdfs dfs -mkdir /user/spark/
  HADOOP_USER_NAME=hdfs hdfs dfs -mkdir /user/spark/logs
  HADOOP_USER_NAME=hdfs hdfs dfs -chmod 1777 /user/spark/
  HADOOP_USER_NAME=hdfs hdfs dfs -chmod 1777 /user/spark/logs
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

if [ ! -f "$testcase_shell_file_01"  ] ; then
  echo "fail - missing testcase for spark, can't continue, exiting"
  exit -2
fi

pushd `pwd`
cd $spark_home
hdfs dfs -mkdir -p spark/test/graphx/followers
hdfs dfs -put /opt/spark/graphx/data/followers.txt spark/test/graphx/followers/
hdfs dfs -put /opt/spark/graphx/data/users.txt spark/test/graphx/followers/
hdfs dfs -mkdir -p spark/test/decision_tree
hdfs dfs -put /opt/spark/mllib/data/sample_tree_data.csv spark/test/decision_tree/
hdfs dfs -mkdir -p spark/test/logistic_regression
hdfs dfs -put /opt/spark/mllib/data/sample_libsvm_data.txt spark/test/logistic_regression/
hdfs dfs -mkdir -p spark/test/kmean
hdfs dfs -put /opt/spark/mllib/data/kmeans/kmeans_data.txt spark/test/kmean/
hdfs dfs -mkdir -p spark/test/linear_regression
hdfs dfs -put /opt/spark/mllib/data/ridge-data/lpsa.data spark/test/linear_regression/
hdfs dfs -mkdir -p spark/test/svm
hdfs dfs -put /opt/spark/mllib/data/sample_svm_data.txt spark/test/svm/
hdfs dfs -mkdir -p spark/test/naive_bayes
hdfs dfs -put /opt/spark/mllib/data/sample_naive_bayes_data.txt spark/test/naive_bayes/

echo "ok - testing spark REPL shell with various algorithm"

LD_LIBRARY_PATH=/opt/hadoop/lib/native/ ./bin/spark-shell --master yarn --deploy-mode client --queue research --driver-memory 512M << EOT
`cat $testcase_shell_file_01`
EOT

if [ $? -ne "0" ] ; then
  echo "fail - testing shell for various algorithm failed!"
  exit -3
fi

reset

LD_LIBRARY_PATH=/opt/hadoop/lib/native/ ./bin/spark-shell --master yarn --deploy-mode client --queue research --driver-memory 512M << EOT
`cat $testcase_shell_file_02`
EOT

if [ $? -ne "0" ] ; then
  echo "fail - testing shell for SparkSQL on HiveQL failed!!"
  exit -4
fi

popd

reset

exit 0


