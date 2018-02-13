#!bin/bash

SPARK_VERSION=<%= version %>
SCALA_VERSION=<%= scala_version %>

echo "ok - post-uninstall script for <%= pkgname %> triggered"

if [ -f /opt/alti-spark-${SPARK_VERSION}/postinstall.do_NOT_modify.${SPARK_VERSION}.txt ] ; then
for f in `cat /opt/alti-spark-${SPARK_VERSION}/postinstall.do_NOT_modify.${SPARK_VERSION}.txt`
  do
    echo "ok - uninstalling symlink $f"
    rm -vf $f
  done
else
  echo "FATAL: Previous installation has changed or no longer compatible with post-uninstallation script!"
  echo "FATAL: Please review pre-install and post-uninstall script and synchronize them! and revert any manual changes!"
fi

rm -vrf /opt/alti-spark-${SPARK_VERSION}/lib/spark-examples_${SCALA_VERSION}-${SPARK_VERSION}.jar
rm -vrf /opt/alti-spark-${SPARK_VERSION}/lib/spark-hive_${SCALA_VERSION}.jar
rm -vrf /opt/alti-spark-${SPARK_VERSION}/lib/spark-hive-thriftserver_${SCALA_VERSION}.jar

# Do NOT put exit here, this will trigger an exit all the way to the parent script hadoop_ecosystem_component_build.rb and justinstall.sh
