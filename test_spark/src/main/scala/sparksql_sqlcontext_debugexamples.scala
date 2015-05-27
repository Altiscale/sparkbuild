import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._
import org.apache.spark.SparkConf

case class PersonDebug(name: String, age: Int)

object SparkSQLTestCase1SQLContextDebugApp {
 def main(args: Array[String]) {

  val conf = new SparkConf().setAppName("Spark SQL Context TestCase Application")
  val sc = new SparkContext(conf)

  // sc is an existing SparkContext.
  val sqlContext = new org.apache.spark.sql.SQLContext(sc)

  // SPARK-1.2 createSchemaRDD obsolete, used to implicitly convert an RDD to a SchemaRDD.
  // import sqlContext.createSchemaRDD

  // SPARK-1.3 This is used to implicitly convert an RDD to a DataFrame.
  import sqlContext.implicits._

  // Define the schema using a case class.
  // Note: Case classes in Scala 2.10 can support only up to 22 fields. To work around this limit,
  // you can use custom classes that implement the Product interface.
  
  // Create an RDD of PersonDebug objects and register it as a table.
  // val people = sc.textFile("spark/test/resources/people.txt").map(_.split(",")).map(p => PersonDebug(p(0), p(1).trim.toInt))
  // SPARK-1.3, applying toDF() function here.
  val people = sc.textFile("spark/test/resources/people.txt").map(_.split(",")).map(p => PersonDebug(p(0), p(1).trim.toInt)).toDF()
  people.registerTempTable("people")

  // SQL statements can be run by using the sql methods provided by sqlContext.
  val teenagers = sqlContext.sql("SELECT name FROM people WHERE age >= 13 AND age <= 19")

  // Debug with explain
  teenagers.explain
  teenagers.explain(true)

  // Debug SQL with DebugQuery developer API, be careful, this is a Developer API
  // and may change in the future. This will actually run the query and print out some
  // information such as how may records returned, filtered, from which RDD, etc.
  import org.apache.spark.sql.execution.debug._
  teenagers.debug

  // The results of SQL queries are SchemaRDDs and support all the normal RDD operations.
  // The columns of a row in the result can be accessed by ordinal.
  teenagers.map(t => "Name: " + t(0)).collect().foreach(println)

  // You should see 2 queries occured in the AM UI due to the debug and the last count actions
  }
}

