#!/bin/bash

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`

spark_spec="$curr_dir/spark.spec"

mock_cfg="$curr_dir/altiscale-spark-centos-6-x86_64.cfg"
mock_cfg_name=$(basename "$mock_cfg")
mock_cfg_runtime=`echo $mock_cfg_name | sed "s/.cfg/.runtime.cfg/"`
build_timeout=28800

maven_settings="$HOME/.m2/settings.xml"
maven_settings_spec="$curr_dir/alti-maven-settings.spec"

git_hash=""

if [ -f "$curr_dir/setup_env.sh" ]; then
  set -a
  source "$curr_dir/setup_env.sh"
  set +a
fi

if [ "x${SPARK_VERSION}" = "x" ] ; then
  echo >&2 "fail - SPARK_VERSION can't be empty"
  exit -8
else
  echo "ok - SPARK_VERSION=$SPARK_VERSION"
fi

if [ "x${SPARK_PLAIN_VERSION}" = "x" ] ; then
  echo >&2 "fail - SPARK_PLAIN_VERSION can't be empty"
  exit -8
else
  echo "ok - SPARK_PLAIN_VERSION=$SPARK_PLAIN_VERSION"
fi

if [ "x${BUILD_TIMEOUT}" = "x" ] ; then
  build_timeout=28800
else
  build_timeout=$BUILD_TIMEOUT
fi

if [ "x${WORKSPACE}" = "x" ] ; then
  WORKSPACE="$curr_dir/../"
fi

if [ ! -f "$maven_settings" ]; then
  echo "fatal - $maven_settings DOES NOT EXIST!!!! YOU MAY PULLING IN UNTRUSTED artifact and BREACH SECURITY!!!!!!"
  exit -9
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

echo "checking if scala is installed on the system"
# this chk can be smarter, however, the build script will re-download the scala libs again during build process
# we can save some build time if we can just re-use the pre-installed scala
chk_scala_rpm=$(rpm -qa *scala*)
if [ "x${chk_scala_rpm}" = "x" -o ! -d "${SCALA_HOME}" ] ; then
  echo "warn - SCALA_HOME may or may not be defined, however, $SCALA_HOME folder doesn't exist."
  if [ ! -d "/opt/scala/" ] ; then
    echo "warn - scala isn't installed on the system?"
  else
    export SCALA_HOME=/opt/scala
  fi
else
  echo "ok - detected installed scala, SCALA_HOME=$SCALA_HOME"
fi

#if [ ! -f "/usr/bin/rpmdev-setuptree" -o ! -f "/usr/bin/rpmbuild" ] ; then
#  echo "fail - rpmdev-setuptree and rpmbuild in /usr/bin/ are both required to build RPMs"
#  exit -8
#fi

# should switch to WORKSPACE, current folder will be in WORKSPACE/spark due to 
# hadoop_ecosystem_component_build.rb => this script will change directory into your submodule dir
# WORKSPACE is the default path when jenkin launches e.g. /mnt/ebs1/jenkins/workspace/spark_build_test-alee
# If not, you will be in the $WORKSPACE/spark folder already, just go ahead and work on the submodule
# The path in the following is all relative, if the parent jenkin config is changed, things may break here.
pushd `pwd`
cd $WORKSPACE/spark

# Manual fix Git URL issue in submodule, safety net, just in case the git scheme doesn't work
# sed -i 's/git\@github.com:Altiscale\/spark.git/https:\/\/github.com\/Altiscale\/spark.git/g' .gitmodules
# sed -i 's/git\@github.com:Altiscale\/spark.git/https:\/\/github.com\/Altiscale\/spark.git/g' .git/config
if [ "x${SPARK_BRANCH_NAME}" = "x" ] ; then
  echo "error - SPARK_BRANCH_NAME is not defined, even though, you may checkout the code from hadoop_ecosystem_component_build, this does not gurantee you have the right branch. Please specify the BRANCH_NAME explicitly. Exiting!"
  exit -9
fi
echo "ok - switching to spark branch $SPARK_BRANCH_NAME and refetch the files"
git checkout $SPARK_BRANCH_NAME
git fetch --all
git_hash=$(git rev-parse HEAD | tr -d '\n')
cat pom.xml
popd

echo "ok - tar zip source file, preparing for build/compile by rpmbuild"
# spark is located at $WORKSPACE/spark
# tar cvzf $WORKSPACE/spark.tar.gz spark

# Looks like this is not installed on all machines
# rpmdev-setuptree
mkdir -p $WORKSPACE/rpmbuild/{BUILD,BUILDROOT,RPMS,SPECS,SOURCES,SRPMS}/
cp "$spark_spec" $WORKSPACE/rpmbuild/SPECS/spark.spec
pushd $WORKSPACE/
tar --exclude .git --exclude .gitignore -cf $WORKSPACE/rpmbuild/SOURCES/spark.tar spark test_spark
popd
pushd "$WORKSPACE/rpmbuild/SOURCES/"
tar -xf spark.tar
if [ -d alti-spark ] ; then
  rm -rf alti-spark
fi
mv spark alti-spark
cp -rp test_spark alti-spark/
tar --exclude .git --exclude .gitignore -czf alti-spark.tar.gz alti-spark
if [ -f "$maven_settings" ] ; then
  mkdir -p  alti-maven-settings
  cp "$maven_settings" alti-maven-settings/
  tar -cvzf alti-maven-settings.tar.gz alti-maven-settings
  cp "$maven_settings_spec" $WORKSPACE/rpmbuild/SPECS/
fi
popd

# Build alti-maven-settings RPM separately so it doesn't get exposed to spark's SRPM or any external trace
rpmbuild -vv -ba $WORKSPACE/rpmbuild/SPECS/alti-maven-settings.spec --define "_topdir $WORKSPACE/rpmbuild" --buildroot $WORKSPACE/rpmbuild/BUILDROOT/
if [ $? -ne "0" ] ; then
  echo "fail - alti-maven-settings SRPM build failed"
  cleanup_secrets
  exit -95
fi

# The patches is no longer needed since we merge the results into a branch on github.
# cp $WORKSPACE/patches/* $WORKSPACE/rpmbuild/SOURCES/

echo "ok - applying version number $SPARK_VERSION and release number $BUILD_TIME, the pattern delimiter is / here"
sed -i "s/SPARK_VERSION_REPLACE/$SPARK_VERSION/g" "$WORKSPACE/rpmbuild/SPECS/spark.spec"
sed -i "s/SPARK_PLAINVERSION_REPLACE/$SPARK_PLAIN_VERSION/g" "$WORKSPACE/rpmbuild/SPECS/spark.spec"
sed -i "s:CURRENT_WORKSPACE_REPLACE:$WORKSPACE:g" "$WORKSPACE/rpmbuild/SPECS/spark.spec"
sed -i "s/HADOOP_VERSION_REPLACE/$HADOOP_VERSION/g" "$WORKSPACE/rpmbuild/SPECS/spark.spec"
sed -i "s/HADOOP_BUILD_VERSION_REPLACE/$HADOOP_BUILD_VERSION/g" "$WORKSPACE/rpmbuild/SPECS/spark.spec"
sed -i "s/HIVE_VERSION_REPLACE/$HIVE_VERSION/g" "$WORKSPACE/rpmbuild/SPECS/spark.spec"
sed -i "s/SPARK_USER/$SPARK_USER/g" "$WORKSPACE/rpmbuild/SPECS/spark.spec"
sed -i "s/SPARK_GID/$SPARK_GID/g" "$WORKSPACE/rpmbuild/SPECS/spark.spec"
sed -i "s/SPARK_UID/$SPARK_UID/g" "$WORKSPACE/rpmbuild/SPECS/spark.spec"
sed -i "s/BUILD_TIME/$BUILD_TIME/g" "$WORKSPACE/rpmbuild/SPECS/spark.spec"
sed -i "s/ALTISCALE_RELEASE/$ALTISCALE_RELEASE/g" "$WORKSPACE/rpmbuild/SPECS/spark.spec"
sed -i "s/GITHASH_REV_RELEASE/$git_hash/g" "$WORKSPACE/rpmbuild/SPECS/spark.spec"
SCALA_HOME=$SCALA_HOME rpmbuild -vv -bs $WORKSPACE/rpmbuild/SPECS/spark.spec --define "_topdir $WORKSPACE/rpmbuild" --buildroot $WORKSPACE/rpmbuild/BUILDROOT/

if [ $? -ne "0" ] ; then
  echo "fail - spark SRPM build failed"
  cleanup_secrets
  exit -98
fi

stat "$WORKSPACE/rpmbuild/SRPMS/alti-spark-${SPARK_VERSION}-${SPARK_VERSION}-${ALTISCALE_RELEASE}.${BUILD_TIME}.el6.src.rpm"
rpm -ivvv "$WORKSPACE/rpmbuild/SRPMS/alti-spark-${SPARK_VERSION}-${SPARK_VERSION}-${ALTISCALE_RELEASE}.${BUILD_TIME}.el6.src.rpm"

echo "ok - applying $WORKSPACE for the new BASEDIR for mock, pattern delimiter here should be :"
# the path includeds /, so we need a diff pattern delimiter

mkdir -p "$WORKSPACE/var/lib/mock"
chmod 2755 "$WORKSPACE/var/lib/mock"
mkdir -p "$WORKSPACE/var/cache/mock"
chmod 2755 "$WORKSPACE/var/cache/mock"
sed "s:BASEDIR:$WORKSPACE:g" "$mock_cfg" > "$curr_dir/$mock_cfg_runtime"
sed -i "s:SPARK_VERSION:$SPARK_VERSION:g" "$curr_dir/$mock_cfg_runtime"
echo "ok - applying mock config $curr_dir/$mock_cfg_runtime"
cat "$curr_dir/$mock_cfg_runtime"

# The following initialization is not cool, need a better way to manage this
# mock -vvv --configdir=$curr_dir -r altiscale-spark-centos-6-x86_64.runtime --scrub=all
mock -vvv --configdir=$curr_dir -r altiscale-spark-centos-6-x86_64.runtime --init

mock -vvv --configdir=$curr_dir -r altiscale-spark-centos-6-x86_64.runtime --no-clean --no-cleanup-after --install $WORKSPACE/rpmbuild/RPMS/noarch/alti-maven-settings-1.0-1.el6.noarch.rpm

mock -vvv --configdir=$curr_dir -r altiscale-spark-centos-6-x86_64.runtime --no-clean --rpmbuild_timeout=$build_timeout --resultdir=$WORKSPACE/rpmbuild/RPMS/ --rebuild $WORKSPACE/rpmbuild/SRPMS/alti-spark-${SPARK_VERSION}-${SPARK_VERSION}-${ALTISCALE_RELEASE}.${BUILD_TIME}.el6.src.rpm

if [ $? -ne "0" ] ; then
  echo "fail - mock RPM build failed"
  cleanup_secrets
  # mock --configdir=$curr_dir -r altiscale-spark-centos-6-x86_64.runtime --clean
  mock --configdir=$curr_dir -r altiscale-spark-centos-6-x86_64.runtime --scrub=all
  exit -99
fi

# mock --configdir=$curr_dir -r altiscale-spark-centos-6-x86_64.runtime --clean
mock --configdir=$curr_dir -r altiscale-spark-centos-6-x86_64.runtime --scrub=all

# Delete all src.rpm in the RPMS folder since this is redundant and copied by the mock process
rm -f $WORKSPACE/rpmbuild/RPMS/*.src.rpm

cleanup_secrets

echo "ok - build Completed successfully!"

exit 0












