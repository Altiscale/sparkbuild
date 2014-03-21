#!/bin/bash

curr_dir=`dirname $0`
local_dir=`cd $curr_dir; pwd`

spark_spec="$local_dir/spark.spec"

if [ -f "$local_dir/setup_env.sh" ]; then
  source "$local_dir/setup_env.sh"
fi

if [ ! -e "$spark_spec" ] ; then
  echo "fail - missing $spark_spec file, can't continue, exiting"
  exit -9
fi

pushd `pwd`
cd sparkbuild
# Manual fix Git URL issue in submodule, safety net, just in case the git scheme doesn't work
# sed -i 's/git\@github.com:Altiscale\/spark.git/https:\/\/github.com\/Altiscale\/spark.git/g' .gitmodules
# sed -i 's/git\@github.com:Altiscale\/spark.git/https:\/\/github.com\/Altiscale\/spark.git/g' .git/config
git submodule update --init --recursive
pushd `pwd`
cd spark
echo "switching to spark branch-0.9 and refetch the files"
git checkout branch-0.9
git fetch --all
popd
tar cvzf spark.tar.gz spark
popd

pushd `pwd`
cd ~
/usr/bin/rpmdev-setuptree

cp "$spark_spec" ~/rpmbuild/SPECS/
cp -r ~/sparkbuild/spark.tar.gz ~/rpmbuild/SOURCES/
rpmbuild -vv -ba ~/rpmbuild/SPECS/spark.spec

echo "Build Completed successfully!"

popd

exit 0

