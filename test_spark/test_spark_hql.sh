#!/bin/sh -x

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`

kerberos_enable=false
spark_home=$SPARK_HOME
spark_test_dir=$spark_home/test_spark/

hive_home=$HIVE_HOME
if [ "x${hive_home}" = "x" ] ; then
  hive_home=/opt/hive
fi

if [ -f "$curr_dir/pom.xml" ] ; then
  spark_test_dir=$curr_dir
fi

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
  if [ ! -f "$curr_dir/pom.xml" ] ; then
    spark_test_dir=$spark_home/test_spark/
  fi
  echo "ok - applying default location /opt/spark"
fi

if [ ! -d $spark_home ] ; then
  echo "fail - $spark_home doesn't exist, can't continue, is spark installed correctly?"
  exit -1
fi

source $spark_home/test_spark/init_spark.sh

pushd `pwd`
cd $spark_home
hdfs dfs -mkdir -p spark/test/resources
hdfs dfs -copyFromLocal /opt/spark/examples/src/main/resources/* spark/test/resources/

# Perform sanity check on required files in test case
if [ ! -f "$spark_home/examples/src/main/resources/kv1.txt" ] ; then
  echo "fail - missing test data $spark_home/examples/src/main/resources/kv1.txt to load, did the examples directory structure changed?"
  exit -3
fi

echo "ok - testing spark SQL shell with simple queries"

app_name=`head -n 9 $spark_test_dir/pom.xml | grep artifactId | cut -d">" -f2- | cut -d"<" -f1`
app_ver=`head -n 9 $spark_test_dir/pom.xml | grep version | cut -d">" -f2- | cut -d"<" -f1`

if [ ! -f "$spark_test_dir/${app_name}-${app_ver}.jar" ] ; then
  echo "fail - $spark_test_dir/${app_name}-${app_ver}.jar test jar does not exist, cannot continue testing, failing!"
  exit -3
fi

mysql_jars=$(find /opt/mysql-connector/ -type f -name "mysql-*.jar")
spark_opts_extra=
for i in `find $hive_home/lib/ -type f -name "datanucleus*.jar"`
do
  spark_opts_extra="$spark_opts_extra --jars $i"
done
spark_opts_extra="$spark_opts_extra --jars $mysql_jars"

spark_files=$(find $hive_home/lib/ -type f -name "datanucleus*.jar" | tr -s '\n' ',')
spark_files="$spark_files$mysql_jars,/etc/spark/hive-site.xml"

./bin/spark-submit --verbose --driver-java-options "-XX:MaxPermSize=8192M -Djava.library.path=/opt/hadoop/lib/native/" --driver-class-path hive-site.xml --master yarn --deploy-mode cluster --driver-memory 2048M --executor-memory 2048M --executor-cores 3 $spark_opts_extra --files $spark_files --class SparkSQLTestCase2HiveContextYarnClusterApp $spark_test_dir/${app_name}-${app_ver}.jar

if [ $? -ne "0" ] ; then
  echo "fail - testing shell for SparkSQL on HiveQL/HiveContext failed!!"
  exit -4
fi

popd

reset

exit 0


