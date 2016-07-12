#!/bin/sh

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
run_sparkr="$curr_dir/run_sparkr.sh"
spark_tmp_dir=$(mktemp -d -q --tmpdir=/tmp)

spark_home=${SPARK_HOME:='/opt/spark'}
if [ "x${spark_home}" = "x" ] ; then
  spark_home=/opt/spark
  echo "ok - applying default location $spark_home"
fi

mkdir -p "$spark_tmp_dir/spark/"
echo "ok - duplicating Spark directory to $spark_tmp_dir for SparkR"
cp -rp $spark_home/* "$spark_tmp_dir/spark/"

if [ ! -f "$run_sparkr"  ] ; then
  echo "fail - missing file $run_sparkr for sparkR, can't continue, exiting"
  exit -2
fi

SPARK_HOME="$spark_tmp_dir/spark" $run_sparkr
if [ $? -ne "0" ] ; then
  echo "fail - testing SparkR shell for various algorithm failed!"
  exit -9
else
  echo "ok - cleaning up $spark_tmp_dir"
  rm -rf "$spark_tmp_dir"
fi

exit 0


