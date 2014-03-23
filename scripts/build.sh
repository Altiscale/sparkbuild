#!/bin/bash

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`

setup_host="$curr_dir/setup_host.sh"
spark_spec="$curr_dir/spark.spec"

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

env | sort

echo "checking if scala is installed on the system"
# this chk can be smarter, however, the build script will re-download the scala libs again during build process
# we can save some build time if we can just re-use the pre-installed scala
chk_scala_rpm=$(rpm -qa *scala*)
if [ "x${chk_scala_rpm}" = "x" -o ! -d "${SCALA_HOME}" ] ; then
  echo "warn - SCALA_HOME may or may not be defined, however, $SCALA_HOME folder doesn't exist, re-downloading scala and install scala temporarily"
  wget --quiet --output-document=scala.tgz  "http://www.scala-lang.org/files/archive/scala-2.10.3.tgz"
  tar xvf scala.tgz
  if [ -d $WORKSPACE/scala ] ; then
    echo "deleting prev installed scala"
    rm -rf $WORKSPACE/scala
  fi
  mv scala-* $WORKSPACE/scala
  SCALA_HOME=$WORKSPACE/scala
  echo "scala downloaded completed, and put to $SCALA_HOME"
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
git checkout branch-0.9
git fetch --all
popd

pushd `pwd`
cd $WORKSPACE/
tar cvzf $WORKSPACE/spark.tar.gz spark
popd

# Looks like this is not installed on all machines
# rpmdev-setuptree
mkdir -p $WORKSPACE/rpmbuild/{BUILD,RPMS,SPECS,SOURCES,SRPMS}/
cp "$spark_spec" $WORKSPACE/rpmbuild/SPECS/spark.spec
cp -r $WORKSPACE/spark.tar.gz $WORKSPACE/rpmbuild/SOURCES/
SCALA_HOME=$SCALA_HOME rpmbuild -vv -ba $WORKSPACE/rpmbuild/SPECS/spark.spec

if [ $? -ne "0" ] ; then
  echo "fail - RPM build failed"
fi
  
echo "ok - build Completed successfully!"

exit 0












