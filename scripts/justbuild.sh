#!/bin/bash -x

# This build script is only applicable to Spark without Hadoop and Hive

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
workspace_dir=$curr_dir
workspace_rpm_dir=$workspace_dir/workspace_rpm
WORKSPACE=${WORKSPACE:-$workspace_rpm_dir}
mkdir -p $workspace_rpm_dir
spark_git_dir=$workspace_dir/../spark
spark_spec="$curr_dir/spark.spec"
git_hash=""
mvn_settings="$HOME/.m2/settings.xml"
mvn_runtime_settings="$curr_dir/settings.xml"
mvn_macros_def_list=
additional_mvn_build_args=
builddir_mvn_settings="/tmp/settings.xml"
# We are migrating Altiscale spark example to its individual build process
# Set to false if that process is available and up and running
INCLUDE_LEGACY_TEST=${INCLUDE_LEGACY_TEST:-"true"}

if [ -f "$curr_dir/setup_env.sh" ]; then
  set -a
  source "$curr_dir/setup_env.sh"
  set +a
fi

if [ ! -e "$spark_spec" ] ; then
  echo "fail - missing $spark_spec file, can't continue, exiting"
  exit -9
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
echo "ok - tar zip spark-xxx source file, preparing for build/compile by rpmbuild"
pushd $workspace_rpm_dir
pushd $spark_git_dir/../
if [ $INCLUDE_LEGACY_TEST = "true" ] ; then
  tar --exclude .git --exclude .gitignore -cf $workspace_rpm_dir/spark.tar spark test_spark
else
  tar --exclude .git --exclude .gitignore -cf $workspace_rpm_dir/spark.tar spark
fi
popd

pushd $workspace_rpm_dir
tar -xf spark.tar
if [ -d alti-spark ] ; then
  rm -rf alti-spark
fi
mv spark alti-spark
# Copy Altiscale test case directory
if [ $INCLUDE_LEGACY_TEST = "true" ] ; then
  cp -rp test_spark alti-spark/
fi
tar --exclude .git --exclude .gitignore -czf alti-spark.tar.gz alti-spark
popd

# Launch mock to build Altiscale Spark
pushd $workspace_rpm_dir
rm -rf *.rpm
echo "ok - producing $SPARK_PKG_NAME spec file"
cp $spark_spec .
spec_name=$(basename $spark_spec)
echo "ok - applying version number $SPARK_VERSION and other env variables to $(pwd)/$spec_name via rpm macros"

if [ -f "$mvn_settings" ] ; then
  diff -q $mvn_settings $mvn_runtime_settings
  if [ $? -eq "0" ] ; then
    echo "ok - $mvn_settings content is the same as local copy, apply local copy due to permission tweak 644"
    mvn_macros_def_list="_mvn_settings $builddir_mvn_settings"
    additional_mvn_build_args="--copyin=$mvn_runtime_settings:$builddir_mvn_settings"
  else
    echo "ok - $mvn_settings content is different from the local copy, use $mvn_settings for safety"
    mvn_macros_def_list="_mvn_settings $builddir_mvn_settings"
    additional_mvn_build_args="--copyin=$mvn_settings:$builddir_mvn_settings"
  fi

  alti_mock build --root=$BUILD_ROOT \
    --spec=./$spec_name \
    -S ./alti-spark.tar.gz \
    -D "_current_workspace $WORKSPACE"\
    "_spark_version $SPARK_VERSION" "_scala_build_version $SCALA_VERSION" "_git_hash_release $git_hash"\
    "_hadoop_version $HADOOP_VERSION" "_hive_version $HIVE_VERSION" "_altiscale_release_ver $ALTISCALE_RELEASE"\
    "_apache_name $SPARK_PKG_NAME"\
    "_build_release $BUILD_TIME" "_production_release $PRODUCTION_RELEASE"\
    "$mvn_macros_def_list"\
    "$additional_mvn_build_args"
else
  2>&1 echo "warn - $mvn_settings not found, env is incorrect and may expose to public repo directly!!!!!"
  alti_mock build --root=$BUILD_ROOT \
    --spec=./$spec_name \
    -S ./alti-spark.tar.gz \
    -D "_current_workspace $WORKSPACE"\
    "_spark_version $SPARK_VERSION" "_scala_build_version $SCALA_VERSION" "_git_hash_release $git_hash"\
    "_hadoop_version $HADOOP_VERSION" "_hive_version $HIVE_VERSION" "_altiscale_release_ver $ALTISCALE_RELEASE"\
    "_apache_name $SPARK_PKG_NAME"\
    "_build_release $BUILD_TIME" "_production_release $PRODUCTION_RELEASE"
fi

if [ $? -ne "0" ] ; then
  echo "fail - $spec_name SRPM build failed"
  popd
  exit -99
fi
popd

echo "ok - build Completed successfully!"

exit 0
