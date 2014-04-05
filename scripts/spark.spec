%define major_ver %(echo ${SPARK_VERSION})
%define service_name alti-spark
%define company_prefix altiscale
%define pkg_name %{service_name}-%{major_ver}
%define install_spark_dest /opt/%{pkg_name}
%define packager %(echo ${PKGER})
%define spark_user %(echo ${SPARK_USER})
%define spark_gid %(echo ${SPARK_GID})
%define spark_uid %(echo ${SPARK_UID})

Name: %{service_name}
Summary: %{pkg_name} RPM Installer
Version: %{major_ver}
Release: 6%{?dist}
License: Copyright (C) 2014 Altiscale. All rights reserved.
# Packager: %{packager}
Source: %{_sourcedir}/%{service_name}
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%{service_name}
# Requires: scala-2.10.3 >= 2.10.3
# Apply all patches to fix CLASSPATH and java lib issues
Patch1: %{_sourcedir}/patch.spark

Url: http://www.altiscale.com/

%description
%{pkg_name} is a repackaged spark distro that is compiled against Hadoop 2.2.x
with YARN enabled. This package should work with Altiscale Hadoop.

%prep
# copying files into BUILD/spark/ e.g. BUILD/spark/* 
echo "ok - copying files from %{_sourcedir} to folder  %{_builddir}/%{service_name}"
cp -r %{_sourcedir}/%{service_name} %{_builddir}/

%patch1 -p0

%build
echo "ANT_HOME=$ANT_HOME"
echo "JAVA_HOME=$JAVA_HOME"
echo "MAVEN_HOME=$MAVEN_HOME"
echo "MAVEN_OPTS=$MAVEN_OPTS"
echo "M2_HOME=$M2_HOME"
echo "SCALA_HOME=$SCALA_HOME"

echo "build - spark core in %{_builddir}"
pushd `pwd`
cd %{_builddir}/%{service_name}/
export SPARK_HADOOP_VERSION=2.2.0 
export SPARK_YARN=true
echo "build - assebly"
# SPARK_HADOOP_VERSION=2.2.0 SPARK_YARN=true sbt/sbt assembly

########################
# BUILD ENTIRE PACKAGE #
########################
# This will build the overall JARs we need in each folder
# and install them locally for further reference. We assume the build
# environment is clean, so we don't need to delete ~/.ivy2 and ~/.m2
mvn -X -Pyarn -Dhadoop.version=$SPARK_HADOOP_VERSION -Dyarn.version=$SPARK_HADOOP_VERSION -DskipTests install
# mvn -Pyarn -Dmaven.repo.remote=http://repo.maven.apache.org/maven2,http://repository.jboss.org/nexus/content/repositories/releases -Dhadoop.version=$SPARK_HADOOP_VERSION -Dyarn.version=$SPARK_HADOOP_VERSION -DskipTests install

#if [ "x${SPARK_YARN}" = "xtrue" ] ; then
#  ./make-distribution.sh --hadoop $SPARK_HADOOP_VERSION --with-yarn
#else
#  ./make-distribution.sh --hadoop $SPARK_HADOOP_VERSION
#fi

######################################
# BUILD INDIVIDUAL JARS if necessary #
######################################
#echo "build - mllib"
#cd mllib
#mvn -Pyarn -Dhadoop.version=$SPARK_HADOOP_VERSION -Dyarn.version=$SPARK_HADOOP_VERSION -DskipTests clean package
#cd ..

#echo "build - graphX"
#cd graphx
#mvn -Pyarn -Dhadoop.version=$SPARK_HADOOP_VERSION -Dyarn.version=$SPARK_HADOOP_VERSION -DskipTests clean package
#cd ..

popd
echo "Build Completed successfully!"

%install
# manual cleanup for compatibility, and to be safe if the %clean isn't implemented
rm -rf %{buildroot}%{install_spark_dest}
# re-create installed dest folders
mkdir -p %{buildroot}%{install_spark_dest}
echo "compiled/built folder is (not the same as buildroot) RPM_BUILD_DIR = %{_builddir}"
echo "test installtion folder (aka buildroot) is RPM_BUILD_ROOT = %{buildroot}"
echo "test install spark dest = %{buildroot}/%{install_spark_dest}"
echo "test install spark label pkg_name = %{pkg_name}"
%{__mkdir} -p %{buildroot}%{install_spark_dest}/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/assembly/target/scala-2.10/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/examples/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/tools/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/mllib/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/graphx/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/streaming/target/
# work and logs folder is for runtime, this is a dummy placeholder here to set the right permission within RPMs
# logs folder should coordinate with log4j and be redirected to /var/log for syslog/flume to pick up
%{__mkdir} -p %{buildroot}%{install_spark_dest}/work
%{__mkdir} -p %{buildroot}%{install_spark_dest}/logs
# copy all necessary jars
cp -rp %{_builddir}/%{service_name}/assembly/target/scala-2.10/*.jar %{buildroot}%{install_spark_dest}/assembly/target/scala-2.10/
cp -rp %{_builddir}/%{service_name}/examples/target/*.jar %{buildroot}%{install_spark_dest}/examples/target/
cp -rp %{_builddir}/%{service_name}/tools/target/*.jar %{buildroot}%{install_spark_dest}/tools/target/
cp -rp %{_builddir}/%{service_name}/mllib/data %{buildroot}%{install_spark_dest}/mllib/
cp -rp %{_builddir}/%{service_name}/mllib/target/*.jar %{buildroot}%{install_spark_dest}/mllib/target/
cp -rp %{_builddir}/%{service_name}/graphx/data %{buildroot}%{install_spark_dest}/graphx/
cp -rp %{_builddir}/%{service_name}/graphx/target/*.jar %{buildroot}%{install_spark_dest}/graphx/target/
cp -rp %{_builddir}/%{service_name}/streaming/target/*.jar %{buildroot}%{install_spark_dest}/streaming/target/
cp -rp %{_builddir}/%{service_name}/conf %{buildroot}%{install_spark_dest}/
cp -rp %{_builddir}/%{service_name}/bin %{buildroot}%{install_spark_dest}/
cp -rp %{_builddir}/%{service_name}/sbin %{buildroot}%{install_spark_dest}/
cp -rp %{_builddir}/%{service_name}/python %{buildroot}%{install_spark_dest}/

# haven't heard any negative feedback by embedding user creation in RPM spec
# during test installation
# if [ "x%{spark_user}" = "x" ] ; then
#  echo "ok - applying default spark user 'spark'"
#  echo "to override default user, UID, and GID, set env for SPARK_USER, SPARK_GID, SPARK_UID"
#  echo "ok - creating 56789:56789 spark"
#  getent group spark >/dev/null || groupadd  -g 56789 spark
#  getent passwd spark >/dev/null || useradd -g 56789 -c "creating spark account to run spark later" spark
#  echo "ok - create a password for the new created user spark"
#  echo "spark:spark" | chpasswd
#elif [ "x%{spark_uid}" = "x" -o "x%{spark_gid}" = "x" ] ; then
#  echo "fatal - spark user specified, but missing uid or gid definition. Specify them all in SPARK_USER, SPARK_UID, SPARK_GID"
#  exit -5
#else
#  echo "ok - creating %{spark_uid}:%{spark_gid} %{spark_user}"
#  getent group %{spark_user} >/dev/null || groupadd  -g %{spark_gid} %{spark_user}
#  getent passwd %{spark_user} >/dev/null || useradd -g %{spark_gid} -c "creating spark account to run spark later" %{spark_user}
  # Create a password, this should be disabled if you are automating this script
  # The build env should have these users created for you already
#  echo "ok - create a password for the new created user %{spark_user}"
#  echo "%{spark_user}:%{spark_user}" | chpasswd
#fi

%clean
echo "ok - cleaning up temporary files, deleting %{buildroot}%{install_spark_dest}"
rm -rf %{buildroot}%{install_spark_dest}

%files
%defattr(0755,root,root,0755)
%{install_spark_dest}

%changelog
* Fri Apr 4 2014 Andrew Lee 20140404
- Change UID to 411460024, and rename it back to alti-spark, add missing JARs for mllib and graphx
* Wed Apr 2 2014 Andrew Lee 20140402
- Rename Spark pkg name to vcc-spark so we can identify our own build
* Wed Mar 19 2014 Andrew Lee 20140319
- Initial Creation of spec file for Spark 0.9.1


