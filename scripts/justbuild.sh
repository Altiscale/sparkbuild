#!/bin/bash -x

# This build script is only applicable to Spark without Hadoop and Hive

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`

WORKSPACE=${WORKSPACE:-"$curr_dir/workspace"}
mkdir -p $WORKSPACE
spark_git_dir=$WORKSPACE/spark
git_hash=""

if [ -f "$curr_dir/setup_env.sh" ]; then
  set -a
  source "$curr_dir/setup_env.sh"
  set +a
fi

env | sort

if [ "x${PACKAGE_BRANCH}" = "x" ] ; then
  echo "error - PACKAGE_BRANCH is not defined. Please specify the branch explicitly. Exiting!"
  exit -9
fi

echo "ok - extracting git commit label from user defined $PACKAGE_BRANCH"
pushd $spark_git_dir
git_hash=$(git rev-parse HEAD | tr -d '\n')
echo "ok - we are compiling spark branch $PACKAGE_BRANCH upto commit label $git_hash"
popd

# Get a copy of the source code, and tar ball it, remove .git related files
# Rename directory from spark to alti-spark to distinguish 'spark' just in case.
echo "ok - preparing to compile, build, and packaging spark"

if [ "x${HADOOP_VERSION}" = "x" ] ; then
  echo "fatal - HADOOP_VERSION needs to be set, can't build anything, exiting"
  exit -8
else
  export SPARK_HADOOP_VERSION=$HADOOP_VERSION
  echo "ok - applying customized hadoop version $SPARK_HADOOP_VERSION"
fi

if [ "x${HIVE_VERSION}" = "x" ] ; then
  echo "fatal - HIVE_VERSION needs to be set, can't build anything, exiting"
  exit -8
else
  export SPARK_HIVE_VERSION=$HIVE_VERSION
  echo "ok - applying customized hive version $SPARK_HIVE_VERSION"
fi

pushd $WORKSPACE
pushd $spark_git_dir/

echo "ok - building Spark in directory $(pwd)"
echo "ok - building assembly with HADOOP_VERSION=$SPARK_HADOOP_VERSION HIVE_VERSION=$SPARK_HIVE_VERSION scala=scala-${SCALA_VERSION}"

# clean up for *NIX environment only, deleting window's cmd
rm -f ./bin/*.cmd

# Remove launch script AE-579
# TODO: Review this for K8s and multi-cloud since we may need this for spark standalond cluster
# later on.
echo "warn - removing Spark standalone scripts that may be required for Kubernetes"
rm -f ./sbin/start-slave*
rm -f ./sbin/start-master.sh
rm -f ./sbin/start-all.sh
rm -f ./sbin/stop-slaves.sh
rm -f ./sbin/stop-master.sh
rm -f ./sbin/stop-all.sh
rm -f ./sbin/slaves.sh
rm -f ./sbin/spark-daemons.sh
rm -f ./sbin/spark-executor
rm -f ./sbin/*mesos*.sh
rm -f ./conf/slaves

env | sort


# PURGE LOCAL CACHE for clean build
# mvn dependency:purge-local-repository

########################
# BUILD ENTIRE PACKAGE #
########################
# This will build the overall JARs we need in each folder
# and install them locally for further reference. We assume the build
# environment is clean, so we don't need to delete ~/.ivy2 and ~/.m2
# Default JDK version applied is 1.7 here.

# hadoop.version, yarn.version, and hive.version are all defined in maven profile now
# they are tied to each profile.
# hadoop-2.2 No longer supported, removed.
# hadoop-2.4 hadoop.version=2.4.1 yarn.version=2.4.1 hive.version=0.13.1a hive.short.version=0.13.1
# hadoop-2.6 hadoop.version=2.6.0 yarn.version=2.6.0 hive.version=1.2.1.spark hive.short.version=1.2.1
# hadoop-2.7 hadoop.version=2.7.1 yarn.version=2.7.1 hive.version=1.2.1.spark hive.short.version=1.2.1

hadoop_profile_str=""
testcase_hadoop_profile_str=""
if [[ $SPARK_HADOOP_VERSION == 2.4.* ]] ; then
  hadoop_profile_str="-Phadoop-2.4"
  testcase_hadoop_profile_str="-Phadoop24-provided"
elif [[ $SPARK_HADOOP_VERSION == 2.6.* ]] ; then
  hadoop_profile_str="-Phadoop-2.6"
  testcase_hadoop_profile_str="-Phadoop26-provided"
elif [[ $SPARK_HADOOP_VERSION == 2.7.* ]] ; then
  hadoop_profile_str="-Phadoop-2.7"
  testcase_hadoop_profile_str="-Phadoop27-provided"
else
  echo "fatal - Unrecognize hadoop version $SPARK_HADOOP_VERSION, can't continue, exiting, no cleanup"
  exit -9
fi

# TODO: This needs to align with Maven settings.xml, however, Maven looks for
# -SNAPSHOT in pom.xml to determine which repo to use. This creates a chain reaction on 
# legacy pom.xml design on other application since they are not implemented in the Maven way.
# :-( 
# Will need to create a work around with different repo URL and use profile Id to activate them accordingly
# mvn_release_flag=""
# if [ "x%{_production_release}" == "xtrue" ] ; then
#   mvn_release_flag="-Preleases"
# else
#   mvn_release_flag="-Psnapshots"
# fi

DEBUG_MAVEN=${DEBUG_MAVEN:-"false"}
if [ "x${DEBUG_MAVEN}" = "xtrue" ] ; then
  mvn_cmd="mvn -U -X $hadoop_profile_str -Phive-thriftserver -Phadoop-provided -Phive-provided -Psparkr -Pyarn -Pkinesis-asl -DskipTests install"
else
  mvn_cmd="mvn -U $hadoop_profile_str -Phive-thriftserver -Phadoop-provided -Phive-provided -Psparkr -Pyarn -Pkinesis-asl -DskipTests install"
fi

echo "$mvn_cmd"
$mvn_cmd

if [ $? -ne "0" ] ; then
  echo "fail - spark build failed!"
  popd
  exit -99
fi

# AE-1369
echo "ok - start packging a sparkr.zip for YARN distributed cache, this assumes user isn't going to customize this file"
pushd R/lib/
/usr/lib/jvm/java-openjdk/bin/jar cvMf sparkr.zip SparkR
popd

popd

echo "ok - build completed successfully!"
popd

exit 0
