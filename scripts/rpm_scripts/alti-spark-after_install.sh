#!bin/bash

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`

if [ -f "$curr_dir/../setup_env.sh" ]; then
  set -a
  source "$curr_dir/../setup_env.sh"
  set +a
else
  echo "FATAL: missing critical env script for post-installation script"
  exit -1
fi

for f in `find /opt/alti-spark-${SPARK_VERSION}/assembly/target/scala-${SCALA_VERSION}/jars/ -name "*.jar"`
do
  ln -vsf $f /opt/alti-spark-${SPARK_VERSION}/lib/
done

ln -vsf /opt/alti-spark-${SPARK_VERSION}/examples/target/scala-${SCALA_VERSION}/jars/spark-examples_${SCALA_VERSION}-${SPARK_VERSION}.jar /opt/alti-spark-${SPARK_VERSION}/lib/
ln -vsf /opt/alti-spark-${SPARK_VERSION}/common/network-yarn/target/scala-${SCALA_VERSION}/spark-${SPARK_VERSION}-yarn-shuffle.jar /opt/alti-spark-${SPARK_VERSION}/lib/
ln -vsf /opt/alti-spark-${SPARK_VERSION}/sql/hive/target/spark-hive_${SCALA_VERSION}-${SPARK_VERSION}.jar /opt/alti-spark-${SPARK_VERSION}/lib/spark-hive_${SCALA_VERSION}.jar
ln -vsf /opt/alti-spark-${SPARK_VERSION}/sql/hive-thriftserver/target/spark-hive-thriftserver_${SCALA_VERSION}-${SPARK_VERSION}.jar /opt/alti-spark-${SPARK_VERSION}/lib/spark-hive-thriftserver_${SCALA_VERSION}.jar

# Do NOT put exit here, this will trigger an exit all the way to the parent script hadoop_ecosystem_component_build.rb and justinstall.sh
