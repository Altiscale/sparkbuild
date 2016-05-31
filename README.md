sparkbuild
==========

Init sparkbuild wrapper repo for one of the spark branch (e.g. branch-1.6-alti) for official release.
You will need to select the build script branch (sparkbuild) and spark branch (spark) to build it.
Specify them in the jenkin job as part of the parameters.

How to Install Spark RPM (e.g. spark 1.6.1)
==========
```
# Install on Hadoop 2.7.1
yum install alti-spark-1.6.1 alti-spark-1.6.1-example alti-spark-1.6.1-yarn-shuffle

# Install on Hadoop 2.4.1
yum install alti-spark-1.4.2.hadoop24.hive13 alti-spark-1.4.2.hadoop24.hive13-example
```

Deployment now relies on Chef server. See the alti_spark_app-cookbook and alti_spark_role-cookbook
for more information.

Be aware that in Spark 1.6.1, Hadoop and Hive JARs are no longer embed in the assembly JAR.
Read https://documentation.altiscale.com/spark-sql-how-to$sparksqlquickstart for more information
on how to include Hive JARs for SparkSQL if you need to run SparkSQL.

Apply different version of Maven
==========

Since building Spark requires different version of Maven from time to time, to apply a different
version of Maven, make sure
- apache-maven RPM are populated and deployed to yum repo that you are testing.
- update altiscale-spark-centos-6-x86_64.cfg `chroot_setup_cmd` option to install the correct version
of apache-maven in mock environment.
- Make sure `setup_env.sh` env variables `M2_HOME`, `MAVEN_HOME`, `MAVEN_OPTS` are updated to point to
the correct location and specifying with the proper values.


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
cp -rp /opt/spark/test_spark /tmp/
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

Applying Different Version of Spark
==========

To apply a different version of Spark, please read: https://documentation.altiscale.com/spark-upgrade-tips$upgradespark
Basically, the idea is to override `SPARK_HOME` and `SPARK_CONF_DIR` to point to the version you want.

