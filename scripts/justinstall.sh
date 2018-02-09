#!/bin/bash

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
rpm_file=""

if [ -f "$curr_dir/setup_env.sh" ]; then
  set -a
	source "$curr_dir/setup_env.sh"
  set +a
fi

WORKSPACE=${WORKSPACE:-"$curr_dir/workspace"}
spark_git_dir=$WORKSPACE/spark

env | sort

ALTISCALE_RELEASE=${ALTISCALE_RELEASE:-"4.3.0"}
export RPM_NAME=`echo alti-spark-${SPARK_VERSION}`
export RPM_DESCRIPTION="Apache Spark ${SPARK_VERSION}\n\n${DESCRIPTION}"
echo "Packaging spark rpm with name ${RPM_NAME} with version ${ALTISCALE_VERSION}-${DATE_STRING}"

export RPM_BUILD_DIR=${INSTALL_DIR}/opt/alti-spark-${SPARK_VERSION}
mkdir --mode=0755 -p ${RPM_BUILD_DIR}
mkdir --mode=0755 -p ${INSTALL_DIR}/etc/alti-spark-${SPARK_VERSION}
mkdir --mode=0755 -p ${INSTALL_DIR}/service/log/alti-spark-${SPARK_VERSION}

# Init local directories within spark pkg
pushd ${RPM_BUILD_DIR}
mkdir --mode=0755 -p assembly/target/scala-${SCALA_VERSION}/jars
mkdir --mode=0755 -p data/
mkdir --mode=0755 -p examples/target/scala-${SCALA_VERSION}/jars/
mkdir --mode=0755 -p external/kafka-0-8/target/
mkdir --mode=0755 -p external/kafka-0-8-assembly/target/
mkdir --mode=0755 -p external/flume/target/
mkdir --mode=0755 -p external/flume-sink/target/
mkdir --mode=0755 -p external/flume-assembly/target/
mkdir --mode=0755 -p external/kinesis-asl/target/
mkdir --mode=0755 -p external/kinesis-asl-assembly/target/
mkdir --mode=0755 -p graphx/target/
mkdir --mode=0755 -p licenses/
mkdir --mode=0755 -p mllib/target/
mkdir --mode=0755 -p common/network-common/target/
mkdir --mode=0755 -p common/network-shuffle/target/
mkdir --mode=0755 -p common/network-yarn/target/scala-${SCALA_VERSION}/
mkdir --mode=0755 -p repl/target/
mkdir --mode=0755 -p streaming/target/
mkdir --mode=0755 -p sql/hive/target/
mkdir --mode=0755 -p sql/hive-thriftserver/target/
mkdir --mode=0755 -p tools/target/
mkdir --mode=0755 -p R/lib/
# Added due to AE-1219 to support Hive 1.2.0+ with Hive on Spark
mkdir --mode=0755 -p lib/
cp -rp $spark_git_dir/assembly/target/scala-${SCALA_VERSION}/jars/*.jar ./assembly/target/scala-${SCALA_VERSION}/jars/
cp -rp $spark_git_dir/examples/target/*.jar ./examples/target/
cp -rp $spark_git_dir/examples/target/scala-${SCALA_VERSION}/jars/*.jar ./examples/target/scala-${SCALA_VERSION}/jars/
# required for python and SQL
cp -rp $spark_git_dir/examples/src ./examples/
cp -rp $spark_git_dir/external/kinesis-asl/target/*.jar ./external/kinesis-asl/target/
cp -rp $spark_git_dir/external/kinesis-asl-assembly/target/*.jar ./external/kinesis-asl-assembly/target/
cp -rp $spark_git_dir/tools/target/*.jar ./tools/target/
cp -rp $spark_git_dir/mllib/data ./mllib/
cp -rp $spark_git_dir/mllib/target/*.jar ./mllib/target/
cp -rp $spark_git_dir/graphx/target/*.jar ./graphx/target/
cp -rp $spark_git_dir/streaming/target/*.jar ./streaming/target/
cp -rp $spark_git_dir/repl/target/*.jar ./repl/target/
cp -rp $spark_git_dir/bin ./
cp -rp $spark_git_dir/sbin ./
cp -rp $spark_git_dir/python ./
cp -rp $spark_git_dir/project ./
cp -rp $spark_git_dir/docs ./
cp -rp $spark_git_dir/dev ./
cp -rp $spark_git_dir/external/kafka-0-8/target/*.jar ./external/kafka-0-8/target/
cp -rp $spark_git_dir/external/kafka-0-8-assembly/target/*.jar ./external/kafka-0-8-assembly/target/
cp -rp $spark_git_dir/external/flume/target/*.jar ./external/flume/target/
cp -rp $spark_git_dir/external/flume-sink/target/*.jar ./external/flume-sink/target/
cp -rp $spark_git_dir/external/flume-assembly/target/*.jar ./external/flume-assembly/target/
cp -rp $spark_git_dir/common/network-common/target/*.jar ./common/network-common/target/
cp -rp $spark_git_dir/common/network-shuffle/target/*.jar ./common/network-shuffle/target/
cp -rp $spark_git_dir/common/network-yarn/target/*.jar ./common/network-yarn/target/
cp -rp $spark_git_dir/common/network-yarn/target/scala-${SCALA_VERSION}/*.jar ./common/network-yarn/target/scala-${SCALA_VERSION}/
cp -rp $spark_git_dir/sql/hive/target/*.jar ./sql/hive/target/
cp -rp $spark_git_dir/sql/hive-thriftserver/target/*.jar ./sql/hive-thriftserver/target/
cp -rp $spark_git_dir/data/* ./data/
cp -rp $spark_git_dir/R/lib/* ./R/lib/
popd

# Generate RPM based on where spark artifacts are placed from previous steps
rm -rf ${INSTALL_DIR}/opt/alti-spark-${SPARK_VERSION}

source /root/.bash_profile

cd ${RPM_DIR}
fpm --verbose \
--maintainer support@altiscale.com \
--vendor Altiscale \
--provides ${RPM_NAME} \
--description "$(printf "${RPM_DESCRIPTION}")" \
--replaces alti-spark-${ARTIFACT_VERSION} \
--url "${GITREPO}" \
--license "Apache License v2" \
--epoch 1 \
-s dir \
-t rpm \
-n ${RPM_NAME} \
-v ${ALTISCALE_RELEASE} \
--iteration ${DATE_STRING} \
--rpm-user root \
--rpm-group root \
-C ${INSTALL_DIR} \
opt etc

exit 0












