#!/bin/sh -x

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`

kerberos_enable=false
spark_home=$SPARK_HOME

testcase_shell_file_01=$curr_dir/sparkshell_examples.txt

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

if [ ! -f "$testcase_shell_file_01"  ] ; then
  echo "fail - missing testcase for spark, can't continue, exiting"
  exit -2
fi

source $spark_home/test_spark/init_spark.sh

pushd `pwd`
cd "$spark_home"
hdfs dfs -mkdir -p spark/test/graphx/followers
hdfs dfs -put "$spark_home/graphx/data/followers.txt" spark/test/graphx/followers/
hdfs dfs -put "$spark_home/graphx/data/users.txt" spark/test/graphx/followers/
hdfs dfs -mkdir -p spark/test/decision_tree
hdfs dfs -put "$spark_home/mllib/data/sample_tree_data.csv" spark/test/decision_tree/
hdfs dfs -mkdir -p spark/test/logistic_regression
hdfs dfs -put "$spark_home/mllib/data/sample_libsvm_data.txt" spark/test/logistic_regression/
hdfs dfs -mkdir -p spark/test/kmean
hdfs dfs -put "$spark_home/mllib/data/kmeans/kmeans_data.txt" spark/test/kmean/
hdfs dfs -mkdir -p spark/test/linear_regression
hdfs dfs -put "$spark_home/mllib/data/ridge-data/lpsa.data" spark/test/linear_regression/
hdfs dfs -mkdir -p spark/test/svm
hdfs dfs -put "$spark_home/mllib/data/sample_svm_data.txt" spark/test/svm/
hdfs dfs -mkdir -p spark/test/naive_bayes
hdfs dfs -put "$spark_home/mllib/data/sample_naive_bayes_data.txt" spark/test/naive_bayes/
hdfs dfs -put "$spark_home/README.md" spark/test/

echo "ok - testing spark REPL shell with various algorithm"

./bin/spark-shell --master yarn --deploy-mode client --queue research --driver-memory 2048M << EOT
`cat $testcase_shell_file_01`
EOT

if [ $? -ne "0" ] ; then
  echo "fail - testing shell for various algorithm failed!"
  exit -3
fi

popd

reset

exit 0


