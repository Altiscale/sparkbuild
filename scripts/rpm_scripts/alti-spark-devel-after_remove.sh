#!bin/bash

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`

if [ -f "$curr_dir/../setup_env.sh" ]; then
  set -a
  source "$curr_dir/../setup_env.sh"
  set +a
else
  echo "FATAL: missing critical env script for post-uninstallation script"
  exit -1
fi

echo "ok - post-uninstall script for alti-spark-${SPARK_VERSION}-devel triggered"

rm -vrf /opt/alti-spark-${SPARK_VERSION}/core
rm -vrf /opt/alti-spark-${SPARK_VERSION}/sql/catalyst
rm -vrf /opt/alti-spark-${SPARK_VERSION}/sql/core
rm -vrf /opt/alti-spark-${SPARK_VERSION}/sql/hive
rm -vrf /opt/alti-spark-${SPARK_VERSION}/launcher
rm -vrf /opt/alti-spark-${SPARK_VERSION}/common/unsafe
rm -vrf /opt/alti-spark-${SPARK_VERSION}/common/tags
rm -vrf /opt/alti-spark-${SPARK_VERSION}/common/sketch
rm -vrf /opt/alti-spark-${SPARK_VERSION}/yarn


# Do NOT put exit here, this will trigger an exit all the way to the parent script hadoop_ecosystem_component_build.rb and justinstall.sh
