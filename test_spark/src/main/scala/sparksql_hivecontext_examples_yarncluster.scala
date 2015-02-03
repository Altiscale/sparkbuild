import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._
import org.apache.spark.SparkConf
import org.apache.spark.sql.hive.HiveContext
import org.apache.spark.sql.hive._

object SparkSQLTestCase2HiveContextYarnClusterApp {
 def main(args: Array[String]) {

  val conf = new SparkConf().setAppName("Spark SQL Hive Context TestCase Application")
  val sc = new SparkContext(conf)
  val hiveContext = new org.apache.spark.sql.hive.HiveContext(sc)

  import hiveContext._

  // Set default hive warehouse that aligns with /etc/hive-metastore/hive-site.xml
  hiveContext.hql("SET hive.metastore.warehouse.dir=hdfs://hive")

  // Create table and clean up data
  hiveContext.hql("CREATE TABLE IF NOT EXISTS spark_hive_test_yarn_cluster_table (key INT, value STRING)")

  // load sample data from HDFS, need to be uploaded first
  hiveContext.hql("LOAD DATA INPATH 'spark/test/resources/kv1.txt' INTO TABLE spark_hive_test_yarn_cluster_table")

  // Queries are expressed in HiveQL, use collect(), results go into memory, be careful. This is just
  // a test case. Do NOT use the following line for production, store results to HDFS.
  hiveContext.hql("FROM spark_hive_test_yarn_cluster_table SELECT key, value").collect().foreach(println)

  }
}


