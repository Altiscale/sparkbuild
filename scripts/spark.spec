%define major_ver 0.9.0
%define service_name spark
%define company_prefix altiscale
%define pkg_name %{service_name}-%{major_ver}
%define spark /opt/%{pkg_name}

Name: %{service_name}
Summary: %{pkg_name} RPM Installer
Version: %{major_ver}
Release: 20140320%{dist}
License: Copyright (C) 2014 Altiscale. All rights reserved.
Packager: Altiscale alee@altiscale.com
Group: Applications
Source: %{service_name}.tar.gz
BuildRoot: %{_tmppath}/build-root-%{service_name}
Requires: scala-2.10.3 >= 2.10.3

Prefix: /spark
Url: http://www.altiscale.com/

%description
%{pkg_name} is a repackaged spark distro that is compiled against Hadoop 2.2.x
with YARN enabled. This package should work with Altiscale Hadoop.

%prep
echo "ok - building %{pkg_name}, installing scala first"
wget --output-document=scala.tgz  "http://www.scala-lang.org/files/archive/scala-2.10.3.tgz"
tar xvf scala.tgz
if [ -d /opt/scala ] ; then
  echo "deleting prev installed scala"
  rm -rf /opt/scala
fi
mv scala-* /opt/scala

%setup -q -n %{service_name}

%build
echo $JAVA_HOME
echo $MAVEN_HOME
echo $ANT_HOME
echo $M2_HOME
echo $MAVEN_HOME
echo $MAVEN_OPTS
echo $SCALA_HOME

echo "build - spark core"
export SPARK_HADOOP_VERSION=2.2.0 
export SPARK_YARN=true
SPARK_HADOOP_VERSION=2.2.0 SPARK_YARN=true sbt/sbt assembly

echo "Build Completed successfully!"

%install
echo "RPM_BUILD_DIR = $RPM_BUILD_DIR"
echo "RPM_BUILD_ROOT = $RPM_BUILD_ROOT"
echo "spark = %{spark}"
echo "pkg_name = %{pkg_name}"
%{__mkdir} -p $RPM_BUILD_ROOT%{spark}/
%{__mkdir} -p $RPM_BUILD_ROOT%{spark}/lib
cp -rp $RPM_BUILD_DIR/%{service_name}/assembly/target/scala-2.10/*.jar $RPM_BUILD_ROOT%{spark}/lib/
# cp -rp $RPM_BUILD_DIR/%{service_name}/bin $RPM_BUILD_ROOT%{spark}/
# cp -rp $RPM_BUILD_DIR/%{service_name}/sbin $RPM_BUILD_ROOT%{spark}/
cp -rp $RPM_BUILD_DIR/%{service_name}/conf $RPM_BUILD_ROOT%{spark}/
# cp -rp $RPM_BUILD_DIR/%{service_name}/python $RPM_BUILD_ROOT%{spark}/

echo "ok - creating user:group spark:spark"
SPARK_GID=56789
SPARK_UID=56789
SPARK_USER=spark

getent group ${SPARK_USER} >/dev/null || groupadd  -g ${SPARK_GID} ${SPARK_USER}
getent passwd ${SPARK_USER} >/dev/null || useradd -g ${SPARK_GID} -c "creating spark account to run spark later" ${SPARK_USER}

# Create a password, this should be disabled if you are automating this script
# The build env should have these users created for you already
echo "Create a password for the new created user ${SPARK_USER}"
echo "${SPARK_USER}:${SPARK_USER}" | chpasswd

%clean
echo "ok - cleaning up temporary files, deleting $RPM_BUILD_ROOT%{spark}"
if [ -d "$RPM_BUILD_ROOT%{spark}" ] ; then
  rm -rf "$RPM_BUILD_ROOT%{spark}"
fi

%files
%defattr(0755,root,root,0755)
%{spark}

%changelog
* Wed Mar 19 2014 Andrew Lee 20140319
- Initial Creation of spec file for Spark 0.9.0


