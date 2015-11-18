%global apache_name           SPARK_USER
%global spark_uid             SPARK_UID
%global spark_gid             SPARK_GID

%define altiscale_release_ver ALTISCALE_RELEASE
%define rpm_package_name      alti-spark
%define spark_version         SPARK_VERSION_REPLACE
%define spark_plain_version   SPARK_PLAINVERSION_REPLACE
%define current_workspace     CURRENT_WORKSPACE_REPLACE
%define hadoop_version        HADOOP_VERSION_REPLACE
%define hadoop_build_version  HADOOP_BUILD_VERSION_REPLACE
%define hive_version          HIVE_VERSION_REPLACE
%define build_service_name    alti-spark
%define spark_folder_name     %{rpm_package_name}-%{spark_version}
%define spark_testsuite_name  %{spark_folder_name}
%define install_spark_dest    /opt/%{spark_folder_name}
%define install_spark_label   /opt/%{spark_folder_name}/VERSION
%define install_spark_conf    /etc/%{spark_folder_name}
%define install_spark_logs    /service/log/%{apache_name}
%define install_spark_test    /opt/%{spark_testsuite_name}/test_spark
%define spark_release_dir     /opt/%{apache_name}/lib
%define build_release         BUILD_TIME

Name: %{rpm_package_name}-%{spark_version}
Summary: %{spark_folder_name} RPM Installer AE-576, cluster mode restricted with warnings
Version: %{spark_version}
Release: %{altiscale_release_ver}.%{build_release}%{?dist}
License: ASL 2.0
Group: Development/Libraries
Source: %{_sourcedir}/%{build_service_name}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{release}-root-%{build_service_name}
Requires(pre): shadow-utils
Requires: scala = 2.10.5
Requires: %{rpm_package_name}-%{spark_version}-example
Requires: %{rpm_package_name}-%{spark_version}-yarn-shuffle
# BuildRequires: vcc-hive-%{hive_version}
BuildRequires: scala = 2.10.5
BuildRequires: apache-maven >= 3.3.3
BuildRequires: jdk >= 1.7.0.51
# The whole purpose for this req is just to repackage the JAR with JDK 1.6
BuildRequires: java-1.6.0-openjdk-devel
# For SparkR, prefer R 3.1.2, but we only have 3.1.1
BuildRequires: vcc-R_3.0.3

Url: http://spark.apache.org/
%description
Build from https://github.com/Altiscale/spark/tree/altiscale-branch-1.4 with 
build script https://github.com/Altiscale/sparkbuild/tree/altiscale-branch-1.4 
Origin source form https://github.com/apache/spark/tree/branch-1.4
%{spark_folder_name} is a re-compiled and packaged spark distro that is compiled against Altiscale's 
Hadoop 2.4.x with YARN 2.4.x enabled, and hive-1.2.1. This package should work with Altiscale 
Hadoop 2.4.1 and Hive 1.2.1 (vcc-hadoop-2.4.1 and alti-hive-1.2.0).

%package example
Summary: The test example package for Spark
Group: Development/Libraries
Requires: %{rpm_package_name}-%{spark_version}

%description example
The test example directory to test Spark REPL shell, submit, sparksql after installing spark.

%package yarn-shuffle
Summary: The pluggable spark_shuffle RPM to install spark_shuffle JAR
Group: Development/Libraries

%description yarn-shuffle
This package contains the yarn-shuffle JAR to enable spark_shuffle on YARN node managers when it is added to NM classpath.

%package devel
Summary: Spark module JARs and libraries compiled by maven
Group: Development/Libraries

%description devel
This package provides spark-core, spark-catalyst, spark-sql, spark-hive, spark-yarn, spark-unsafe, spark-launcher, spark-kinesis-asl spark-gangalia-lgpl jars, etc.

%pre
# Soft creation for spark user if it doesn't exist. This behavior is idempotence to Chef deployment.
# Should be harmless. MAKE SURE UID and GID is correct FIRST!!!!!!
# getent group %{apache_name} >/dev/null || groupadd -f -g %{spark_gid} -r %{apache_name}
# if ! getent passwd %{apache_name} >/dev/null ; then
#    if ! getent passwd %{spark_uid} >/dev/null ; then
#      useradd -r -u %{spark_uid} -g %{apache_name} -c "Soft creation of user and group of spark for manual deployment" %{apache_name}
#    else
#      useradd -r -g %{apache_name} -c "Soft adding user spark to group spark for manual deployment" %{apache_name}
#    fi
# fi

%prep
# copying files into BUILD/spark/ e.g. BUILD/spark/* 
# echo "ok - copying files from %{_sourcedir} to folder  %{_builddir}/%{build_service_name}"
# cp -r %{_sourcedir}/%{build_service_name} %{_builddir}/

# %patch1 -p0

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

echo "build - spark core in %{_builddir}"
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

if [ "x%{hadoop_version}" = "x" ] ; then
  echo "fatal - HADOOP_VERSION needs to be set, can't build anything, exiting"
  exit -8
else
  export SPARK_HADOOP_VERSION=%{hadoop_version}
  echo "ok - applying customized hadoop version $SPARK_HADOOP_VERSION"
fi

if [ "x%{hadoop_build_version}" = "x" ] ; then
  echo "fatal - hadoop_build_version needs to be set, can't build anything, exiting"
  exit -8
fi

if [ "x%{hive_version}" = "x" ] ; then
  echo "fatal - HIVE_VERSION needs to be set, can't build anything, exiting"
  exit -8
else
  export SPARK_HIVE_VERSION=%{hive_version}
  echo "ok - applying customized hive version $SPARK_HIVE_VERSION"
fi

# Always build with YARN
export SPARK_YARN=true
# Build SPARK with Hive
export SPARK_HIVE=true

env | sort

echo "ok - building assembly with HADOOP_VERSION=$SPARK_HADOOP_VERSION HIVE_VERSION=$SPARK_HIVE_VERSION SPARK_YARN=$SPARK_YARN SPARK_HIVE=$SPARK_HIVE"

# PURGE LOCAL CACHE for clean build
# mvn dependency:purge-local-repository

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

if [ -f /etc/alti-maven-settings/settings.xml ] ; then
  echo "ok - applying local maven repo settings.xml for first priority"
  if [[ $SPARK_HADOOP_VERSION == 2.4.* ]] ; then
    echo "mvn -U -X -Phadoop-2.4 -Psparkr -Pyarn -Phive -Phive-thriftserver -Pkinesis-asl --settings /etc/alti-maven-settings/settings.xml --global-settings /etc/alti-maven-settings/settings.xml -DskipTests install"
    mvn -U -X -Phadoop-2.4 -Psparkr -Pyarn -Phive -Phive-thriftserver -Pkinesis-asl --settings /etc/alti-maven-settings/settings.xml --global-settings /etc/alti-maven-settings/settings.xml -DskipTests install
  elif [[ $SPARK_HADOOP_VERSION == 2.6.* ]] ; then
    echo "mvn -U -X -Phadoop-2.6 -Psparkr -Pyarn -Phive -Phive-thriftserver -Pkinesis-asl --settings /etc/alti-maven-settings/settings.xml --global-settings /etc/alti-maven-settings/settings.xml -DskipTests install"
    mvn -U -X -Phadoop-2.6 -Psparkr -Pyarn -Phive -Phive-thriftserver -Pkinesis-asl --settings /etc/alti-maven-settings/settings.xml --global-settings /etc/alti-maven-settings/settings.xml -DskipTests install
  elif [[ $SPARK_HADOOP_VERSION == 2.7.* ]] ; then
    echo "mvn -U -X -Phadoop-2.7 -Psparkr -Pyarn -Phive -Phive-thriftserver -Pkinesis-asl --settings /etc/alti-maven-settings/settings.xml --global-settings /etc/alti-maven-settings/settings.xml -DskipTests install"
    mvn -U -X -Phadoop-2.7 -Psparkr -Pyarn -Phive -Phive-thriftserver -Pkinesis-asl --settings /etc/alti-maven-settings/settings.xml --global-settings /etc/alti-maven-settings/settings.xml -DskipTests install
  else
    echo "fatal - Unrecognize hadoop version $SPARK_HADOOP_VERSION, can't continue, exiting, no cleanup"
    exit -9
  fi
else
  echo "ok - applying default repository form pom.xml"
  if [[ $SPARK_HADOOP_VERSION == 2.4.* ]] ; then
    echo "mvn -U -X -Phadoop-2.4 -Psparkr -Pyarn -Phive -Phive-thriftserver -Pkinesis-asl -DskipTests install"
    mvn -U -X -Phadoop-2.4 -Psparkr -Pyarn -Phive -Phive-thriftserver -Pkinesis-asl -DskipTests install
  elif [[ $SPARK_HADOOP_VERSION == 2.6.* ]] ; then
    echo "mvn -U -X -Phadoop-2.6 -Psparkr -Pyarn -Phive -Phive-thriftserver -Pkinesis-asl -DskipTests install"
    mvn -U -X -Phadoop-2.6 -Psparkr -Pyarn -Phive -Phive-thriftserver -Pkinesis-asl -DskipTests install
  elif [[ $SPARK_HADOOP_VERSION == 2.7.* ]] ; then
    echo "mvn -U -X -Phadoop-2.7 -Psparkr -Pyarn -Phive -Phive-thriftserver -DskipTests install"
    mvn -U -X -Phadoop-2.7 -Psparkr -Pyarn -Phive -Phive-thriftserver -Pkinesis-asl -DskipTests install
  else
    echo "fatal - Unrecognize hadoop version $SPARK_HADOOP_VERSION, can't continue, exiting, no cleanup"
    exit -9
  fi
fi

popd
echo "ok - build spark core completed successfully!"

echo "ok - start building spark test case in %{_builddir}/%{build_service_name}/test_spark"
pushd `pwd`
cd %{_builddir}/%{build_service_name}/test_spark

echo "ok - local repository will be installed under %{current_workspace}/.m2/repository"
# TODO: Install local JARs to local repo so we apply the latest built assembly JARs from above
# This is a workaround(hack). A better way is to deploy it to SNAPSHOT on Archiva via maven-deploy plugin,
# and include it in the test_case pom.xml. This is really annoying.
# spark_version is different then spark_plain_Version

if [ ! -d "%{current_workspace}/.m2" ] ; then
  # This usually happens in mock, the default local repository will be the same in this case
  # no need to specify it here.
  mvn -U org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file -Dfile=`pwd`/../assembly/target/scala-2.10/spark-assembly-%{spark_plain_version}-hadoop%{hadoop_build_version}.jar -DgroupId=local.org.apache.spark -DartifactId=spark-assembly_2.10 -Dversion=%{spark_plain_version} -Dpackaging=jar 
  # For Kafka Examples
  mvn -U org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file -Dfile=`pwd`/../external/kafka/target/spark-streaming-kafka_2.10-%{spark_plain_version}.jar -DgroupId=local.org.apache.spark -DartifactId=spark-streaming-kafka_2.10 -Dversion=%{spark_plain_version} -Dpackaging=jar
  mvn -U org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file -Dfile=`pwd`/../streaming/target/spark-streaming_2.10-%{spark_plain_version}.jar -DgroupId=local.org.apache.spark -DartifactId=spark-streaming_2.10 -Dversion=%{spark_plain_version} -Dpackaging=jar
else
  # This applies to local hand build with a existing user
  mvn -U org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file -Dfile=`pwd`/../assembly/target/scala-2.10/spark-assembly-%{spark_plain_version}-hadoop%{hadoop_build_version}.jar -DgroupId=local.org.apache.spark -DartifactId=spark-assembly_2.10 -Dversion=%{spark_plain_version} -Dpackaging=jar -DlocalRepositoryPath=%{current_workspace}/.m2/repository
  # For Kafka Examples
  mvn -U org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file -Dfile=`pwd`/../external/kafka/target/spark-streaming-kafka_2.10-%{spark_plain_version}.jar -DgroupId=local.org.apache.spark -DartifactId=spark-streaming-kafka_2.10 -Dversion=%{spark_plain_version} -Dpackaging=jar -DlocalRepositoryPath=%{current_workspace}/.m2/repository
  mvn -U org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file -Dfile=`pwd`/../streaming/target/spark-streaming_2.10-%{spark_plain_version}.jar -DgroupId=local.org.apache.spark -DartifactId=spark-streaming_2.10 -Dversion=%{spark_plain_version} -Dpackaging=jar -DlocalRepositoryPath=%{current_workspace}/.m2/repository
fi

# Build our test case with our own pom.xml file
# Update profile ID spark-1.4 for 1.4.1, spark-1.5 for 1.5.2, spark-1.6 for 1.6.0, and hadoop version hadoop24-provided or hadoop27-provided as well
if [[ $SPARK_HADOOP_VERSION == 2.4.* ]] ; then
  mvn -U -X package -Pspark-1.6 -Phadoop24-provided -Pkafka-provided
elif [[ $SPARK_HADOOP_VERSION == 2.6.* ]] ; then
  mvn -U -X package -Pspark-1.6 -Phadoop26-provided -Pkafka-provided
elif [[ $SPARK_HADOOP_VERSION == 2.7.* ]] ; then
  mvn -U -X package -Pspark-1.6 -Phadoop27-provided -Pkafka-provided
else
  echo "fatal - Unrecognize hadoop version $SPARK_HADOOP_VERSION for test case test_spark, can't continue, exiting, no cleanup"
  exit -9
fi

popd
echo "ok - build spark test case completed successfully!"

echo "ok - start repackging assembly JAR with jdk 1.6 due to JIRA AE-1112"
pushd `pwd`
cd %{_builddir}/%{build_service_name}/
%{__mkdir} -p %{_builddir}/%{build_service_name}/tmp/
# AE-1112 pyspark is packaged with JDK 1.7 which will not work. Need to repackage it with 
# JDK 1.6 while not breaking the bytecode, etc. In other word, only the JAR format matters
# and we don't want to compile it with JDK 1.6.
ls -al %{_builddir}/%{build_service_name}/assembly/target/scala-2.10/spark-assembly-%{spark_plain_version}-hadoop%{hadoop_build_version}.jar

cp -p %{_builddir}/%{build_service_name}/assembly/target/scala-2.10/spark-assembly-%{spark_plain_version}-hadoop%{hadoop_build_version}.jar %{_builddir}/%{build_service_name}/tmp/ORG-spark-assembly-%{spark_plain_version}-hadoop%{hadoop_build_version}.jar

ls -al %{_builddir}/%{build_service_name}/tmp/ORG-spark-assembly-%{spark_plain_version}-hadoop%{hadoop_build_version}.jar

pushd %{_builddir}/%{build_service_name}/tmp/
unzip -d tweak_spark ORG-spark-assembly-%{spark_plain_version}-hadoop%{hadoop_build_version}.jar
cd tweak_spark
/usr/lib/jvm/java-1.6.0-openjdk.x86_64/bin/jar cvmf META-INF/MANIFEST.MF %{_builddir}/%{build_service_name}/tmp/REWRAP-spark-assembly-%{spark_plain_version}-hadoop%{hadoop_build_version}.jar .
popd
popd

ls -al %{_builddir}/%{build_service_name}/assembly/target/scala-2.10/spark-assembly-%{spark_plain_version}-hadoop%{hadoop_build_version}.jar
ls -al %{_builddir}/%{build_service_name}/tmp/REWRAP-spark-assembly-%{spark_plain_version}-hadoop%{hadoop_build_version}.jar
cp -fp %{_builddir}/%{build_service_name}/tmp/REWRAP-spark-assembly-%{spark_plain_version}-hadoop%{hadoop_build_version}.jar %{_builddir}/%{build_service_name}/assembly/target/scala-2.10/spark-assembly-%{spark_plain_version}-hadoop%{hadoop_build_version}.jar

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
%{__mkdir} -p %{buildroot}%{install_spark_dest}/external/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/graphx/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/mllib/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/network/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/repl/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/streaming/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/sql/hive-thriftserver/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/tools/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/lib_managed/jars/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/R/lib/
# Added due to AE-1219 to support Hive 1.2.0+ with Hive on Spark
%{__mkdir} -p %{buildroot}%{install_spark_dest}/lib/
# work and logs folder is for runtime, this is a dummy placeholder here to set the right permission within RPMs
# logs folder should coordinate with log4j and be redirected to /var/log for syslog/flume to pick up
%{__mkdir} -p %{buildroot}%{install_spark_logs}
%{__mkdir} -p %{buildroot}%{install_spark_test}
# copy all necessary jars
cp -rp %{_builddir}/%{build_service_name}/assembly/target/scala-2.10/*.jar %{buildroot}%{install_spark_dest}/assembly/target/scala-2.10/
cp -rp %{_builddir}/%{build_service_name}/bagel/target/*.jar %{buildroot}%{install_spark_dest}/bagel/target/
cp -rp %{_builddir}/%{build_service_name}/examples/target/*.jar %{buildroot}%{install_spark_dest}/examples/target/
# required for python and SQL
cp -rp %{_builddir}/%{build_service_name}/examples/src %{buildroot}%{install_spark_dest}/examples/
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
cp -rp %{_builddir}/%{build_service_name}/external/* %{buildroot}%{install_spark_dest}/external/
cp -rp %{_builddir}/%{build_service_name}/network/* %{buildroot}%{install_spark_dest}/network/
cp -rp %{_builddir}/%{build_service_name}/sql/hive-thriftserver/target/* %{buildroot}%{install_spark_dest}/sql/hive-thriftserver/target/
cp -rp %{_builddir}/%{build_service_name}/lib_managed/jars/* %{buildroot}%{install_spark_dest}/lib_managed/jars/
cp -rp %{_builddir}/%{build_service_name}/data/* %{buildroot}%{install_spark_dest}/data/
cp -rp %{_builddir}/%{build_service_name}/R/lib/* %{buildroot}%{install_spark_dest}/R/lib/

# test deploy the config folder
cp -rp %{_builddir}/%{build_service_name}/conf %{buildroot}/%{install_spark_conf}

# Inherit license, readme, etc
cp -p %{_builddir}/%{build_service_name}/README.md %{buildroot}/%{install_spark_dest}
cp -p %{_builddir}/%{build_service_name}/LICENSE %{buildroot}/%{install_spark_dest}
cp -p %{_builddir}/%{build_service_name}/NOTICE %{buildroot}/%{install_spark_dest}
cp -p %{_builddir}/%{build_service_name}/CHANGES.txt %{buildroot}/%{install_spark_dest}
cp -p %{_builddir}/%{build_service_name}/CONTRIBUTING.md %{buildroot}/%{install_spark_dest}

# This will capture the installation property form this spec file for further references
rm -f %{buildroot}/%{install_spark_label}
touch %{buildroot}/%{install_spark_label}
echo "name=%{name}" >> %{buildroot}/%{install_spark_label}
echo "version=%{spark_version}" >> %{buildroot}/%{install_spark_label}
echo "release=%{name}-%{release}" >> %{buildroot}/%{install_spark_label}


# add dummy file to warn user that CLUSTER mode is not for Production
echo "Currently, standalone mode is DISABLED, and it is not suitable for Production environment" >  %{buildroot}%{install_spark_dest}/sbin/CLUSTER_STANDALONE_MODE_NOT_SUPPORTED.why.txt
echo "DO NOT HAND EDIT, DEPLOYED BY RPM and CHEF" >  %{buildroot}%{install_spark_conf}/DO_NOT_HAND_EDIT.txt

# deploy test suite and scripts
cp -rp %{_builddir}/%{build_service_name}/test_spark/target/*.jar %{buildroot}/%{install_spark_test}/
cp -rp %{_builddir}/%{build_service_name}/test_spark/* %{buildroot}/%{install_spark_test}/
# manual cleanup on unnecessary files
rm -rf %{buildroot}/%{install_spark_test}/target
rm -rf %{buildroot}/%{install_spark_test}/project/target

%clean
echo "ok - cleaning up temporary files, deleting %{buildroot}%{install_spark_dest}"
rm -rf %{buildroot}%{install_spark_dest}

%files
%defattr(0755,spark,spark,0755)
%{install_spark_dest}/project
%{install_spark_dest}/assembly
%{install_spark_dest}/bin
%{install_spark_dest}/data
%{install_spark_dest}/dev
%{install_spark_dest}/docs
%{install_spark_dest}/examples
%{install_spark_dest}/external
%{install_spark_dest}/graphx
%{install_spark_dest}/lib
%{install_spark_dest}/lib_managed
%{install_spark_dest}/mllib
%{install_spark_dest}/network/common
%{install_spark_dest}/network/shuffle
%{install_spark_dest}/network/yarn/pom.xml
%{install_spark_dest}/network/yarn/src
%{install_spark_dest}/network/yarn/target/spark-network-yarn_2.10-%{spark_plain_version}-tests.jar
%{install_spark_dest}/network/yarn/target/spark-network-yarn_2.10-%{spark_plain_version}.jar
%{install_spark_dest}/network/yarn/target/spark-network-yarn_2.10-%{spark_plain_version}-test-sources.jar
%{install_spark_dest}/network/yarn/target/spark-network-yarn_2.10-%{spark_plain_version}-javadoc.jar
%{install_spark_dest}/network/yarn/target/spark-network-yarn_2.10-%{spark_plain_version}-sources.jar
%{install_spark_dest}/network/yarn/target/.plxarc
%{install_spark_dest}/network/yarn/target/analysis
%{install_spark_dest}/network/yarn/target/antrun
%{install_spark_dest}/network/yarn/target/generated-sources
%{install_spark_dest}/network/yarn/target/maven-archiver
%{install_spark_dest}/network/yarn/target/maven-shared-archive-resources
%{install_spark_dest}/network/yarn/target/maven-status
%{install_spark_dest}/network/yarn/target/scala-2.10/classes
%{install_spark_dest}/network/yarn/target/scala-2.10/test-classes
%{install_spark_dest}/network/yarn/target/scalastyle-output.xml
%{install_spark_dest}/network/yarn/target/site
%{install_spark_dest}/python
%{install_spark_dest}/R
%{install_spark_dest}/repl
%{install_spark_dest}/sbin
%{install_spark_dest}/sql
%{install_spark_dest}/streaming
%{install_spark_dest}/tools
%docdir %{install_spark_dest}/docs
%doc %{install_spark_label}
%doc %{install_spark_dest}/LICENSE
%doc %{install_spark_dest}/README.md
%doc %{install_spark_dest}/NOTICE
%doc %{install_spark_dest}/CHANGES.txt
%doc %{install_spark_dest}/CONTRIBUTING.md
%attr(0755,spark,spark) %{install_spark_conf}/spark-env.sh
%attr(0644,spark,spark) %{install_spark_conf}/log4j.properties
%attr(0644,spark,spark) %{install_spark_conf}/spark-defaults.conf
%attr(0644,spark,spark) %{install_spark_conf}/java-opts
%attr(0644,spark,spark) %{install_spark_conf}/*.template
%attr(0444,spark,spark) %{install_spark_conf}/DO_NOT_HAND_EDIT.txt
%attr(1777,spark,spark) %{install_spark_logs}
%config(noreplace) %{install_spark_conf}

%files example
%defattr(0755,spark,spark,0755)
%{install_spark_test}

%files yarn-shuffle
%defattr(0644,spark,spark,0644)
%{install_spark_dest}/network/yarn/target/scala-2.10/spark-%{spark_plain_version}-yarn-shuffle.jar

%files devel
%defattr(0644,spark,spark,0644)
%{install_spark_dest}/core/target/spark-core_2.10-%{spark_plain_version}.jar
%{install_spark_dest}/sql/catalyst/target/spark-catalyst_2.10-%{spark_plain_version}.jar
%{install_spark_dest}/sql/core/target/spark-sql_2.10-%{spark_plain_version}.jar
%{install_spark_dest}/sql/hive/target/spark-hive_2.10-%{spark_plain_version}.jar
%{install_spark_dest}/launcher/target/spark-launcher_2.10-%{spark_plain_version}.jar
%{install_spark_dest}/unsafe/target/spark-unsafe_2.10-%{spark_plain_version}.jar
%{install_spark_dest}/yarn/target/spark-yarn_2.10-%{spark_plain_version}.jar

%post
if [ "$1" = "1" ]; then
  echo "ok - performing fresh installation"
elif [ "$1" = "2" ]; then
  echo "ok - upgrading system"
fi
rm -vf /opt/%{apache_name}/logs
rm -vf /opt/%{apache_name}/conf
rm -vf /opt/%{apache_name}/test_spark
rm -vf /opt/%{apache_name}
rm -vf /etc/%{apache_name}
ln -vsf %{install_spark_dest} /opt/%{apache_name}
ln -vsf %{install_spark_conf} /etc/%{apache_name}
ln -vsf %{install_spark_conf} /opt/%{apache_name}/conf
ln -vsf %{install_spark_logs} /opt/%{apache_name}/logs
# mkdir -p /home/spark/logs
# chmod -R 1777 /home/spark/logs
# chown %{spark_uid}:%{spark_gid} /home/spark/
# chown %{spark_uid}:%{spark_gid} /home/spark/logs
# Added due to AE-1219, this should go to Chef for refactor
# The symbolic link is version sensitive
# TODO: Move to Chef later
ln -vsf %{install_spark_dest}/assembly/target/scala-2.10/spark-assembly-%{spark_plain_version}-hadoop%{hadoop_build_version}.jar %{spark_release_dir}/
for f in `find %{install_spark_dest}/lib_managed/jars/ -name "datanucleus-*.jar"`
do
  ln -vsf $f %{spark_release_dir}/
done
ln -vsf %{install_spark_dest}/examples/target/spark-examples_2.10-%{spark_plain_version}.jar %{spark_release_dir}/
ln -vsf %{install_spark_dest}/network/yarn/target/scala-2.10/spark-%{spark_plain_version}-yarn-shuffle.jar %{spark_release_dir}/


%postun
if [ "$1" = "0" ]; then
  ret=$(rpm -qa | grep %{rpm_package_name} | grep -v test | wc -l)
  if [ "x${ret}" != "x0" ] ; then
    echo "ok - detected other spark version, no need to clean up symbolic links"
    echo "ok - cleaning up version specific directories only regarding this uninstallation"
    rm -vrf %{install_spark_dest}
    rm -vrf %{install_spark_conf}
  else
    echo "ok - uninstalling %{rpm_package_name} on system, removing symbolic links"
    rm -vf /opt/%{apache_name}/logs
    rm -vf /opt/%{apache_name}/conf
    rm -vf /opt/%{apache_name}
    rm -vf /etc/%{apache_name}
    rm -vrf %{install_spark_dest}
    rm -vrf %{install_spark_conf}
  fi
fi
# Don't delete the users after uninstallation.

%changelog
* Fri Nov 13 2015 Andrew Lee 20151113
- Update spark version to 1.6 
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


