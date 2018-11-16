sparkbuild
==========

The sparkbuild wrapper repo for Spark-2.3.2 official release.
This build script here is independent to the build environment used by SAP.

How to Install Spark RPM for this build
==========
```
# Install on Hadoop 2.7.x
yum install alti-spark-2.3.2 alti-spark-2.3.2-example alti-spark-2.3.2-yarn-shuffle
```

For development purposes, you can install the devel package.
```
yum install alti-spark-2.3.2-devel
```

and to use Amazon Kinesis, you can install the kinesis artifacts.
```
# TODO: This has not yet been implemented
yum install alti-spark-2.3.2-kinesis
```

Deployment now relies on Chef server. See the `alti_spark_app-cookbook` and `alti_spark_role-cookbook`
for more information.

Run Test Case
==========
Copy the folder test_spark to the remote workbench. We will use /tmp/ here for example.
Run the command as the user you want to test. In Altiscale, alti-test-01 is usually
the user we use to test most test case. We will apply the same user here. You can also
run the test case within $SPARK_HOME/test_spark/ directly since all files are copied to 
HDFS first, test case doesn't write to the current local direectory.

Login to remote workbench.
```
ssh workbench_hostname
# define SPARK_VERSION as necessary or source it from /etc/alti-spark-x.y.z/spark-env.sh
spark_version=2.3.2
source /etc/alti-spark-${spark_version}/spark-env.sh
cp -rp /opt/alti-spark-${spark_version}/test_spark /tmp/
cd /tmp/test_spark/
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


