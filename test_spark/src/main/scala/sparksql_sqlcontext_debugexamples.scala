import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._
import org.apache.spark.SparkConf
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.Row

object SparkSQLTestCase1SQLContextDebugApp {

  case class PersonDebug(name: String, age: Int)
  def parsePerson(str: Row): PersonDebug = {
    val fields = str.mkString(",").split(",")
    assert(fields.size == 2)
    PersonDebug(fields(0), fields(1).trim.toInt)
  }

  def main(args: Array[String]) {
    val mySqlContext = SparkSession
      .builder
      .appName("Spark SQL Context DEBUG TestCase Application")
      .config("spark.sql.warehouse.dir","hdfs:///spark-warehouse")
      .getOrCreate()

    import mySqlContext.implicits._

    // Define the schema using a case class.
    // Note: Case classes in Scala 2.10 can support only up to 22 fields. To work around this limit,
    // you can use custom classes that implement the Product interface.
    // See: https://issues.scala-lang.org/browse/SI-7296
    // In Scala 2.11.0, this is fixed.

    // Create an RDD of Person objects and register it as a table.
    // val people = sc.textFile("spark/test/resources/people.txt").map(_.split(",")).map(p => Person(p(0), p(1).trim.toInt))
    // SPARK-1.3, applying toDF() function here.
    // val people = sc.textFile("spark/test/resources/people.txt").map(_.split(",")).map(p => Person(p(0), p(1).trim.toInt)).toDF()
    // Due to SPARK-2243, we will re-use the same SparkContext from SparkSession to load the file
    val people = mySqlContext.read.text("spark/test/resources/people.txt")
          .map(parsePerson)
          .toDF()
    people.createOrReplaceTempView("people")

    // SQL statements can be run by using the sql methods provided by sqlContext.
    val teenagers = mySqlContext.sql("SELECT name FROM people WHERE age >= 13 AND age <= 19")

    // Debug with explain
    teenagers.explain
    teenagers.explain(true)

    // The results of SQL queries are SchemaRDDs and support all the normal RDD operations.
    // The columns of a row in the result can be accessed by ordinal.
    teenagers.collect().foreach(println)
  }
}
