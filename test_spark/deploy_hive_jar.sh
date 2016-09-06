#!/bin/bash

# This script is NOT thread-safe
# Multiple invocation will result in corrupted zip file
# Last run wins

mypid=$$
tmp_hive_fname_zip=$(basename $(readlink -f $HIVE_HOME))-lib.zip
tmp_hive_lib_zip_tmp=/tmp/$USER-$tmp_hive_fname_zip-$mypid
tmp_hive_lib_zip=/tmp/$USER-$tmp_hive_fname_zip
tmp_hive_lib_zip_md5_tmp=/tmp/$USER-$mypid-$tmp_hive_fname_zip.md5
tmp_hive_lib_zip_md5=/tmp/$USER-$tmp_hive_fname_zip.md5
hive_lib_dir=$(readlink -f $HIVE_HOME)/lib
gen_hive_lib_zip=true

if [ -f $tmp_hive_lib_zip_md5 ] ; then
  md5sum -c $tmp_hive_lib_zip_md5
  ret=$?
  if [ $ret -eq "0" ] ; then
    echo "ok - no need to re-generate the same $tmp_hive_lib_zip, continuing"
    gen_hive_lib_zip=false
  else
    2>&1 echo "warn - $tmp_hive_lib_zip seems to be corrupted or modified, re-generating a new one"
    gen_hive_lib_zip=true
  fi
fi

if  [ "x$gen_hive_lib_zip" = "xtrue" ] ; then
  echo "ok - generating first time hive libs $tmp_hive_lib_zip_tmp for pre-deployment"
  rm -f "$tmp_hive_lib_zip_tmp"
  pushd $hive_lib_dir
  zip --quiet -r $tmp_hive_lib_zip_tmp *
  unzip -qt $tmp_hive_lib_zip_tmp
  ret=$?
  popd
  if [ $ret -eq "0" ] ; then
    # mv shall be atomic, last write wins
    mv $tmp_hive_lib_zip_tmp $tmp_hive_lib_zip
    md5sum $tmp_hive_lib_zip > $tmp_hive_lib_zip_md5_tmp
    mv $tmp_hive_lib_zip_md5_tmp $tmp_hive_lib_zip_md5
    echo "ok - generating $tmp_hive_lib_zip and md5sum $tmp_hive_lib_zip_md5 completed successfully"
  else
    2>&1 echo "fatal - cannot generate $tmp_hive_lib_zip_tmp from hive libs, zip corrupted"
    2>&1 echo "fatal - please check disk space/capacity or system resource"
    rm -f $tmp_hive_lib_zip_tmp
    exit -9
  fi
fi

# Upload the HDFS regardless
hdfs dfs -mkdir /user/$USER/apps
hdfs dfs -put $tmp_hive_lib_zip /user/$USER/apps/$tmp_hive_fname_zip
