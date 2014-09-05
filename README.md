sparkbuild
==========

Init sparkbuild wrapper repo for Spark-1.1.1 (aka 1.1-rc3) official release.
This branch tracks the upstream branch-1.1.0 branch.

How to Install Spark RPM for this build
==========
```
yum install --enablerepo=verticloud-test alti-spark-1.1.1
```

How to Install via Chef and mkcluster
==========
When you run mkcluster, you will need to manually add the spark in the run_list.
For example, I created a cluster with name alee-ae525-vpc2-cluster with the following mkcluster command on VPC.
Currently, we built Spark 1.1 on Hadoop 2.2.0 with Hive 0.12. (Hive0.13.1+ is not yet supported due to incompatible Hive APIs).

```
mkcluster create -i alee-ae525-vpc2-cluster -t ./chef/environments/fantastic_four/template --region=us-west-1 --environment=dev --desktop=alee-ae525-vpc2-cluster-dt.test.altiscale.com --resource-manager=alee-ae525-vpc2-cluster-rm.test.altiscale.com --namenode=alee-ae525-vpc2-cluster-nn.test.altiscale.com --services-node=alee-ae525-vpc2-cluster-sn.test.altiscale.com --compute-nodes=alee-ae525-vpc2-cluster-s0.test.altiscale.com alee-ae525-vpc2-cluster-s1.test.altiscale.com alee-ae525-vpc2-cluster-s2.test.altiscale.com --configserver-iptables --force -d ./chef/environments/fantastic_four/alee-ae525-vpc2-cluster --hadoop-22
```
Before you run deploy_desktop.rb, add the following entry to desktop.json
```
vim ./chef/environments/fantastic_four/alee-ae525-vpc2-cluster/roles/desktop.json
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
Now, you can run deploy_desktop.rb, and it will install spark 1.1 on workbench. For example,
```
./deploy_desktop.rb -k ~/.ssh/generic_smoke -l debug -H alee-ae525-vpc2-cluster-dt.test.altiscale.com -c alee-ae525-vpc2-cluster
```

Run Test Case
==========
Copy the folder test_spark to the remote workbench. We will use /tmp/ here for example.
Run the command as the user you want to test. In Altiscale, alti-test-01 is usually
the user we use to test most test case. We will apply the same user here.
Run the following command.

```
scp -r test_spark workbench_hostname:/tmp/
```

Login to remote workbench.
```
ssh workbench_hostname
cd /tmp/
/bin/su - alti-test-01 -c "/tmp/test_spark/test_spark_shell.sh"
```
The test should exit with 0 if everything completes correctly.

