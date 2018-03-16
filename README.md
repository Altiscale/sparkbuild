sparkbuild
==========

This branch collects the build script to build Spark.
You will only need to update `scripts/setup_env.sh` variable `SPARK_VERSION` default value accordingly.
This will ensure if the user forgot to specify the `SPARK_VERSION`, it will still fall back to the
expected default version for this branch.

Note: branch name for `spark` and `sparkbuild` repositories align. For example,

* Spark 1.6.1 => `spark` branch `branch-1.6-alti` : `sparkbuild` branch `branch-1.6-alti`
* Spark 1.6.2 => `spark` branch `branch-1.6.2-alti` : `sparkbuild` branch `branch-1.6.2-alti`
* Spark 1.6.3 => `spark` branch `branch-1.6.3-alti` : `sparkbuild` branch `branch-1.6.3-alti`
* Spark 2.0.0 => `spark` branch `branch-2.0-alti` : `sparkbuild` branch `branch-2.0-alti`
* Spark 2.0.2 => `spark` branch `branch-2.0.2-alti` : `sparkbuild` branch `branch-2.0.2-alti`
* Spark 2.1.0 => `spark` branch `branch-2.1-alti` : `sparkbuild` branch `branch-2.1-alti`
* Spark 2.1.1 => `spark` branch `branch-2.1.1-alti` : `sparkbuild` branch `branch-2.1.1-alti`
* Spark 2.1.2 => `spark` branch `branch-2.1.2-alti` : `sparkbuild` branch `branch-2.1.2-alti`

and only the first Spark x.y version offering will have the `breanch-x.y-alti` without the patch version.
(Spark 1.6.1 branch `branch-1.6-alti` was the only exception due to legacy, and for Spark2 onward, we will follow this pattern)

How to build Spark locally in your VM
==========

In order to discover ALL the dependencies related to Spark installation and build process,
you must use a **minimal** installed Linux VM to build this. As a result, we use `mock` here.
The new method utilize *alti_dev_images* which is an in-house tool to build Spark in Docker container
where the base image is coming from Prometheus (which contains some pre-installed libraries from SAP).
However, they provide similar minimal environment as long as you are using the minimal installation from 
Docker repository, or if you are confident on how the `Dockerfile` is configured for the base image.
Here, we will provide both, the new and old methdology how we build Apache Spark.

* Using fpm and Docker

This section provides the more modern way to build this **Java** application. Be aware that,
the assumption here assume you are not building some features that requires a different 
runtime environment (e.g. python virtualenv, ruby env, etc.) along with your application.
If that is the case, you should use **omnibus** to package your runtime along with your
application to be installed in a self-contained runnable distros. Other solutions such as providing a
Docker container for this service is also feasible. Please consult with the Infra team to see if
running Docker is supported in your environment.

You can run this on your local laptop, or anywhere that supports Docker.
The following example will be running on a Mac OSX.

1. Check out the **private** repository from SAP.

```
export BUILD_BRANCH=branch-2.1.2-alti
git clone -b master git@github.com:VertiCloud/alti_dev_images.git
git clone -b $BUILD_BRANCH git@github.com:Altiscale/sparkbuild.git
pushd sparkbuild
git submodule init
git submodule update
popd
```

2. Define the following env variables that are used by the `patch.sh` script and build
the package.

```
export PATCH_DIR=dev_images/docker
export PACKAGE_NAME=spark
# You can override this to use your own local/remote base image if you want
export DOCKER_BASE_IMAGE_NAME=docker-dev.artifactory.service.altiscale.com/sparkbase

# Copy the files we want to use for build
mkdir dev_images
cp -rp alti_dev_images/docker dev_images/

# Kick off the build
${PATCH_DIR}/package_build/patch.sh
```

* Using mock and rpmbuild

This ssection focus on `mock` along with CentOS6.5/RHEL6. The example was tested on 
mock version `1.1.32` and `1.3.5`, and we have also tested on CentOS6.7 as well.
Note: If you build this on your laptop, your host environemnt may be compromised, and you 
are required to rebuild it in a clean environment (e.g. in VirtualBox, VMFusion, or Docker, etc.) if you are 
submitting a pull request.

1. Launch and setup your CentOS6.5/6.7/RHEL6 VM. Within your VM, you will need to use a non-privilege user
e.g. `makerpm` in our example. You will also need to install other packages accordingly.

```
# You need EPEL yum repo enabled first
yum install mock git rpm-build
useradd makerpm
usermod -a -G mock makerpm
```

2. Clone the `sparkbuild` and `spark` repository and kick off the build process with user `makerpm`.
The `build_rpm_only.sh` looks at the `spark` directory in its relative path, so `spark` repository  must be
cloned inside the `sparkbuild` directory.

```
su - makerpm
cd $HOME
git clone -b branch-2.1.2-alti https://github.com/Altiscale/sparkbuild.git
pushd sparkbuild
git clone -b branch-2.1.2-alti git@github.com:Altiscale/spark.git
# git clone -b branch-2.1.2-alti https://github.com/Altiscale/spark.git
```

3. Review `$HOME/sparkbuild/scripts/setup_env.sh` for the version default values for various packages 
such as `SPARK_VERSION`, `JAVA_HOME`, `HIVE_VERSION`, etc.

4. Build spark with the `build_rpm_only.sh` script. You will need to specify a few env variables.
`SPARK_BRANCH_NAME` refers to your `spark` repository branch name. If you have a custom branch, you will specify
it here, and you will also need to check them out in previous step 2 into directory `spark`.

```
su - makerpm
cd $HOME/sparkbuild/scripts
INCLUDE_LEGACY_TEST=false SPARK_BRANCH_NAME=branch-2.1.2-alti ./build_rpm_only.sh
```

5. Once the build complets, you will notice directory `$HOME/sparkbuild/rpmbuild` created. The RPMs will appear in
`$HOME/sparkbuild/rpmbuild/RPMS/x86_64/`. If the RPM files are not available, that means you have errors in the build
process. Please review the `spark.spec` and the env variables specified in `setup_env.sh` file.


How to Install Spark RPM for this build
==========
```
# Install on Hadoop 2.7.1 for Spark version x.y.z (e.g. x.y.z could be 1.6.1/1.6.2/2.0.2/2.1.1/2.1.2/etc.)
yum install alti-spark-x.y.z-* alti-spark-x.y.z-example

# Install on Hadoop 2.4.1 is no longer supported, and it is obsolete
```

Deployment now relies on Chef-solo (partially while we migrate away) and Chef server. 
See the alti_spark_app-cookbook and alti_spark_role-cookbook for more information.

Run Test Case
==========
Copy the folder test_spark to the remote workbench. We will use /tmp/ here for example.
Run the command as the user you want to test. In Altiscale, alti-test-01 is usually
the user we use to test most test case. We will apply the same user here. You can also
run the test case within $SPARK_HOME/test_spark/ directly since all files are copied to 
HDFS first, test case doesn't write to the current local direectory.

Login to remote workbench. (Default is Spark 1.6.1 as of 2016/2017)
```
ssh workbench_hostname
```

In your shell, you can run
```
cp -rp /opt/spark/test_spark /tmp/
cd /tmp/test_spark/
# For non-Kerberos cluster
./run_all_test.nokerberos.sh
# For kerberos enabled cluster
./run_all_test.kerberos.sh
```

To run a different version of Spark, you will need to specify the `SPARK_HOME` and `SPARK_CONF_DIR`
accordingly for that specific Spark version. For example, to run Spark 2.1.2
Login to remote workbench. (Default is still Spark 1.6.1 as of 2016/2017)
```
ssh workbench_hostname
```
Specify the spark version and preset the `SPARK_HOME` and `SPARK_CONF_DIR` env variables.
```
SPARK_HOME=/opt/alti-spark-2.1.2
SPARK_CONF_DIR=/etc/alti-spark-2.1.2
cp -rp /opt/alti-spark-2.1.2/test_spark /tmp/test_spark-2.1.2
cd /tmp/test_spark-2.1.2/
# For non-Kerberos cluster
./run_all_test.nokerberos.sh
# For kerberos enabled cluster
./run_all_test.kerberos.sh
```

If you prefer (discouraged) to run it as root and delegate to alti-test-01 user, the following
command is sufficient.
```
/bin/su - alti-test-01 -c "/tmp/test_spark/test_spark_submit.sh"
```

The test should exit with 0 if everything completes correctly.

