#!/bin/bash -x

# We want to honor SPARK_CONF_DIR if someone override this with their
# own config. Our test case shall pass as well.
spark_conf_dir_tmp=$SPARK_CONF_DIR
if [ "x${spark_conf_dir_tmp}" = "x" ] ; then
  spark_conf_dir_tmp=/etc/spark
fi
echo "ok - applying Spark conf $spark_conf_dir_tmp"

# Load other env variables defined in the SPARK_CONF_DIR such as SPARK_VERSION, etc.
# This file must exist for all Spark installation
if [ -f "$spark_conf_dir_tmp/spark-env.sh" ] ; then
  source $spark_conf_dir_tmp/spark-env.sh
else
  >&2 echo "fail - spark installation not completed, missing directory or files from $spark_conf_dir_tmp"
  exit -1
fi

spark_version=$SPARK_VERSION
kerberos_enable=false
spark_home_tmp=$SPARK_HOME

# Sanity check on SPARK_VERSION
if [ "x${spark_version}" = "x" ] ; then
  >&2 echo "fail - cannot detect SPARK_VERSION from $spark_conf_dir_tmp/spark-env.sh"
  >&2 echo "fail - you need to define SPARK_VERSOIN in $spark_conf_dir_tmp/spark-env.sh or SPARK_VERSION env variable"
  exit -1
fi

# Sanity check on SPARK_HOME
if [ "x${spark_home_tmp}" = "x" ] ; then
  spark_home_tmp=/opt/spark
  if [[ ! -L "$spark_home_tmp" && ! -d "$spark_home_tmp" ]] ; then
    >&2 echo "fail - $spark_home_tmp does not exist, can't continue, exiting! check spark installation."
    exit -1
  fi
  echo "ok - applying default location $spark_home"
fi

# Check Spark RPM installation
spark_installed=$(rpm -qa | grep alti-spark | grep $spark_version | grep -v test | grep -v example | wc -l)
if [ "x${spark_installed}" = "x0" ] ; then
  >&2 echo "fail - spark for $spark_version not detected or installed, can't continue, exiting"
  >&2 echo "fail - you should install spark via RPM, if you install them from binary distros, you will need to tweak these test case"
  exit -2
elif [ "x${spark_installed}" = "x1" ] ; then
  echo "ok - detect one version of spark $spark_version installed that aligns with these test case"
  echo "ok - $(rpm -q $(rpm -qa | grep alti-spark | grep $spark_version)) installed"
else
  echo "warn - detected more than 1 spark $spark_version installed, be aware that test case may refer to different directories"
fi

# Create HDFS folders for Spark Event logs
# Doesn't matter who runs it.
# TODO: Move to Chef, and support Kerberos since HADOOP_USER_NAME will
# be invalid after enabling Kerberos.
spark_conf_tmp="${spark_conf_dir_tmp}/spark-defaults.conf"
if [ ! -f $spark_conf_tmp ] ; then
  >&2 echo "fatal - spark config not found, installation not complete, exiting!!!"
  exit -2
fi

# Prepare Spark user event log HDFS directory for every new users running Spark for the first time
event_log_dir=$(grep 'spark.history.fs.logDirectory' $spark_conf_tmp | tr -s ' ' '\t' | cut -f2)
hdfs dfs -mkdir $event_log_dir/$USER
