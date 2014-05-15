#!/bin/bash

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`

setup_host="$curr_dir/setup_host.sh"
spark_spec="$curr_dir/spark.spec"
spark_rc_macros="$curr_dir/spark_rpm_macros"
mock_cfg="$curr_dir/altiscale-spark-centos-6-x86_64.cfg"
mock_cfg_name=$(basename "$mock_cfg")
mock_cfg_runtime=`echo $mock_cfg_name | sed "s/.cfg/.runtime.cfg/"`
scala_tgz="$curr_dir/scala.tgz"

if [ -f "$curr_dir/setup_env.sh" ]; then
  source "$curr_dir/setup_env.sh"
fi

if [ "x${WORKSPACE}" = "x" ] ; then
  WORKSPACE="$curr_dir/../"
fi

if [ ! -f "$curr_dir/setup_host.sh" ]; then
  echo "warn - $setup_host does not exist, we may not need this if all the libs and RPMs are pre-installed"
fi

if [ ! -e "$spark_spec" ] ; then
  echo "fail - missing $spark_spec file, can't continue, exiting"
  exit -9
fi

if [ ! -e "$spark_rc_macros" ] ; then
  echo "fail - missing $spark_rc_macros file to override rpmbuild folders, can't continue, exiting"
  exit -9
fi

env | sort

echo "checking if scala is installed on the system"
# this chk can be smarter, however, the build script will re-download the scala libs again during build process
# we can save some build time if we can just re-use the pre-installed scala
chk_scala_rpm=$(rpm -qa *scala*)
if [ "x${chk_scala_rpm}" = "x" -o ! -d "${SCALA_HOME}" ] ; then
  echo "warn - SCALA_HOME may or may not be defined, however, $SCALA_HOME folder doesn't exist, re-validating $scala_tgz file or re-downloading scala and install scala temporarily"
  if [ -f "$scala_tgz" ] ; then
    echo "ok - found existing $scala_tgz, verifying integrity."
    fhash=$(md5sum "$scala_tgz" | cut -d" " -f1)
    if [ "x${fhash}" = "x7665a125ceb38c1ba32cbb9acba9070f" ] ; then
      echo "ok - md5 hash  matched, file is the same, no need to re-download again, use current one on disk"
    else
      echo "warn - previous file hash $fhash <> 7665a125ceb38c1ba32cbb9acba9070f , does not match , deleting and re-download again"
      echo "ok - deleting previous stale/corrupted file $scala_tgz"
      stat "$scala_tgz"
      rm -f "$scala_tgz"
      wget --output-document=$scala_tgz "http://www.scala-lang.org/files/archive/scala-2.10.3.tgz"
    fi
  else
    echo "ok - download fresh scala binaries 2.10.3"
    wget --output-document=$scala_tgz "http://www.scala-lang.org/files/archive/scala-2.10.3.tgz"
  fi
  tar xvf $scala_tgz
  if [ -d $WORKSPACE/scala ] ; then
    echo "deleting prev installed scala localtion $WORKSPACE/scala"
    rm -rf $WORKSPACE/scala
  fi
  mv scala-* $WORKSPACE/scala
  export SCALA_HOME=$WORKSPACE/scala
  echo "ok - scala update or re-downloaded completed, and put to $SCALA_HOME"
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
echo "ok - switching to spark branch-0.9 and refetch the files"
git checkout altiscale-branch-1.0
git fetch --all
popd

echo "ok - tar zip source file, preparing for build/compile by rpmbuild"
pushd `pwd`
# spark is located at $WORKSPACE/spark
cd $WORKSPACE
# tar cvzf $WORKSPACE/spark.tar.gz spark
popd

# Looks like this is not installed on all machines
# rpmdev-setuptree
mkdir -p $WORKSPACE/rpmbuild/{BUILD,BUILDROOT,RPMS,SPECS,SOURCES,SRPMS}/
cp "$spark_spec" $WORKSPACE/rpmbuild/SPECS/spark.spec
cp -r $WORKSPACE/spark $WORKSPACE/rpmbuild/SOURCES/alti-spark
pushd "$WORKSPACE/rpmbuild/SOURCES/"
tar --exclude .git -czf alti-spark.tar.gz alti-spark
popd

# The patches is no longer needed since we merge the results into a branch on github.
# cp $WORKSPACE/patches/* $WORKSPACE/rpmbuild/SOURCES/

# SCALA_HOME=$SCALA_HOME rpmbuild -vv -ba $WORKSPACE/rpmbuild/SPECS/spark.spec --define "_topdir $WORKSPACE/rpmbuild" --rcfile=$spark_rc_macros --buildroot $WORKSPACE/rpmbuild/BUILDROOT/
echo "ok - applying version number $SPARK_VERSION and release number $BUILD_TIME, the pattern delimiter is / here"
sed -i "s/SPARK_VERSION/$SPARK_VERSION/g" "$WORKSPACE/rpmbuild/SPECS/spark.spec"
sed -i "s/BUILD_TIME/$BUILD_TIME/g" "$WORKSPACE/rpmbuild/SPECS/spark.spec"
sed -i "s/ALTISCALE_RELEASE/$ALTISCALE_RELEASE/g" "$WORKSPACE/rpmbuild/SPECS/spark.spec"
SCALA_HOME=$SCALA_HOME rpmbuild -vv -bs $WORKSPACE/rpmbuild/SPECS/spark.spec --define "_topdir $WORKSPACE/rpmbuild" --buildroot $WORKSPACE/rpmbuild/BUILDROOT/

if [ $? -ne "0" ] ; then
  echo "fail - RPM build failed"
  exit -98
fi

stat "$WORKSPACE/rpmbuild/SRPMS/alti-spark-${SPARK_VERSION}-${ALTISCALE_RELEASE}.${BUILD_TIME}.el6.src.rpm"
rpm -ivvv "$WORKSPACE/rpmbuild/SRPMS/alti-spark-${SPARK_VERSION}-${ALTISCALE_RELEASE}.${BUILD_TIME}.el6.src.rpm"

echo "ok - applying $WORKSPACE for the new BASEDIR for mock, pattern delimiter here should be :"
# the path includeds /, so we need a diff pattern delimiter

mkdir -p "$WORKSPACE/var/lib/mock"
chmod 2755 "$WORKSPACE/var/lib/mock"
mkdir -p "$WORKSPACE/var/cache/mock"
chmod 2755 "$WORKSPACE/var/cache/mock"
sed "s:BASEDIR:$WORKSPACE:g" "$mock_cfg" > "$mock_cfg_runtime"
echo "ok - applying mock config $mock_cfg_runtime"
cat "$mock_cfg_runtime"
mock -vvv --configdir=$curr_dir -r altiscale-spark-centos-6-x86_64.runtime --resultdir=$WORKSPACE/rpmbuild/RPMS/ --rebuild $WORKSPACE/rpmbuild/SRPMS/alti-spark-${SPARK_VERSION}-${ALTISCALE_RELEASE}.${BUILD_TIME}.el6.src.rpm

if [ $? -ne "0" ] ; then
  echo "fail - mock RPM build failed"
  exit -99
fi

echo "ok - build Completed successfully!"

exit 0












