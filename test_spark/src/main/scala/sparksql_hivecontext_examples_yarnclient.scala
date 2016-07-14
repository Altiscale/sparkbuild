import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._
import org.apache.spark.SparkConf
import org.apache.spark.sql.hive.HiveContext
import org.apache.spark.sql.hive._

object SparkSQLTestCase2HiveContextYarnClientApp {
  def main(args: Array[String]) {
    if ( args.length < 2 )
    {
      System.err.println("Missing local input file or hive table name")
      System.exit(-1)
    }
    val input_file = args(0).trim()
    val hive_table_name = args(args.length - 1).trim()
    val conf = new SparkConf().setAppName("Spark SQL Hive Context yarn-client TestCase Application")
    val sc = new SparkContext(conf)
    val hiveContext = new org.apache.spark.sql.hive.HiveContext(sc)

    import hiveContext._

    // Create table and clean up data
    hiveContext.sql("CREATE TABLE IF NOT EXISTS " + hive_table_name + " (key INT, value STRING)")

    // load sample data from local workbench only
    hiveContext.sql("LOAD DATA LOCAL INPATH '" + input_file + "' INTO TABLE " + hive_table_name)

    // Queries are expressed in HiveQL, use collect(), results go into memory, be careful. This is just
    // a test case. Do NOT use the following line for production, store results to HDFS.
    hiveContext.sql("FROM " + hive_table_name + " SELECT key, value").collect().foreach(println)
  }
}
