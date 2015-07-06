#!/bin/sh -x

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
testcase_shell_file_01="$curr_dir/sparkshell_examples.mllib.classification.txt"
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
hdfs dfs -mkdir -p spark/test/svm
hdfs dfs -put /opt/spark/mllib/data/sample_svm_data.txt spark/test/svm/
hdfs dfs -mkdir -p spark/test/naive_bayes
hdfs dfs -put /opt/spark/mllib/data/sample_naive_bayes_data.txt spark/test/naive_bayes/
hdfs dfs -mkdir spark/test/logistic_regression/
hdfs dfs -put /opt/spark/mllib/data/sample_libsvm_data.txt spark/test/logistic_regression/

echo "ok - testing spark REPL shell with various algorithm"
hadoop_snappy_jar=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "snappy-java-*.jar")
hadoop_lzo_jar=$(find $HADOOP_HOME/share/hadoop/common/lib/ -type f -name "hadoop-lzo-*.jar")
# The guava JAR here does not match the Spark's pom.xml which is looking for version 14.0.1
# Hive comes with Guava 11.0.2
guava_jar=$(find $HIVE_HOME/lib/ -type f -name "guava-*.jar")
spark_opts_extra="$spark_opts_extra --jars $hadoop_lzo_jar,$hadoop_snappy_jar,$guava_jar"

spark_event_log_dir=$(grep 'spark.eventLog.dir' /etc/spark/spark-defaults.conf | tr -s ' ' '\t' | cut -f2)

./bin/spark-shell --verbose --master yarn --deploy-mode client --queue research --driver-memory 1024M --conf spark.eventLog.dir=${spark_event_log_dir}$USER/ $spark_opts_extra << EOT
`cat $testcase_shell_file_01`
EOT

if [ $? -ne "0" ] ; then
  echo "fail - testing shell for various algorithm failed!"
  exit -3
fi

popd

reset

exit 0


