#!/bin/bash

curr_dir=`dirname $0`
local_dir=`cd $curr_dir; pwd`

MOCK_GID=3456
MOCK_UID=34567
MOCK_USER=makerpm
spark_spec="$local_dir/spark.spec"

if [ -f "$local_dir/setup_env.sh" ]; then
  source "$local_dir/setup_env.sh"
fi

if [ "$UID" -ne 0 ]
  then echo "fail - please run as root"
  exit -1
fi

# Install EPEL6 to bring in addt'l RPMs
wget http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
yum -y localinstall epel-release-6-8.noarch.rpm

# Install all dependent package for Mock later on for this Host
# The repo should go to internal to keep the version, otherwise, things break over time
# TBD: on production, a lot of these should be removed (security concern due to patching complexity)
yum -y install fedora-packager rpmdevtools s3cmd
yum -y groupinstall "Development Tools"
yum -y install zlib zlib-devel openssl-devel libyaml-devel curl

# These should be packaged along with the VM since these repo URL may break anytime
# No master redirect on these repo URLs.
wget --output-document=apache-maven.zip http://www.eng.lsu.edu/mirrors/apache/maven/maven-3/3.2.1/binaries/apache-maven-3.2.1-bin.zip
wget --output-document=apache-ant.zip http://mirror.reverse.net/pub/apache//ant/binaries/apache-ant-1.9.3-bin.zip
unzip apache-maven.zip > /dev/null
unzip apache-ant.zip > /dev/null

# Normalize dir and file path
mv apache-ant-* apache-ant
mv apache-maven-* apache-maven

# apache_ant_dir=$(basename $apache_ant_dir_tmp)
# apache_mvn_dir=$(basename $apache_mvn_dir_tmp)

mv ./apache-ant /opt/apache-ant
mv ./apache-maven /opt/apache-maven

# Mock requires all users be part of the 'mock' group.
# The 'makerpm' is just a username, change it to anything that make sense as long as
# it is in the 'mock' group
getent group ${MOCK_USER} >/dev/null || groupadd  -g ${MOCK_GID} ${MOCK_USER}
getent passwd ${MOCK_USER} >/dev/null || useradd -g ${MOCK_GID} -c "creating mock account to run mock later" ${MOCK_USER}

# Create a password, this should be disabled if you are automating this script
# The build env should have these users created for you already
echo "ok - create a default password for the new created user ${MOCK_USER}"
echo "${MOCK_USER}:${MOCK_USER}" | chpasswd

# Login as 'makerpm' and initialized the environment
# su - ${MOCK_USER} -c cd ~; /usr/bin/rpmdev-setuptree

#if [ ! -d "/home/${MOCK_USER}/rpmbuild" ] ; then
#  echo "${MOCK_USER} rpmdev-setuptree failed to create the RPM folders, can't continue, please chk."
#  echo "Environment is not clean up, you can simply run rpmdev-setuptree manually to conitue from here. Exiting."
#  exit -2
#fi

# Setup Ruby 1.9.3

ruby_installed=`ruby -v | grep -o ruby`
rubygem_installed=`gem -v`
if [ "x${ruby_installed}" = "xruby" -o "x${rubygem_installed}" != "x" ] ; then
  echo "ok - ruby and gem installed, good"
else
  echo "warn - trying to install Ruby, this shouldn't happen"
  pushd `pwd`
  cd /tmp/
  yum -y remove ruby
  yum -y groupinstall "Development Tools"
  yum -y install zlib zlib-devel openssl-devel libyaml-devel curl

  # Use RVM
  curl -L https://get.rvm.io | bash -s stable
  mkdir -p ~/.rvm/
  cp -r /usr/local/rvm/scripts  ~/.rvm/
  source ~/.rvm/scripts/rvm
  /usr/local/rvm/bin/rvm get head
  /usr/local/rvm/bin/rvm autolibs enable
  /usr/local/rvm/bin/rvm install ruby-1.9.3
  # Update PATH again to locate ruby exe
  source ~/.rvm/scripts/rvm
  /usr/local/rvm/bin/rvm alias create default ruby-1.9.3
  /usr/local/rvm/bin/rvm use default
  # Add Altiscale Gem
  gem update --system
  gem install bundler
  gem sources -a https://gems.service.verticloud.com/
  ruby -v
  gem -v
  popd

  # Hardcode compilation
  # wget --output-document=ruby.tar.gz http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p194.tar.gz
  # tar xvzf ruby.tar.gz
  # mv ruby-* ruby
  # pushd `pwd`
  # cd ruby
  # ./configure  --prefix=/usr/lib64 --enable-shared --disable-install-doc --with-opt-dir=/usr/local/lib64
  # make
  # make install
fi

# setup RPM environment, it's a bad idea to run by root here.
# TBD: try to run by a diff user e.g. makerpm
cd ~
/usr/bin/rpmdev-setuptree
 
if [ ! -e "$spark_spec" ] ; then
  echo "fail - missing $spark_spec file, can't continue, exiting"
  exit -9
fi

exit 0

