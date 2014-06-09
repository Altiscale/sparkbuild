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
  export MAVEN_OPTS="-Xmx2048m -XX:MaxPermSize=1024m"
fi
if [ "x${SCALA_HOME}" = "x" ] ; then
  export SCALA_HOME=/opt/scala
fi

export PATH=$PATH:$M2_HOME/bin:$SCALA_HOME/bin:$ANT_HOME/bin:$JAVA_HOME/bin

# Define defau;t spark uid:gid and build version
# WARNING: the SPARK_VERSION branch name does not align with the Git branch name branch-0.9
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
  export SPARK_VERSION=0.9.1
fi
if [ "x${ALTISCALE_RELEASE}" = "x" ] ; then
  export ALTISCALE_RELEASE=2.0.0
else
  export ALTISCALE_RELEASE
fi

BUILD_TIME=$(date +%Y%m%d%H%M)
export BUILD_TIME

# Customize build OPTS for MVN
export MAVEN_OPTS="-Xmx2048m -XX:MaxPermSize=1024m"




