#!/bin/bash

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`

setup_host="$curr_dir/setup_host.sh"
spark_spec="$curr_dir/spark.spec"

if [ -f "$curr_dir/setup_env.sh" ]; then
  source "$curr_dir/setup_env.sh"
fi

if [ ! -f "$curr_dir/setup_host.sh" ]; then
  echo "warn - $setup_host does not exist, we may not need this if all the libs and RPMs are pre-installed"
fi

if [ ! -e "$spark_spec" ] ; then
  echo "fail - missing $spark_spec file, can't continue, exiting"
  exit -9
fi

if [ ! -x "/usr/bin/rpmdev-setuptree" -o ! -x "/usr/bin/rpmbuild" ] ; then
  echo "fail - rpmdev-setuptree and rpmbuild in /usr/bin/ are both required to build RPMs"
  exit -8
fi

# should switch to WORKSPACE
# e.g. /mnt/ebs1/jenkins/workspace/spark_build_test-alee
# If not, you will be in the $WORKSPACE/spark folder already, just go ahead and work on the submodule

# Manual fix Git URL issue in submodule, safety net, just in case the git scheme doesn't work
# sed -i 's/git\@github.com:Altiscale\/spark.git/https:\/\/github.com\/Altiscale\/spark.git/g' .gitmodules
# sed -i 's/git\@github.com:Altiscale\/spark.git/https:\/\/github.com\/Altiscale\/spark.git/g' .git/config
echo "ok - switching to spark branch-0.9 and refetch the files"
git checkout branch-0.9
git fetch --all
tar cvzf spark.tar.gz spark

/usr/bin/rpmdev-setuptree

cp "$spark_spec" ~/rpmbuild/SPECS/
cp -r ~/sparkbuild/spark.tar.gz ~/rpmbuild/SOURCES/
rpmbuild -vv -ba --clean ~/rpmbuild/SPECS/spark.spec

echo "ok - build Completed successfully!"

exit 0

