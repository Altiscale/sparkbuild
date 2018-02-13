#!bin/bash

SPARK_VERSION=<%= version %>
SCALA_VERSION=<%= scala_version %>

echo "ok - post-install script for <%= pkgname %> triggered"

for f in `find /opt/alti-spark-${SPARK_VERSION}/assembly/target/scala-${SCALA_VERSION}/jars/ -name "*.jar"`
do
  ln -vsf $f /opt/alti-spark-${SPARK_VERSION}/lib/
done

ln -vsf /opt/alti-spark-${SPARK_VERSION}/examples/target/scala-${SCALA_VERSION}/jars/spark-examples_${SCALA_VERSION}-${SPARK_VERSION}.jar /opt/alti-spark-${SPARK_VERSION}/lib/
ln -vsf /opt/alti-spark-${SPARK_VERSION}/common/network-yarn/target/scala-${SCALA_VERSION}/spark-${SPARK_VERSION}-yarn-shuffle.jar /opt/alti-spark-${SPARK_VERSION}/lib/
ln -vsf /opt/alti-spark-${SPARK_VERSION}/sql/hive/target/spark-hive_${SCALA_VERSION}-${SPARK_VERSION}.jar /opt/alti-spark-${SPARK_VERSION}/lib/spark-hive_${SCALA_VERSION}.jar
ln -vsf /opt/alti-spark-${SPARK_VERSION}/sql/hive-thriftserver/target/spark-hive-thriftserver_${SCALA_VERSION}-${SPARK_VERSION}.jar /opt/alti-spark-${SPARK_VERSION}/lib/spark-hive-thriftserver_${SCALA_VERSION}.jar

# Do NOT put exit here, this will trigger an exit all the way to the parent script hadoop_ecosystem_component_build.rb and justinstall.sh
