sparkbuild
==========

Init sparkbuild wrapper repo for Spark-1.6.0 official release.
This branch tracks the upstream branch-1.5 branch.

How to Install Spark RPM for this build
==========
```
# Install on Hadoop 2.7.1
yum install alti-spark-1.6.0.hadoop27.hive121 alti-spark-1.6.0.hadoop27.hive121-example alti-spark-1.6.0.hadoop27.hive121-yarn-shuffle

# Install on Hadoop 2.4.1
yum install alti-spark-1.6.0.hadoop24.hive121 alti-spark-1.6.0.hadoop24.hive121-example
```

Before you run deploy_desktop.rb, add the following entry to desktop.json
```
vim ./chef/environments/fantastic_four/alee-vpc2-cluster/roles/desktop.json
```
The spark entry in run_list:
```
"recipe[hadoop-eco::spark]"
```
Now, you can run deploy_desktop.rb, and it will install spark 1.6.0 on workbench. For example,
```
./deploy_desktop.rb -k ~/.ssh/your_priv_key -l debug -H alee-vpc2-dt.test.altiscale.com -c alee-vpc2-cluster
```

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


