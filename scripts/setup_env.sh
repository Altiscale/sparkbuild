#!/bin/bash

# TBD: honor system pre-defined property/variable files from 
# /etc/hadoop/ and other /etc config for spark, hdfs, hadoop, etc

if [ "x${JAVA_HOME}" = "x" ] ; then
  export JAVA_HOME=/usr/java/default
fi
if [ "x${ANT_HOME}" = "x" ] ; then
  export ANT_HOME=/opt/apache-ant
fi
if [ "x${MAVEN_HOME}" = "x" ] ; then
  export MAVEN_HOME=/opt/apache-maven
fi
if [ "x${M2_HOME}" = "x" ] ; then
  export M2_HOME=/opt/apache-maven
fi
if [ "x${MAVEN_OPTS}" = "x" ] ; then
  export MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=1024M -XX:ReservedCodeCacheSize=512m"
fi
if [ "x${SCALA_HOME}" = "x" ] ; then
  export SCALA_HOME=/opt/scala
fi
if [ "x${HADOOP_VERSION}" = "x" ] ; then
  export HADOOP_VERSION=2.4.1
fi
if [ "x${HIVE_VERSION}" = "x" ] ; then
  export HIVE_VERSION=0.13.1
fi
# AE-1226 temp fix on the R PATH
if [ "x${R_HOME}" = "x" ] ; then
  export R_HOME=$(dirname $(rpm -ql $(rpm -qa | grep vcc-R_.*-0.2.0- | sort -r | head -n 1 ) | grep bin | head -n 1))
  if [ "x${R_HOME}" = "x" ] ; then
    echo "warn - R_HOME not defined, CRAN R isn't installed properly in the current env"
  else
    echo "ok - R_HOME redefined to $R_HOME based on installed RPM due to AE-1226"
  fi
fi

export PATH=$PATH:$M2_HOME/bin:$SCALA_HOME/bin:$ANT_HOME/bin:$JAVA_HOME/bin:$R_HOME

# Define defau;t spark uid:gid and build version
if [ "x${SPARK_USER}" = "x" ] ; then
  export SPARK_USER=spark
fi
if [ "x${SPARK_GID}" = "x" ] ; then
  export SPARK_GID=411460017
fi
if [ "x${SPARK_UID}" = "x" ] ; then
  export SPARK_UID=411460024
fi
if [ "x${SPARK_VERSION}" = "x" ] ; then
  export SPARK_VERSION=1.4.0
fi
if [ "x${SPARK_PLAIN_VERSION}" = "x" ] ; then
  export SPARK_PLAIN_VERSION=1.4.0
fi

if [ "x${HADOOP_VERSION}" = "x2.2.0" ] ; then
  export SPARK_VERSION="$SPARK_VERSION.hadoop22"
elif [ "x${HADOOP_VERSION}" = "x2.4.0" ] ; then
  export SPARK_VERSION="$SPARK_VERSION.hadoop24"
elif [ "x${HADOOP_VERSION}" = "x2.4.1" ] ; then
  export SPARK_VERSION="$SPARK_VERSION.hadoop24"
else
  echo "error - can't recognize altiscale's HADOOP_VERSION=$HADOOP_VERSION"
fi

if [ "x${HIVE_VERSION}" = "x0.12.0" ] ; then
  export SPARK_VERSION="$SPARK_VERSION.hive12"
elif [ "x${HIVE_VERSION}" = "x0.13.0" ] ; then
  export SPARK_VERSION="$SPARK_VERSION.hive13"
elif [ "x${HIVE_VERSION}" = "x0.13.1" ] ; then
  export SPARK_VERSION="$SPARK_VERSION.hive13"
else
  echo "error - can't recognize altiscale's HIVE_VERSION=$HIVE_VERSION"
fi

if [ "x${ALTISCALE_RELEASE}" = "x" ] ; then
  if [ "x${HADOOP_VERSION}" = "x2.2.0" ] ; then
    export ALTISCALE_RELEASE=2.0.0
  elif [ "x${HADOOP_VERSION}" = "x2.4.0" ] ; then
    export ALTISCALE_RELEASE=3.0.0
  elif [ "x${HADOOP_VERSION}" = "x2.4.1" ] ; then
    export ALTISCALE_RELEASE=3.0.0
  else
    echo "error - can't recognize altiscale's HADOOP_VERSION=$HADOOP_VERSION for ALTISCALE_RELEASE"
  fi 
else
  export ALTISCALE_RELEASE
fi 

if [ "x${BRANCH_NAME}" = "x" ] ; then
  export BRANCH_NAME=altiscale-branch-1.3
fi

if [ "x${BUILD_TIMEOUT}" = "x" ] ; then
  export BUILD_TIMEOUT=28800
fi

BUILD_TIME=$(date +%Y%m%d%H%M)
export BUILD_TIME

# Customize build OPTS for MVN
export MAVEN_OPTS="-Xmx2048m -XX:MaxPermSize=1024m"




