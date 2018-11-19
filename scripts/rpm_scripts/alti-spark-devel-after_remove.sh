#!bin/bash

SPARK_VERSION=<%= version %>
SCALA_VERSION=<%= scala_version %>

echo "ok - post-uninstall script for <%= pkgname %> triggered"

rm -vrf /opt/alti-spark-${SPARK_VERSION}/core
rm -vrf /opt/alti-spark-${SPARK_VERSION}/sql/catalyst
rm -vrf /opt/alti-spark-${SPARK_VERSION}/sql/core
rm -vrf /opt/alti-spark-${SPARK_VERSION}/sql/hive
rm -vrf /opt/alti-spark-${SPARK_VERSION}/launcher
rm -vrf /opt/alti-spark-${SPARK_VERSION}/common/unsafe
rm -vrf /opt/alti-spark-${SPARK_VERSION}/common/tags
rm -vrf /opt/alti-spark-${SPARK_VERSION}/common/sketch
rm -vrf /opt/alti-spark-${SPARK_VERSION}/yarn
rm -vrf /opt/alti-spark-${SPARK_VERSION}/resource-managers/yarn


# Do NOT put exit here, this will trigger an exit all the way to the parent script hadoop_ecosystem_component_build.rb and justinstall.sh
