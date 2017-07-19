sparkbuild
==========

This branch collects the build script to build Spark.
You will only need to update `scripts/setup_env.sh` variable `SPARK_VERSION` default value accordingly.
This will ensure if the user forgot to specify the `SPARK_VERSION`, it will still fall back to the
expected default version for this branch.

How to build Spark locally in your VM
==========

In order to discover ALL the dependencies related to Spark installation and build process,
you must use a minimal installed Linux VM to build this. As a result, we use `mock` here.
You may notice Docker container to build Apache projects as well, however, they provide similar minimal
environment as long as you are using the minimal installation from Docker repository, or if you are confident
on how the `Dockerfile` is configured. 
Here, we will focus on `mock` along with CentOS6.5/RHEL6. The example was tested on mock version `1.1.32` and `1.3.5`.
Note: If you build this on your laptop, your host environemnt may be compromised, and you are required to
rebuild it in a clean environment if you are submitting a pull request.

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
git clone -b branch-2.1.1-alti https://github.com/Altiscale/sparkbuild.git
pushd sparkbuild
git clone -b branch-2.1.1-alti git@github.com:Altiscale/spark.git
# git clone -b branch-2.1.1-alti https://github.com/Altiscale/spark.git
```

3. Review `$HOME/sparkbuild/scripts/setup_env.sh` for the version default values for various packages 
such as `SPARK_VERSION`, `JAVA_HOME`, `HIVE_VERSION`, etc.

4. Build spark with the `build_rpm_only.sh` script. You will need to specify a few env variables.
`SPARK_BRANCH_NAME` refers to your `spark` repository branch name. If you have a custom branch, you will specify
it here, and you will also need to check them out in previous step 2 into directory `spark`.

```
su - makerpm
cd $HOME/sparkbuild/scripts
INCLUDE_LEGACY_TEST=false SPARK_BRANCH_NAME=branch-2.1.1-alti ./build_rpm_only.sh
```

5. Once the build complets, you will notice directory `$HOME/sparkbuild/rpmbuild` created. The RPMs will appear in
`$HOME/sparkbuild/rpmbuild/RPMS/x86_64/`. If the RPM files are not available, that means you have errors in the build
process. Please review the `spark.spec` and the env variables specified in `setup_env.sh` file.


How to Install Spark RPM for this build
==========
```
# Install on Hadoop 2.7.1 for Spark version x.y.z (e.g. x.y.z could be 1.6.1/1.6.2/2.0.2/2.1.1/etc.)
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
accordingly for that specific Spark version. For example, to run Spark 2.1.1
Login to remote workbench. (Default is still Spark 1.6.1 as of 2016/2017)
```
ssh workbench_hostname
```
Specify the spark version and preset the `SPARK_HOME` and `SPARK_CONF_DIR` env variables.
```
SPARK_HOME=/opt/alti-spark-2.1.1
SPARK_CONF_DIR=/etc/alti-spark-2.1.1
cp -rp /opt/alti-spark-2.1.1/test_spark /tmp/test_spark-2.1.1
cd /tmp/test_spark-2.1.1/
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

