#!bin/bash

SPARK_VERSION=<%= version %>
SCALA_VERSION=<%= scala_version %>

echo "ok - post-uninstall script for <%= pkgname %> triggered"

if [ -d /opt/alti-spark-${SPARK_VERSION}/lib ] ; then
  rm -vrf /opt/alti-spark-${SPARK_VERSION}/lib/spark-${SPARK_VERSION}-yarn-shuffle.jar
fi
rm -vrf /opt/alti-spark-${SPARK_VERSION}/common/network-yarn

# Do NOT put exit here, this will trigger an exit all the way to the parent script hadoop_ecosystem_component_build.rb and justinstall.sh
