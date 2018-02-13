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

echo "ok - post-uninstall script for alti-spark-${SPARK_VERSION}-kinesis triggered"

rm -vrf /opt/alti-spark-${SPARK_VERSION}/external/kinesis-asl
rm -vrf /opt/alti-spark-${SPARK_VERSION}/external/kinesis-asl-assembly

# Do NOT put exit here, this will trigger an exit all the way to the parent script hadoop_ecosystem_component_build.rb and justinstall.sh
