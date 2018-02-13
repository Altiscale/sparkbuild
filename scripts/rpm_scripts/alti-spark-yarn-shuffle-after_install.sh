#!bin/bash

SPARK_VERSION=<%= version %>
SCALA_VERSION=<%= scala_version %>

echo "ok - post-install script for <%= pkgname %> triggered"

ln -vsf /opt/alti-spark-${SPARK_VERSION}/common/network-yarn/target/scala-${SCALA_VERSION}/spark-${SPARK_VERSION}-yarn-shuffle.jar /opt/alti-spark-${SPARK_VERSION}/lib/

# Do NOT put exit here, this will trigger an exit all the way to the parent script hadoop_ecosystem_component_build.rb and justinstall.sh
