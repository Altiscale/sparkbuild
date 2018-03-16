#!bin/bash

SPARK_VERSION=<%= version %>
SCALA_VERSION=<%= scala_version %>

echo "ok - post-uninstall script for <%= pkgname %> triggered"

rm -vrf /opt/alti-spark-${SPARK_VERSION}/external/kinesis-asl
rm -vrf /opt/alti-spark-${SPARK_VERSION}/external/kinesis-asl-assembly

# Do NOT put exit here, this will trigger an exit all the way to the parent script hadoop_ecosystem_component_build.rb and justinstall.sh
