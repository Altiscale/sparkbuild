import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._
import org.apache.spark.SparkConf
import org.apache.spark.sql.hive.HiveContext
import org.apache.spark.sql.hive._

object SparkSQLTestCase2HiveContextYarnClientApp {
 def main(args: Array[String]) {

  val conf = new SparkConf().setAppName("Spark SQL Hive Context yarn-client TestCase Application")
  val sc = new SparkContext(conf)
  val hiveContext = new org.apache.spark.sql.hive.HiveContext(sc)

  import hiveContext._

  // Create table and clean up data
  hiveContext.sql("CREATE TABLE IF NOT EXISTS spark_hive_test_yarn_client_table (key INT, value STRING)")

  // load sample data from local workbench only
  hiveContext.sql("LOAD DATA LOCAL INPATH '/opt/spark/examples/src/main/resources/kv1.txt' INTO TABLE spark_hive_test_yarn_client_table")

  // Queries are expressed in HiveQL, use collect(), results go into memory, be careful. This is just
  // a test case. Do NOT use the following line for production, store results to HDFS.
  hiveContext.sql("FROM spark_hive_test_yarn_client_table SELECT key, value").collect().foreach(println)

  }
}


