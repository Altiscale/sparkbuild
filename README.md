# DO NOT USE THIS BRANCH, WE HAVE SWITCH TO `branch-1.6-alti`

sparkbuild
==========

Init sparkbuild wrapper repo for Spark-1.6.0 official release.
This branch tracks the upstream branch-1.6 branch.

How to Install Spark RPM for this build
==========
```
# Install on Hadoop 2.7.1
yum install alti-spark-1.6.0 alti-spark-1.6.0-example alti-spark-1.6.0-yarn-shuffle

# Install on Hadoop 2.4.1
yum install alti-spark-1.4.2.hadoop24.hive13 alti-spark-1.4.2.hadoop24.hive13-example
```

Deployment now relies on Chef server. See the alti_spark_app-cookbook and alti_spark_role-cookbook
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


