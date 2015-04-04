#!/bin/sh -x

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
testcase_shell_file_01=$curr_dir/sparkshell_examples.txt
spark_home=$SPARK_HOME

if [ "x${spark_home}" = "x" ] ; then
  spark_home=/opt/spark
  echo "ok - applying default location /opt/spark"
fi

source $spark_home/test_spark/init_spark.sh

spark_version=$SPARK_VERSION

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
hadoop_snappy_jar=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "snappy-java-*.jar")
hadoop_lzo_jar=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "hadoop-lzo-*.jar")
spark_opts_extra="$spark_opts_extra --jars $hadoop_lzo_jar,$hadoop_snappy_jar"

spark_event_log_dir=$(grep 'spark.eventLog.dir' /etc/spark/spark-defaults.conf | tr -s ' ' '\t' | cut -f2)

./bin/spark-shell --master yarn --deploy-mode client --queue research --driver-memory 2048M --conf spark.eventLog.dir=${spark_event_log_dir}$USER/ $spark_opts_extra << EOT
`cat $testcase_shell_file_01`
EOT

if [ $? -ne "0" ] ; then
  echo "fail - testing shell for various algorithm failed!"
  exit -3
fi

popd

reset

exit 0


