#!/bin/sh -x

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`

kerberos_enable=false
spark_home=$SPARK_HOME

testcase_shell_file=$curr_dir/sparkshell_examples.txt

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

./bin/spark-shell --master yarn --deploy-mode client --queue research --driver-memory 512M --driver-class-path $(find /opt/hadoop/share/hadoop/mapreduce/lib/hadoop-lzo-* | head -n 1) << EOT
`cat $testcase_shell_file`
EOT

popd

reset

exit 0


