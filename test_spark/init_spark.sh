#!/bin/bash -x

# We want to honot SPARK_CONF_DIR if someone override this with their
# own config. Our test case shall pass as well.
spark_conf_dir=$SPARK_CONF_DIR
if [ "x${spark_conf_dir}" = "x" ] ; then
  spark_conf_dir=/etc/spark
fi

echo "ok - applying Spark conf $spark_conf_dir"

if [ -f "$spark_conf_dir/spark-env.sh" ] ; then
  source $spark_conf_dir/spark-env.sh
fi
spark_version=$SPARK_VERSION
kerberos_enable=false
spark_home_tmp=$SPARK_HOME

if [ "x${spark_version}" = "x" ] ; then
  >&2 echo "fail - cannot detect SPARK_VERSION from /etc/spark/spark-env.sh"
  >&2 echo "fail - you need to define SPARK_VERSOIN in $spark_conf_dir/spark-env.sh or SPARK_VERSION env variable"
  exit -1
fi

if [ ! -d $spark_home_tmp ] ; then
  >&2 echo "fail - SPARK_HOME isn't defined, can't continue, is spark installed correctly?"
  exit -1
fi

# Check Spark RPM installation

spark_installed=$(rpm -qa | grep alti-spark | grep $spark_version | grep -v test | grep -v example | wc -l)
if [ "x${spark_installed}" = "x0" ] ; then
  >&2 echo "fail - spark for $spark_Version not detected or installed, can't continue, exiting"
  >&2 echo "fail - you should install spark via RPM, if you install them from binary distros, you will need to tweak these test case"
  exit -2
elif [ "x${spark_installed}" = "x1" ] ; then
  echo "ok - detect one version of spark $spark_Version installed that aligns with these test case"
  echo "ok - $(rpm -q $(rpm -qa | grep alti-spark | grep $spark_version)) installed"
else
  echo "warn - detected more than 1 spark $spark_Version installed, be aware that test case may refer to different directories"
fi

# Create HDFS folders for Spark Event logs
# Doesn't matter who runs it.
# TBD: Move to Chef, and support Kerberos since HADOOP_USER_NAME will
# be invalid after enabling Kerberos.
spark_conf="/etc/spark/spark-defaults.conf"

if [ ! -f $spark_conf ] ; then
  echo "fatal - spark config not found, installation not complete, exiting!!!"
  exit -2
fi

event_log_dir=$(grep 'spark.history.fs.logDirectory' $spark_conf | tr -s ' ' '\t' | cut -f2)

hdfs dfs -mkdir $event_log_dir/$USER
