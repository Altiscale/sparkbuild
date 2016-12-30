%define rpm_package_name      alti-spark
%define build_service_name    alti-spark
%define spark_folder_name     %{rpm_package_name}-%{_spark_version}
%define spark_testsuite_name  %{spark_folder_name}
%define install_spark_dest    /opt/%{spark_folder_name}
%define install_spark_label   /opt/%{spark_folder_name}/VERSION
%define install_spark_conf    /etc/%{spark_folder_name}
%define install_spark_logs    /service/log/%{_apache_name}/%{rpm_package_name}-%{_spark_version}
%define install_sparkts_initd /etc/init.d
%define spark_release_dir     /opt/%{spark_folder_name}/lib

Name: %{rpm_package_name}-%{_spark_version}
Summary: %{spark_folder_name} RPM Installer without Apache Hadoop and Hive JARs.
Version: %{_spark_version}
Release: %{_altiscale_release_ver}.%{_build_release}%{?dist}
License: Apache Software License 2.0
Group: Development/Libraries
Source: %{_sourcedir}/%{build_service_name}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{release}-root-%{build_service_name}
Requires(pre): shadow-utils
Requires: scala = 2.10.5
Requires: %{rpm_package_name}-%{_spark_version}-yarn-shuffle
Requires: %{rpm_package_name}-%{_spark_version}-devel
# BuildRequires: vcc-hive-%{_hive_version}
BuildRequires: scala = 2.10.5
BuildRequires: apache-maven >= 3.3.3
BuildRequires: jdk >= 1.7.0.51
# The whole purpose for this req is just to repackage the JAR with JDK 1.6
BuildRequires: java-1.6.0-openjdk-devel
# For SparkR, prefer R 3.1.2, but we only have 3.1.1
BuildRequires: vcc-R_3.0.3

Url: http://spark.apache.org/
%description
Build from https://github.com/Altiscale/spark/tree/branch-1.6.2-alti with 
build script https://github.com/Altiscale/sparkbuild/tree/branch-1.6.2-alti
Origin source form https://github.com/apache/spark/tree/branch-1.6
%{spark_folder_name} is a re-compiled and packaged spark distro that is compiled against Altiscale's 
Hadoop 2.7.x with YARN 2.7.x enabled, and hive-1.2.1. This package should work with Altiscale 
Hadoop 2.7.x and Hive 1.2.1 (vcc-hadoop-2.7.1/2 and alti-hive-1.2.0/alti-hive-1.2.1).

%package sparkts
Summary: Spark Thrift Server system service scripts and configuration
Group: Development/Libraries

%description sparkts
A RPM package that provides init.d script and default configuraiton for Spark Thrift Server
Requires Spark and Hive RPM installed.

%package yarn-shuffle
Summary: The pluggable spark_shuffle RPM to install spark_shuffle JAR
Group: Development/Libraries

%description yarn-shuffle
This package contains the yarn-shuffle JAR to enable spark_shuffle on YARN node managers when it is added to NM classpath.

%package devel
Summary: Spark module JARs and libraries compiled by maven
Group: Development/Libraries

%description devel
This package provides spark-core, spark-catalyst, spark-sql, spark-hive, spark-yarn, spark-unsafe, spark-launcher, etc. that are under Apache License 2. Other components that has a different license will be under different package for distribution.

%package kinesis
Summary: Amazon Kinesis libraries to integrate with Spark Streaming compiled by maven
License: Amazon Software License
Group: Development/Libraries

%description kinesis
This package provides the artifact for kinesis integration for Spark. Aware, this is under Amazon Software License (ASL), see: https://aws.amazon.com/asl/ for more information.

%pre

%prep

%setup -q -n %{build_service_name}

%build
if [ "x${SCALA_HOME}" = "x" ] ; then
  echo "ok - SCALA_HOME not defined, trying to set SCALA_HOME to default location /opt/scala/"
  export SCALA_HOME=/opt/scala/
fi
# AE-1226 temp fix on the R PATH
if [ "x${R_HOME}" = "x" ] ; then
  export R_HOME=$(dirname $(rpm -ql $(rpm -qa | grep vcc-R_.*-0.2.0- | sort -r | head -n 1 ) | grep bin | head -n 1))
  if [ "x${R_HOME}" = "x" ] ; then
    echo "warn - R_HOME not defined, CRAN R isn't installed properly in the current env"
  else
    echo "ok - R_HOME redefined to $R_HOME based on installed RPM due to AE-1226"
    export PATH=$PATH:$R_HOME
  fi
fi
if [ "x${JAVA_HOME}" = "x" ] ; then
  export JAVA_HOME=/usr/java/default
  # Hijack JAva path to use our JDK 1.7 here instead of openjdk
  export PATH=$JAVA_HOME/bin:$PATH
fi
export MAVEN_OPTS="-Xmx2048m -XX:MaxPermSize=1024m"

echo "build - entire spark project in %{_builddir}"
pushd `pwd`
cd %{_builddir}/%{build_service_name}/

# clean up for *NIX environment only, deleting window's cmd
find %{_builddir}/%{build_service_name}/bin -type f -name '*.cmd' -exec rm -f {} \;

# Remove launch script AE-579
# find %{_builddir}/%{build_service_name}/sbin -type f -name 'start-*.sh' -exec rm -f {} \;
# find %{_builddir}/%{build_service_name}/sbin -type f -name 'stop-*.sh' -exec rm -f {} \;
rm -f %{_builddir}/%{build_service_name}/sbin/start-slave*
rm -f %{_builddir}/%{build_service_name}/sbin/start-master.sh
rm -f %{_builddir}/%{build_service_name}/sbin/start-all.sh
rm -f %{_builddir}/%{build_service_name}/sbin/stop-slaves.sh
rm -f %{_builddir}/%{build_service_name}/sbin/stop-master.sh
rm -f %{_builddir}/%{build_service_name}/sbin/stop-all.sh
rm -f %{_builddir}/%{build_service_name}/sbin/slaves.sh
rm -f %{_builddir}/%{build_service_name}/sbin/spark-daemons.sh
rm -f %{_builddir}/%{build_service_name}/sbin/spark-executor
rm -f %{_builddir}/%{build_service_name}/sbin/*mesos*.sh
rm -f %{_builddir}/%{build_service_name}/conf/slaves

if [ "x%{_hadoop_version}" = "x" ] ; then
  echo "fatal - HADOOP_VERSION needs to be set, can't build anything, exiting"
  exit -8
else
  export SPARK_HADOOP_VERSION=%{_hadoop_version}
  echo "ok - applying customized hadoop version $SPARK_HADOOP_VERSION"
fi

if [ "x%{_hive_version}" = "x" ] ; then
  echo "fatal - HIVE_VERSION needs to be set, can't build anything, exiting"
  exit -8
else
  export SPARK_HIVE_VERSION=%{_hive_version}
  echo "ok - applying customized hive version $SPARK_HIVE_VERSION"
fi

env | sort

echo "ok - building assembly with HADOOP_VERSION=$SPARK_HADOOP_VERSION HIVE_VERSION=$SPARK_HIVE_VERSION"

########################
# BUILD ENTIRE PACKAGE #
########################
# This will build the overall JARs we need in each folder
# and install them locally for further reference. We assume the build
# environment is clean, so we don't need to delete ~/.ivy2 and ~/.m2
# Default JDK version applied is 1.7 here.

# hadoop.version, yarn.version, and hive.version are all defined in maven profile now
# they are tied to each profile.
# hadoop-2.2 No longer supported, removed.
# hadoop-2.4 hadoop.version=2.4.1 yarn.version=2.4.1 hive.version=0.13.1a hive.short.version=0.13.1
# hadoop-2.6 hadoop.version=2.6.0 yarn.version=2.6.0 hive.version=1.2.1.spark hive.short.version=1.2.1
# hadoop-2.7 hadoop.version=2.7.1 yarn.version=2.7.1 hive.version=1.2.1.spark hive.short.version=1.2.1

hadoop_profile_str=""
testcase_hadoop_profile_str=""
if [[ %{_hadoop_version} == 2.4.* ]] ; then
  hadoop_profile_str="-Phadoop-2.4"
  testcase_hadoop_profile_str="-Phadoop24-provided"
elif [[ %{_hadoop_version} == 2.6.* ]] ; then
  hadoop_profile_str="-Phadoop-2.6"
  testcase_hadoop_profile_str="-Phadoop26-provided"
elif [[ %{_hadoop_version} == 2.7.* ]] ; then
  hadoop_profile_str="-Phadoop-2.7"
  testcase_hadoop_profile_str="-Phadoop27-provided"
else
  echo "fatal - Unrecognize hadoop version $SPARK_HADOOP_VERSION, can't continue, exiting, no cleanup"
  exit -9
fi
xml_setting_str=""

if [ -f %{_mvn_settings} ] ; then
  echo "ok - picking up %{_mvn_settings}"
  xml_setting_str="--settings %{_mvn_settings} --global-settings %{_mvn_settings}"
elif [ -f %{_builddir}/.m2/settings.xml ] ; then
  echo "ok - picking up %{_builddir}/.m2/settings.xml"
  xml_setting_str="--settings %{_builddir}/.m2/settings.xml --global-settings %{_builddir}/.m2/settings.xml"
elif [ -f /etc/alti-maven-settings/settings.xml ] ; then
  echo "ok - applying local installed maven repo settings.xml for first priority"
  xml_setting_str="--settings /etc/alti-maven-settings/settings.xml --global-settings /etc/alti-maven-settings/settings.xml"
else
  echo "ok - applying default repository from pom.xml"
  xml_setting_str=""
fi

# TODO: This needs to align with Maven settings.xml, however, Maven looks for
# -SNAPSHOT in pom.xml to determine which repo to use. This creates a chain reaction on 
# legacy pom.xml design on other application since they are not implemented in the Maven way.
# :-( 
# Will need to create a work around with different repo URL and use profile Id to activate them accordingly
# mvn_release_flag=""
# if [ "x%{_production_release}" == "xtrue" ] ; then
#   mvn_release_flag="-Preleases"
# else
#   mvn_release_flag="-Psnapshots"
# fi

mvn_cmd="mvn -U $hadoop_profile_str -Phadoop-provided -Phive-provided -Psparkr -Pyarn -Pkinesis-asl $xml_setting_str -DskipTests install"
echo "$mvn_cmd"
$mvn_cmd

pushd %{_builddir}/%{build_service_name}/sql/hive-thriftserver/
mvn_spark_hs2_cmd="mvn -U $hadoop_profile_str -Phadoop-provided -Phive-provided -Psparkr -Pyarn $xml_setting_str -DskipTests package"
echo "$mvn_spark_hs2_cmd"
$mvn_spark_hs2_cmd
popd

popd
echo "ok - build spark project completed successfully!"

echo "ok - start repackging assembly JAR with jdk 1.6 due to JIRA AE-1112"
pushd `pwd`
cd %{_builddir}/%{build_service_name}/
%{__mkdir} -p %{_builddir}/%{build_service_name}/tmp/
# AE-1112 pyspark is packaged with JDK 1.7 which will not work. Need to repackage it with 
# JDK 1.6 while not breaking the bytecode, etc. In other word, only the JAR format matters
# and we don't want to compile it with JDK 1.6.
ls -al %{_builddir}/%{build_service_name}/assembly/target/scala-2.10/spark-assembly-%{_spark_version}-hadoop%{_hadoop_version}.jar

cp -p %{_builddir}/%{build_service_name}/assembly/target/scala-2.10/spark-assembly-%{_spark_version}-hadoop%{_hadoop_version}.jar %{_builddir}/%{build_service_name}/tmp/ORG-spark-assembly-%{_spark_version}-hadoop%{_hadoop_version}.jar

ls -al %{_builddir}/%{build_service_name}/tmp/ORG-spark-assembly-%{_spark_version}-hadoop%{_hadoop_version}.jar

pushd %{_builddir}/%{build_service_name}/tmp/
unzip -d tweak_spark ORG-spark-assembly-%{_spark_version}-hadoop%{_hadoop_version}.jar
cd tweak_spark
/usr/lib/jvm/java-1.6.0-openjdk.x86_64/bin/jar cvmf META-INF/MANIFEST.MF %{_builddir}/%{build_service_name}/tmp/REWRAP-spark-assembly-%{_spark_version}-hadoop%{_hadoop_version}.jar .
popd
popd

ls -al %{_builddir}/%{build_service_name}/assembly/target/scala-2.10/spark-assembly-%{_spark_version}-hadoop%{_hadoop_version}.jar
ls -al %{_builddir}/%{build_service_name}/tmp/REWRAP-spark-assembly-%{_spark_version}-hadoop%{_hadoop_version}.jar
cp -fp %{_builddir}/%{build_service_name}/tmp/REWRAP-spark-assembly-%{_spark_version}-hadoop%{_hadoop_version}.jar %{_builddir}/%{build_service_name}/assembly/target/scala-2.10/spark-assembly-%{_spark_version}-hadoop%{_hadoop_version}.jar

echo "ok - complete repackging assembly JAR with jdk 1.6 due to JIRA AE-1112"

# AE-1369
echo "ok - start packging a sparkr.zip for YARN distributed cache, this assumes user isn't going to customize this file"
pushd `pwd`
cd %{_builddir}/%{build_service_name}/
cd R/lib/
/usr/lib/jvm/java-1.6.0-openjdk.x86_64/bin/jar cvMf %{_builddir}/%{build_service_name}/R/lib/sparkr.zip SparkR
popd


%install
# manual cleanup for compatibility, and to be safe if the %clean isn't implemented
rm -rf %{buildroot}%{install_spark_dest}
# re-create installed dest folders
mkdir -p %{buildroot}%{install_spark_dest}
echo "compiled/built folder is (not the same as buildroot) RPM_BUILD_DIR = %{_builddir}"
echo "test installtion folder (aka buildroot) is RPM_BUILD_ROOT = %{buildroot}"
echo "test install spark dest = %{buildroot}/%{install_spark_dest}"
echo "test install spark label spark_folder_name = %{spark_folder_name}"
%{__mkdir} -p %{buildroot}%{install_spark_dest}/
%{__mkdir} -p %{buildroot}/etc/%{install_spark_dest}/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/assembly/target/scala-2.10/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/bagel/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/data/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/examples/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/external/kafka/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/external/kafka-assembly/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/external/flume/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/external/flume-sink/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/external/flume-assembly/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/external/mqtt/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/external/mqtt-assembly/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/external/twitter/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/external/zeromq/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/extras/kinesis-asl/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/extras/kinesis-asl-assembly/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/graphx/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/licenses/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/mllib/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/network/common/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/network/shuffle/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/network/yarn/target/scala-2.10/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/repl/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/streaming/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/sql/hive/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/sql/hive-thriftserver/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/tools/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/lib_managed/jars/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/R/lib/
# Added due to AE-1219 to support Hive 1.2.0+ with Hive on Spark
%{__mkdir} -p %{buildroot}%{install_spark_dest}/lib/
# work and logs folder is for runtime, this is a dummy placeholder here to set the right permission within RPMs
# logs folder should coordinate with log4j and be redirected to /var/log for syslog/flume to pick up
%{__mkdir} -p %{buildroot}%{install_spark_logs}
# copy all necessary jars
cp -rp %{_builddir}/%{build_service_name}/assembly/target/scala-2.10/*.jar %{buildroot}%{install_spark_dest}/assembly/target/scala-2.10/
cp -rp %{_builddir}/%{build_service_name}/bagel/target/*.jar %{buildroot}%{install_spark_dest}/bagel/target/
cp -rp %{_builddir}/%{build_service_name}/examples/target/*.jar %{buildroot}%{install_spark_dest}/examples/target/
# required for python and SQL
cp -rp %{_builddir}/%{build_service_name}/examples/src %{buildroot}%{install_spark_dest}/examples/
cp -rp %{_builddir}/%{build_service_name}/extras/README.md %{buildroot}%{install_spark_dest}/extras/
cp -rp %{_builddir}/%{build_service_name}/extras/kinesis-asl/target/*.jar %{buildroot}%{install_spark_dest}/extras/kinesis-asl/target/
cp -rp %{_builddir}/%{build_service_name}/extras/kinesis-asl-assembly/target/*.jar %{buildroot}%{install_spark_dest}/extras/kinesis-asl-assembly/target/
cp -rp %{_builddir}/%{build_service_name}/tools/target/*.jar %{buildroot}%{install_spark_dest}/tools/target/
cp -rp %{_builddir}/%{build_service_name}/mllib/data %{buildroot}%{install_spark_dest}/mllib/
cp -rp %{_builddir}/%{build_service_name}/mllib/target/*.jar %{buildroot}%{install_spark_dest}/mllib/target/
cp -rp %{_builddir}/%{build_service_name}/graphx/data %{buildroot}%{install_spark_dest}/graphx/
cp -rp %{_builddir}/%{build_service_name}/graphx/target/*.jar %{buildroot}%{install_spark_dest}/graphx/target/
cp -rp %{_builddir}/%{build_service_name}/streaming/target/*.jar %{buildroot}%{install_spark_dest}/streaming/target/
cp -rp %{_builddir}/%{build_service_name}/repl/target/*.jar %{buildroot}%{install_spark_dest}/repl/target/
cp -rp %{_builddir}/%{build_service_name}/bin %{buildroot}%{install_spark_dest}/
cp -rp %{_builddir}/%{build_service_name}/sbin %{buildroot}%{install_spark_dest}/
cp -rp %{_builddir}/%{build_service_name}/python %{buildroot}%{install_spark_dest}/
cp -rp %{_builddir}/%{build_service_name}/project %{buildroot}%{install_spark_dest}/
cp -rp %{_builddir}/%{build_service_name}/docs %{buildroot}%{install_spark_dest}/
cp -rp %{_builddir}/%{build_service_name}/dev %{buildroot}%{install_spark_dest}/
cp -rp %{_builddir}/%{build_service_name}/external/kafka/target/*.jar %{buildroot}%{install_spark_dest}/external/kafka/target/
cp -rp %{_builddir}/%{build_service_name}/external/kafka-assembly/target/*.jar %{buildroot}%{install_spark_dest}/external/kafka-assembly/target/
cp -rp %{_builddir}/%{build_service_name}/external/flume/target/*.jar %{buildroot}%{install_spark_dest}/external/flume/target/
cp -rp %{_builddir}/%{build_service_name}/external/flume-sink/target/*.jar %{buildroot}%{install_spark_dest}/external/flume-sink/target/
cp -rp %{_builddir}/%{build_service_name}/external/flume-assembly/target/*.jar %{buildroot}%{install_spark_dest}/external/flume-assembly/target/
cp -rp %{_builddir}/%{build_service_name}/external/mqtt/target/*.jar %{buildroot}%{install_spark_dest}/external/mqtt/target/
cp -rp %{_builddir}/%{build_service_name}/external/mqtt-assembly/target/*.jar %{buildroot}%{install_spark_dest}/external/mqtt-assembly/target/
cp -rp %{_builddir}/%{build_service_name}/external/twitter/target/*.jar %{buildroot}%{install_spark_dest}/external/twitter/target/
cp -rp %{_builddir}/%{build_service_name}/external/zeromq/target/*.jar %{buildroot}%{install_spark_dest}/external/zeromq/target/
cp -rp %{_builddir}/%{build_service_name}/network/common/target/*.jar %{buildroot}%{install_spark_dest}/network/common/target/
cp -rp %{_builddir}/%{build_service_name}/network/shuffle/target/*.jar %{buildroot}%{install_spark_dest}/network/shuffle/target/
cp -rp %{_builddir}/%{build_service_name}/network/yarn/target/*.jar %{buildroot}%{install_spark_dest}/network/yarn/target/
cp -rp %{_builddir}/%{build_service_name}/network/yarn/target/scala-2.10/*.jar %{buildroot}%{install_spark_dest}/network/yarn/target/scala-2.10/
cp -rp %{_builddir}/%{build_service_name}/sql/hive/target/*.jar %{buildroot}%{install_spark_dest}/sql/hive/target/
cp -rp %{_builddir}/%{build_service_name}/sql/hive-thriftserver/target/*.jar %{buildroot}%{install_spark_dest}/sql/hive-thriftserver/target/
cp -rp %{_builddir}/%{build_service_name}/lib_managed/jars/* %{buildroot}%{install_spark_dest}/lib_managed/jars/
cp -rp %{_builddir}/%{build_service_name}/data/* %{buildroot}%{install_spark_dest}/data/
cp -rp %{_builddir}/%{build_service_name}/R/lib/* %{buildroot}%{install_spark_dest}/R/lib/

# Spark Thrift Server init.d related files
%{__mkdir} -p %{buildroot}%{install_sparkts_initd}
cp -rp %{_builddir}/%{build_service_name}/etc/init.d/* %{buildroot}%{install_sparkts_initd}/

# devel package files
%{__mkdir} -p %{buildroot}%{install_spark_dest}/core/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/sql/catalyst/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/sql/core/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/launcher/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/unsafe/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/yarn/target/
cp -rp %{_builddir}/%{build_service_name}/core/target/*.jar %{buildroot}%{install_spark_dest}/core/target/
cp -rp %{_builddir}/%{build_service_name}/sql/catalyst/target/*.jar %{buildroot}%{install_spark_dest}/sql/catalyst/target/
cp -rp %{_builddir}/%{build_service_name}/sql/core/target/*.jar %{buildroot}%{install_spark_dest}/sql/core/target/
cp -rp %{_builddir}/%{build_service_name}/launcher/target/*.jar %{buildroot}%{install_spark_dest}/launcher/target/
cp -rp %{_builddir}/%{build_service_name}/unsafe/target/*.jar %{buildroot}%{install_spark_dest}/unsafe/target/
cp -rp %{_builddir}/%{build_service_name}/yarn/target/*.jar %{buildroot}%{install_spark_dest}/yarn/target/
 
# test deploy the config folder
cp -rp %{_builddir}/%{build_service_name}/conf %{buildroot}/%{install_spark_conf}

# Inherit license, readme, etc
cp -p %{_builddir}/%{build_service_name}/README.md %{buildroot}%{install_spark_dest}
cp -p %{_builddir}/%{build_service_name}/LICENSE %{buildroot}%{install_spark_dest}
cp -p %{_builddir}/%{build_service_name}/NOTICE %{buildroot}%{install_spark_dest}
cp -p %{_builddir}/%{build_service_name}/CHANGES.txt %{buildroot}%{install_spark_dest}
cp -p %{_builddir}/%{build_service_name}/CONTRIBUTING.md %{buildroot}%{install_spark_dest}
cp -p %{_builddir}/%{build_service_name}/licenses/* %{buildroot}%{install_spark_dest}/licenses/

# This will capture the installation property form this spec file for further references
rm -f %{buildroot}/%{install_spark_label}
touch %{buildroot}/%{install_spark_label}
echo "name=%{name}" >> %{buildroot}/%{install_spark_label}
echo "version=%{_spark_version}" >> %{buildroot}/%{install_spark_label}
echo "release=%{name}-%{release}" >> %{buildroot}/%{install_spark_label}
echo "git_rev=%{_git_hash_release}" >> %{buildroot}/%{install_spark_label}

# add dummy file to warn user that CLUSTER mode is not for Production
echo "Currently, standalone mode is DISABLED, and it is not suitable for Production environment" >  %{buildroot}%{install_spark_dest}/sbin/CLUSTER_STANDALONE_MODE_NOT_SUPPORTED.why.txt

%clean
echo "ok - cleaning up temporary files, deleting %{buildroot}%{install_spark_dest}"
rm -rf %{buildroot}%{install_spark_dest}

%files
%defattr(0755,root,root,0755)
%{install_spark_dest}/bin
%{install_spark_dest}/project
%{install_spark_dest}/assembly
%{install_spark_dest}/data
%{install_spark_dest}/dev
%{install_spark_dest}/bagel
%{install_spark_dest}/examples
%{install_spark_dest}/external
%dir %{install_spark_dest}/extras
%{install_spark_dest}/extras/README.md
%{install_spark_dest}/graphx
%{install_spark_dest}/lib
%{install_spark_dest}/lib_managed
%{install_spark_dest}/licenses
%{install_spark_dest}/mllib
%{install_spark_dest}/network/common
%{install_spark_dest}/network/shuffle
%dir %{install_spark_dest}/network
%dir %{install_spark_dest}/network/yarn
%dir %{install_spark_dest}/network/yarn/target
%{install_spark_dest}/network/yarn/target/spark-network-yarn_2.10-%{_spark_version}-tests.jar
%{install_spark_dest}/network/yarn/target/spark-network-yarn_2.10-%{_spark_version}.jar
%{install_spark_dest}/network/yarn/target/spark-network-yarn_2.10-%{_spark_version}-test-sources.jar
%{install_spark_dest}/network/yarn/target/spark-network-yarn_2.10-%{_spark_version}-javadoc.jar
%{install_spark_dest}/network/yarn/target/spark-network-yarn_2.10-%{_spark_version}-sources.jar
%{install_spark_dest}/python
%{install_spark_dest}/R
%{install_spark_dest}/repl
%{install_spark_dest}/sbin
%dir %{install_spark_dest}/sql
%{install_spark_dest}/sql/hive
%{install_spark_dest}/sql/hive-thriftserver
%{install_spark_dest}/streaming
%{install_spark_dest}/tools
%docdir %{install_spark_dest}/docs
%{install_spark_dest}/docs
%doc %{install_spark_label}
%doc %{install_spark_dest}/LICENSE
%doc %{install_spark_dest}/README.md
%doc %{install_spark_dest}/NOTICE
%doc %{install_spark_dest}/CHANGES.txt
%doc %{install_spark_dest}/CONTRIBUTING.md
%attr(0644,root,root) %{install_spark_conf}/log4j.properties
%attr(0644,root,root) %{install_spark_conf}/*.template
%attr(1777,root,root) %{install_spark_logs}
%config %{install_spark_conf}

%files sparkts
%attr(0755,root,root) %{install_sparkts_initd}/sparktsd-%{_spark_version}

%files yarn-shuffle
%defattr(0755,root,root,0755)
%{install_spark_dest}/network/yarn/target/scala-2.10/

%files devel
%defattr(0755,root,root,0755)
%{install_spark_dest}/core
%{install_spark_dest}/sql/catalyst
%{install_spark_dest}/sql/core
%{install_spark_dest}/launcher
%{install_spark_dest}/unsafe
%{install_spark_dest}/yarn

%files kinesis
%defattr(0755,root,root,0755)
%{install_spark_dest}/extras/kinesis-asl
%{install_spark_dest}/extras/kinesis-asl-assembly

%post
if [ "$1" = "1" ]; then
  echo "ok - performing fresh installation"
elif [ "$1" = "2" ]; then
  echo "ok - upgrading system"
fi
# TODO: Move to Chef later. The symbolic link is version sensitive
# CLean up old symlink
rm -vf %{install_spark_dest}/logs
rm -vf %{install_spark_dest}/conf
# Restore conf and logs symlink
ln -vsf %{install_spark_conf} %{install_spark_dest}/conf
ln -vsf %{install_spark_logs} %{install_spark_dest}/logs
ln -vsf %{install_spark_dest}/assembly/target/scala-2.10/spark-assembly-%{_spark_version}-hadoop%{_hadoop_version}.jar %{spark_release_dir}/spark-assembly-%{_spark_version}.jar
# For backward compatibility which requires hadoop version
ln -vsf %{install_spark_dest}/assembly/target/scala-2.10/spark-assembly-%{_spark_version}-hadoop%{_hadoop_version}.jar %{spark_release_dir}/spark-assembly-%{_spark_version}-hadoop%{_hadoop_version}.jar
# for f in `find %{install_spark_dest}/lib_managed/jars/ -name "datanucleus-*.jar"`
# do
#   ln -vsf $f %{spark_release_dir}/
# done
ln -vsf %{install_spark_dest}/examples/target/spark-examples_2.10-%{_spark_version}.jar %{spark_release_dir}/
ln -vsf %{install_spark_dest}/network/yarn/target/scala-2.10/spark-%{_spark_version}-yarn-shuffle.jar %{spark_release_dir}/
ln -vsf %{install_spark_dest}/sql/hive/target/spark-hive_2.10-%{_spark_version}.jar %{spark_release_dir}/spark-hive_2.10.jar
ln -vsf %{install_spark_dest}/sql/hive-thriftserver/target/spark-hive-thriftserver_2.10-%{_spark_version}.jar %{spark_release_dir}/spark-hive-thriftserver_2.10.jar

%postun
if [ "$1" = "0" ]; then
  ret=$(rpm -qa | grep %{rpm_package_name} | grep -v example | grep -v yarn-shuffle | wc -l)
  # The rpm is already uninstall and shouldn't appear in the counts
  if [ "x${ret}" != "x0" ] ; then
    echo "ok - detected other spark version, no need to clean up symbolic links"
    echo "ok - cleaning up version specific directories only regarding this uninstallation"
    rm -vrf %{install_spark_dest}
    rm -vrf %{install_spark_conf}
  else
    echo "ok - uninstalling %{rpm_package_name} on system, removing symbolic links"
    rm -vf %{install_spark_dest}/logs
    rm -vf %{install_spark_dest}/conf
    rm -vrf %{install_spark_dest}
    rm -vrf %{install_spark_conf}
  fi
fi
# Don't delete the users after uninstallation.

%postun devel
if [ "$1" = "0" ]; then
  ret=$(rpm -qa | grep %{rpm_package_name} | grep devel | grep -v example | wc -l)
  # The devel rpm is already uninstall and shouldn't appear in the counts
  if [ "x${ret}" != "x0" ] ; then
    echo "ok - detected other spark development package version"
    echo "ok - cleaning up version specific directories only regarding ${ret} uninstallation"
    rm -vrf %{install_spark_dest}/core
    rm -vrf %{install_spark_dest}/sql/catalyst
    rm -vrf %{install_spark_dest}/sql/core
    rm -vrf %{install_spark_dest}/sql/hive
    rm -vrf %{install_spark_dest}/launcher
    rm -vrf %{install_spark_dest}/unsafe
    rm -vrf %{install_spark_dest}/yarn
  else
    echo "ok - uninstalling %{rpm_package_name}-devel on system, removing everything related except the parent directoy /opt/%{_apache_name}"
    rm -vrf %{install_spark_dest}/core
    rm -vrf %{install_spark_dest}/sql/catalyst
    rm -vrf %{install_spark_dest}/sql/core
    rm -vrf %{install_spark_dest}/sql/hive
    rm -vrf %{install_spark_dest}/launcher
    rm -vrf %{install_spark_dest}/unsafe
    rm -vrf %{install_spark_dest}/yarn
  fi
fi

%postun kinesis
if [ "$1" = "0" ]; then
  ret=$(rpm -qa | grep %{rpm_package_name} | grep kinesis | grep -v example | wc -l)
  # The kinesis rpm is already uninstall and shouldn't appear in the counts
  if [ "x${ret}" != "x0" ] ; then
    echo "ok - detected other spark kinesis package version"
    echo "ok - cleaning up version specific directories only regarding ${ret} uninstallation"
    rm -vrf %{install_spark_dest}/extras/kinesis-asl
    rm -vrf %{install_spark_dest}/extras/kinesis-asl-assembly
  else
    echo "ok - uninstalling %{rpm_package_name}-kinesis on system, removing everything related except the parent directoy /opt/%{_apache_name}"
    rm -vrf %{install_spark_dest}/extras/kinesis-asl
    rm -vrf %{install_spark_dest}/extras/kinesis-asl-assembly
  fi
fi

%changelog
* Tue Sep 13 2016 Andrew Lee 20160913
- Add hive dependency to sparkts pkg
* Thu Sep 8 2016 Andrew Lee 20160908
- Remove spark example pkg
* Thu Aug 25 2016 Andrew Lee 20160825
- Breakup Spark 1.6 to multiple packages and refactor spec file with rpm macros
* Thu Jun 9 2016 Andrew Lee 20160609
- Add default initd and look for sysconfig for sparktsd
* Fri Aug 21 2015 Andrew Lee 20150821
- Update RPM file listing
* Tue Aug 11 2015 Andrew Lee 20150811
- Update spark version to 1.5 
* Wed Jul 29 2015 Andrew Lee 20150729
- Update install section with new directories lib for AE-1219
* Mon Jul 6 2015 Andrew Lee 20150706
- Rename spark test RPM pkg to example
* Tue Jun 9 2015 Andrew Lee 20150609
- Fix post uninstall operation
* Tue Jun 9 2015 Andrew Lee 20150609
- Update spark version to 1.4
* Mon Mar 30 2015 Andrew Lee 20150330
- Update spark version to 1.3
* Tue Dec 23 2014 Andrew Lee 20141223
- Output maven build command in build macro, added more files from test case
* Sat Oct 18 2014 Andrew Lee 20141018
- Add test package spec and source files, updated files for rpm package
* Fri Aug 8 2014 Andrew Lee 20140808
- Add new statement to post installation section, creating log directory
* Mon Jun 23 2014 Andrew Lee 20140623
- Update pre macro to identify update versus fresh installation
* Fri May 23 2014 Andrew Lee 20140523
- Removed Require tag for java. Update install macro to include more sample data for mllib/data
* Tue May 20 2014 Andrew Lee 20140520
- Update log folder macro, added post section, fix build command for hadoop 2.2
* Tue May 13 2014 Andrew Lee 20140513
- Commented out patch, no need for patch. Patch is now merged into git during Spark checkout.
* Mon Apr 7 2014 Andrew Lee 20140407
- Added log4j settings, and create /etc/spark-0.9.1 for Chef to pick up in post-installation
* Sun Apr 6 2014 Andrew Lee 20140406
- Added KMean test data, and run-example2 to locate default classpath for SPARK_JAR and SPARK_YARN_APP_JAR
* Fri Apr 4 2014 Andrew Lee 20140404
- Change UID to 411460024, and rename it back to alti-spark, add missing JARs for mllib and graphx
* Wed Apr 2 2014 Andrew Lee 20140402
- Rename Spark pkg name to vcc-spark so we can identify our own build
* Wed Mar 19 2014 Andrew Lee 20140319
- Initial Creation of spec file for Spark 0.9.1
