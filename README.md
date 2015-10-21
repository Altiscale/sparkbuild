sparkbuild
==========

Init sparkbuild wrapper repo for Spark-1.4.2 (aka 1.4.2-rc1) official release.
This branch tracks the upstream branch-1.4 branch.

How to Install Spark RPM for this build
==========
```
yum install alti-spark-1.4.2.hadoop24.hive13 alti-spark-1.4.2.hadoop24.hive13-test
```

How to Install via Chef and mkcluster
==========
When you run mkcluster, you will need to manually add the spark in the run_list.
For example, I created a cluster with name alee-vpc2 with the following mkcluster command on VPC.
Currently, we built Spark 1.4.2 on Hadoop 2.4.1 with Hive 0.13.1. 
Also tested on Hadoop 2.7.0.
Most function works on Keberos enabled cluster except Spark TS2.

```
mkcluster create -i alee-vpc2-cluster -t /Users/alee/AltiScale/vpc2/chef/environments/fantastic_four/template --region=us-west-1 --environment=dev --desktop=alee-vpc2-dt.test.altiscale.com --resource-manager=alee-vpc2-rm.test.altiscale.com --namenode=alee-vpc2-nn.test.altiscale.com --services-node=alee-vpc2-gw.test.altiscale.com --compute-nodes=alee-vpc2-slave-0.test.altiscale.com alee-vpc2-slave-1.test.altiscale.com alee-vpc2-slave-2.test.altiscale.com --configserver-iptables --force -d /Users/alee/AltiScale/vpc2/chef/environments/fantastic_four/alee-vpc2-cluster --hadoop-24 --no-krb
```

Before you run deploy_desktop.rb, add the following entry to desktop.json
```
vim ./chef/environments/fantastic_four/alee-vpc2-cluster/roles/desktop.json
```
The spark entry in run_list:
```
"recipe[hadoop-eco::spark]"
```
For example, in my desktop.json, I just add it after Pig's recipe.
```
"run_list": [
    "recipe[centos_base::aws_hostname]",
    "recipe[hadoop-eco::aws]",
    "recipe[hadoop-eco::alti_utils]",
    "recipe[hadoop-eco::tmpdir]",
    "recipe[hadoop-eco::ec2_get_ssh]",
    "role[cluster]",
    "recipe[hadoop-eco::hive_metastore]",
    "recipe[hadoop-eco::hive_client]",
    "recipe[hadoop-eco::hiveserver2]",
    "recipe[hadoop-eco::oozie_client]",
    "recipe[hadoop-eco::pig]",
    "recipe[hadoop-eco::spark]",
....
```
Now, you can run deploy_desktop.rb, and it will install spark 1.4.2 on workbench. For example,
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


