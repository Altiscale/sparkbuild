%global apache_name           spark
%global spark_uid             411460024
%global spark_gid             411460017

%define altiscale_release_ver ALTISCALE_RELEASE
%define rpm_package_name      alti-spark
%define spark_version         SPARK_VERSION
%define build_service_name    alti-spark
%define spark_folder_name     %{rpm_package_name}-%{spark_version}
%define install_spark_dest    /opt/%{spark_folder_name}
%define install_spark_conf    /etc/%{spark_folder_name}
%define install_spark_logs    /var/log/%{apache_name}
%define build_release         BUILD_TIME

Name: %{rpm_package_name}
Summary: %{spark_folder_name} RPM Installer AE-576, cluster mode restricted with warnings
Version: %{spark_version}
Release: %{altiscale_release_ver}.%{build_release}%{?dist}
License: ASL 2.0
# Packager: %{packager}
Source: %{_sourcedir}/%{build_service_name}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%{build_service_name}
Requires(pre): shadow-utils
Requires: scala >= 2.10.3
Requires: jre >= 1.7
BuildRequires: scala = 2.10.3
BuildRequires: apache-maven >= 3.2.1
BuildRequires: java-1.7.0-openjdk-devel >= 1.7.0.51
# Apply all patches to fix CLASSPATH and java lib issues
# Patch1: %{_sourcedir}/patch.spark

Url: http://spark.apache.org/

%description
%{spark_folder_name} is a repackaged spark distro that is compiled against Hadoop 2.2.x
with YARN enabled. This package should work with Altiscale Hadoop 2.2.

%pre
# Soft creation for spark user if it doesn't exist. This behavior is idempotence to Chef deployment.
# Should be harmless. MAKE SURE UID and GID is correct FIRST!!!!!!
getent group %{apache_name} >/dev/null || groupadd -f -g %{spark_gid} -r %{apache_name}
if ! getent passwd %{apache_name} >/dev/null ; then
    if ! getent passwd %{spark_uid} >/dev/null ; then
      useradd -r -u %{spark_uid} -g %{apache_name} -c "Soft creation of user and group of spark for manual deployment" %{apache_name}
    else
      useradd -r -g %{apache_name} -c "Soft adding user spark to group spark for manual deployment" %{apache_name}
    fi
fi

%prep
# copying files into BUILD/spark/ e.g. BUILD/spark/* 
# echo "ok - copying files from %{_sourcedir} to folder  %{_builddir}/%{build_service_name}"
# cp -r %{_sourcedir}/%{build_service_name} %{_builddir}/

# %patch1 -p0

%setup -q -n %{build_service_name}

%build
echo "ANT_HOME=$ANT_HOME"
echo "JAVA_HOME=$JAVA_HOME"
echo "MAVEN_HOME=$MAVEN_HOME"
echo "MAVEN_OPTS=$MAVEN_OPTS"
echo "M2_HOME=$M2_HOME"
echo "SCALA_HOME=$SCALA_HOME"
if [ "x${SCALA_HOME}" = "x" ] ; then
  echo "ok - SCALA_HOME not defined, trying to set SCALA_HOME to default location /opt/scala/"
  export SCALA_HOME=/opt/scala/
fi

export MAVEN_OPTS="-Xmx2048m -XX:MaxPermSize=1024m"

echo "build - spark core in %{_builddir}"
pushd `pwd`
cd %{_builddir}/%{build_service_name}/

# clean up for *NIX environment only, deleting window's cmd
find %{_builddir}/%{build_service_name}/bin -type f -name '*.cmd' -exec rm -f {} \;

# Remove launch script AE-579
find %{_builddir}/%{build_service_name}/sbin -type f -name 'start-*.sh' -exec rm -f {} \;
find %{_builddir}/%{build_service_name}/sbin -type f -name 'stop-*.sh' -exec rm -f {} \;
rm -f %{_builddir}/%{build_service_name}/sbin/slaves.sh

export SPARK_HADOOP_VERSION=2.2.0 
export SPARK_YARN=true
echo "build - assembly"
# SPARK_HADOOP_VERSION=2.2.0 SPARK_YARN=true sbt/sbt assembly

# PURGE LOCAL CACHE for clean build
# mvn dependency:purge-local-repository

########################
# BUILD ENTIRE PACKAGE #
########################
# This will build the overall JARs we need in each folder
# and install them locally for further reference. We assume the build
# environment is clean, so we don't need to delete ~/.ivy2 and ~/.m2
if [ -f /etc/alti-maven-settings/settings.xml ] ; then
  echo "ok - applying local maven repo settings.xml for first priority"
  mvn -U -X -Phadoop-2.2 -Pyarn --settings /etc/alti-maven-settings/settings.xml --global-settings /etc/alti-maven-settings/settings.xml -Dhadoop.version=$SPARK_HADOOP_VERSION -Dyarn.version=$SPARK_HADOOP_VERSION -DskipTests install
else
  echo "ok - applying default repository form pom.xml"
  mvn -U -X -Phadoop-2.2 -Pyarn -Dhadoop.version=$SPARK_HADOOP_VERSION -Dyarn.version=$SPARK_HADOOP_VERSION -DskipTests install
fi
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
echo "test install spark label spark_folder_name = %{spark_folder_name}"
%{__mkdir} -p %{buildroot}%{install_spark_dest}/
%{__mkdir} -p %{buildroot}/etc/%{install_spark_dest}/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/assembly/target/scala-2.10/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/examples/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/tools/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/mllib/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/graphx/target/
%{__mkdir} -p %{buildroot}%{install_spark_dest}/streaming/target/
# work and logs folder is for runtime, this is a dummy placeholder here to set the right permission within RPMs
# logs folder should coordinate with log4j and be redirected to /var/log for syslog/flume to pick up
%{__mkdir} -p %{buildroot}%{install_spark_dest}/work
%{__mkdir} -p %{buildroot}%{install_spark_logs}
# copy all necessary jars
cp -rp %{_builddir}/%{build_service_name}/assembly/target/scala-2.10/*.jar %{buildroot}%{install_spark_dest}/assembly/target/scala-2.10/
cp -rp %{_builddir}/%{build_service_name}/examples/target/*.jar %{buildroot}%{install_spark_dest}/examples/target/
cp -rp %{_builddir}/%{build_service_name}/tools/target/*.jar %{buildroot}%{install_spark_dest}/tools/target/
cp -rp %{_builddir}/%{build_service_name}/mllib/data %{buildroot}%{install_spark_dest}/mllib/
cp -rp %{_builddir}/%{build_service_name}/mllib/target/*.jar %{buildroot}%{install_spark_dest}/mllib/target/
cp -rp %{_builddir}/%{build_service_name}/graphx/data %{buildroot}%{install_spark_dest}/graphx/
cp -rp %{_builddir}/%{build_service_name}/graphx/target/*.jar %{buildroot}%{install_spark_dest}/graphx/target/
cp -rp %{_builddir}/%{build_service_name}/streaming/target/*.jar %{buildroot}%{install_spark_dest}/streaming/target/
cp -rp %{_builddir}/%{build_service_name}/bin %{buildroot}%{install_spark_dest}/
cp -rp %{_builddir}/%{build_service_name}/sbin %{buildroot}%{install_spark_dest}/
cp -rp %{_builddir}/%{build_service_name}/python %{buildroot}%{install_spark_dest}/

# test deploy the config folder
cp -rp %{_builddir}/%{build_service_name}/conf %{buildroot}/%{install_spark_conf}

# add dummy file to warn user that CLUSTER mode is not for Production
echo "Currently, cluster mode NOT supported, and it is not suitable for Production environment" >  %{buildroot}%{install_spark_dest}/sbin/CLUSTER_MODE_NOT_SUPPORTED.why.txt

%clean
echo "ok - cleaning up temporary files, deleting %{buildroot}%{install_spark_dest}"
rm -rf %{buildroot}%{install_spark_dest}

%files
%defattr(0755,spark,spark,0755)
%{install_spark_dest}
%dir %{install_spark_dest}/work
%dir %{install_spark_conf}
%attr(0777,spark,spark) %{install_spark_dest}/work
%attr(0755,spark,spark) %{install_spark_conf}
%attr(0755,spark,spark) %{install_spark_logs}
%config(noreplace) %{install_spark_conf}

%post
ln -sf %{install_spark_dest} /opt/%{apache_name}
ln -sf %{install_spark_conf} /etc/%{apache_name}
ln -sf %{install_spark_logs} /opt/%{apache_name}/logs

%postun
rm -f /opt/%{apache_name}/logs
rm -f /opt/%{apache_name}
rm -f /etc/%{apache_name}

%changelog
* Tue May 20 2014 Andrew Lee 20140520
- Update log folder macro, added %post section, fix build command for hadoop 2.2
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


