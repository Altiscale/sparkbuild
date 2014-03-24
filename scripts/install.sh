#!/bin/bash

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
rpm_file=""

if [ -f "$curr_dir/setup_env.sh" ]; then
  source "$curr_dir/setup_env.sh"
fi

if [ "x${WORKSPACE}" = "x" ] ; then
  WORKSPACE="$curr_dir/../"
fi

env | sort

# TBD: Verification on the RPM should be performed
rpm_file=$WORKSPACE/rpmbuild/RPMS/x86_64/spark-0.9.0-1.el6.x86_64.rpm
if [ ! -f "$rpm_file" ] ; then
  echo "fatal - can't find RPM $rpm_file to install, can't continue, exiting"
  exit -5
else
  echo "ok - $rpm_file test installed successfully. Basically, this is already covered in the RPM spec file, this file $0 is redundant"
fi

exit 0












