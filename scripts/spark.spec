%define major_ver %(echo ${SPARK_VERSION})
%define service_name spark
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
Release: 1%{?dist}
License: Copyright (C) 2014 Altiscale. All rights reserved.
# Packager: %{packager}
Source: %{_sourcedir}/%{service_name}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%{service_name}
# Requires: scala-2.10.3 >= 2.10.3

Url: http://www.altiscale.com/

%description
%{pkg_name} is a repackaged spark distro that is compiled against Hadoop 2.2.x
with YARN enabled. This package should work with Altiscale Hadoop.

%prep
# copying files into BUILD/spark/ e.g. BUILD/spark/* 
echo "ok - copying files from %{_sourcedir} to folder  %{_builddir}/%{service_name}"

%setup -q -n %{service_name}

%build
echo "ANT_HOME=$ANT_HOME"
echo "JAVA_HOME=$JAVA_HOME"
echo "MAVEN_HOME=$MAVEN_HOME"
echo "MAVEN_OPTS=$MAVEN_OPTS"
echo "M2_HOME=$M2_HOME"
echo "SCALA_HOME=$SCALA_HOME"

echo "build - spark core in %{_builddir}"
export SPARK_HADOOP_VERSION=2.2.0 
export SPARK_YARN=true
SPARK_HADOOP_VERSION=2.2.0 SPARK_YARN=true sbt/sbt assembly

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
%{__mkdir} -p %{buildroot}%{install_spark_dest}/lib
%{__mkdir} -p %{buildroot}%{install_spark_dest}/work
cp -rp %{_builddir}/%{service_name}/assembly/target/scala-2.10/*.jar %{buildroot}%{install_spark_dest}/lib/
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
* Wed Mar 19 2014 Andrew Lee 20140319
- Initial Creation of spec file for Spark 0.9.0


