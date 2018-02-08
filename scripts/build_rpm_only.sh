#!/bin/bash

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
WORKSPACE=${WORKSPACE:-"$curr_dir/../"}
spark_git_dir=$WORKSPACE/spark
spark_spec="$curr_dir/spark.spec"

mock_cfg="$curr_dir/altiscale-spark-centos-6-x86_64.cfg"
mock_cfg_name=$(basename "$mock_cfg")
mock_cfg_runtime=`echo $mock_cfg_name | sed "s/.cfg/.runtime.cfg/"`
build_timeout=28800

maven_settings="$HOME/.m2/settings.xml"
maven_settings_spec="$curr_dir/alti-maven-settings.spec"
INCLUDE_LEGACY_TEST=${INCLUDE_LEGACY_TEST:-"true"}

git_hash=""

if [ -f "$curr_dir/setup_env.sh" ]; then
  set -a
  source "$curr_dir/setup_env.sh"
  set +a
fi

if [ ! -f "$maven_settings" ]; then
  echo "fatal - $maven_settings DOES NOT EXIST!!!! YOU MAY PULLING IN UNTRUSTED artifact and BREACH SECURITY!!!!!!"
fi

if [ ! -e "$spark_spec" ] ; then
  echo "fail - missing $spark_spec file, can't continue, exiting"
  exit -9
fi

cleanup_secrets()
{
  # Erase our track for any sensitive credentials if necessary
  rm -f $WORKSPACE/rpmbuild/RPMS/noarch/alti-maven-settings*.rpm
  rm -f $WORKSPACE/rpmbuild/RPMS/noarch/alti-maven-settings*.src.rpm
  rm -f $WORKSPACE/rpmbuild/SRPMS/alti-maven-settings*.src.rpm
  rm -rf $WORKSPACE/rpmbuild/SOURCES/alti-maven-settings*
}

env | sort

# Manual fix Git URL issue in submodule, safety net, just in case the git scheme doesn't work
# sed -i 's/git\@github.com:Altiscale\/spark.git/https:\/\/github.com\/Altiscale\/spark.git/g' .gitmodules
# sed -i 's/git\@github.com:Altiscale\/spark.git/https:\/\/github.com\/Altiscale\/spark.git/g' .git/config
if [ "x${SPARK_BRANCH_NAME}" = "x" ] ; then
  echo "error - SPARK_BRANCH_NAME is not defined. Please specify the branch explicitly. Exiting!"
  exit -9
fi

echo "ok - extracting git commit label from user defined $SPARK_BRANCH_NAME"
pushd $spark_git_dir
git_hash=$(git rev-parse HEAD | tr -d '\n')
echo "ok - we are compiling spark branch $SPARK_BRANCH_NAME upto commit label $git_hash"
popd

echo "ok - tar zip source file, preparing for build/compile by rpmbuild"

mkdir -p $WORKSPACE/rpmbuild/{BUILD,BUILDROOT,RPMS,SPECS,SOURCES,SRPMS}/
cp "$spark_spec" $WORKSPACE/rpmbuild/SPECS/spark.spec

pushd $WORKSPACE/
if [ $INCLUDE_LEGACY_TEST = "true" ] ; then
  tar --exclude .git --exclude .gitignore -cf $WORKSPACE/rpmbuild/SOURCES/spark.tar spark test_spark
else
  tar --exclude .git --exclude .gitignore -cf $WORKSPACE/rpmbuild/SOURCES/spark.tar spark
fi
popd

pushd "$WORKSPACE/rpmbuild/SOURCES/"
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
if [ -f "$maven_settings" ] ; then
  mkdir -p  alti-maven-settings
  cp "$maven_settings" alti-maven-settings/
  tar -cvzf alti-maven-settings.tar.gz alti-maven-settings
  cp "$maven_settings_spec" $WORKSPACE/rpmbuild/SPECS/

  # Build alti-maven-settings RPM separately so it doesn't get exposed to spark's SRPM or any external trace
  rpmbuild -vv -ba $WORKSPACE/rpmbuild/SPECS/alti-maven-settings.spec \
		--define "_topdir $WORKSPACE/rpmbuild" \
		--buildroot $WORKSPACE/rpmbuild/BUILDROOT/
  if [ $? -ne "0" ] ; then
    echo "fail - alti-maven-settings SRPM build failed"
    cleanup_secrets
    exit -95
  fi
fi
popd

# The patches is no longer needed since we merge the results into a branch on github.
# cp $WORKSPACE/patches/* $WORKSPACE/rpmbuild/SOURCES/

echo "ok - applying version number $SPARK_VERSION and release number $BUILD_TIME, the pattern delimiter is / here"
rpmbuild -vv \
  -ba $WORKSPACE/rpmbuild/SPECS/spark.spec \
  --define "_topdir $WORKSPACE/rpmbuild" \
  --define "_current_workspace $WORKSPACE" \
  --define "_spark_version $SPARK_VERSION" \
  --define "_scala_build_version $SCALA_VERSION" \
  --define "_git_hash_release $git_hash" \
  --define "_hadoop_version $HADOOP_VERSION" \
  --define "_hive_version $HIVE_VERSION" \
  --define "_altiscale_release_ver $ALTISCALE_RELEASE" \
  --define "_apache_name $SPARK_PKG_NAME" \
  --define "_build_release $BUILD_TIME" \
  --define "_production_release $PRODUCTION_RELEASE" \
  --define "_mvn_debug $MAVEN_DEBUG" \
  --buildroot $WORKSPACE/rpmbuild/BUILDROOT/

if [ $? -ne "0" ] ; then
  echo "fail - spark SRPM build failed"
  cleanup_secrets
  exit -98
fi

stat "$WORKSPACE/rpmbuild/SRPMS/alti-spark-${SPARK_VERSION}-${SPARK_VERSION}-${ALTISCALE_RELEASE}.${BUILD_TIME}.el6.src.rpm"
rpm -ivvv "$WORKSPACE/rpmbuild/SRPMS/alti-spark-${SPARK_VERSION}-${SPARK_VERSION}-${ALTISCALE_RELEASE}.${BUILD_TIME}.el6.src.rpm"

echo "ok - applying $WORKSPACE for the new BASEDIR for mock, pattern delimiter here should be :"
# the path includeds /, so we need a diff pattern delimiter

rpmbuild -vv --bi $WORKSPACE/rpmbuild/SPECS/spark.spec --short-circuit --buildroot $WORKSPACE/rpmbuild/BUILDROOT/ \
  --define "_topdir $WORKSPACE/rpmbuild" \
  --define "_current_workspace $WORKSPACE" \
  --define "_spark_version $SPARK_VERSION" \
  --define "_scala_build_version $SCALA_VERSION" \
  --define "_git_hash_release $git_hash" \
  --define "_hadoop_version $HADOOP_VERSION" \
  --define "_hive_version $HIVE_VERSION" \
  --define "_altiscale_release_ver $ALTISCALE_RELEASE" \
  --define "_apache_name $SPARK_PKG_NAME" \
  --define "_build_release $BUILD_TIME" \
  --define "_production_release $PRODUCTION_RELEASE" \
  --define "_mvn_debug $MAVEN_DEBUG" \

if [ $? -ne "0" ] ; then
  echo "fail - mock RPM build failed"
  cleanup_secrets
  # mock --configdir=$curr_dir -r altiscale-spark-centos-6-x86_64.runtime --clean
  # mock --configdir=$curr_dir -r altiscale-spark-centos-6-x86_64.runtime --scrub=all
  exit -99
fi

# Delete all src.rpm in the RPMS folder since this is redundant and copied by the mock process
rm -f $WORKSPACE/rpmbuild/RPMS/*.src.rpm

cleanup_secrets

echo "ok - build Completed successfully!"

exit 0
