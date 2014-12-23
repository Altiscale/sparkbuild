import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._
import org.apache.spark.SparkConf

case class Person(name: String, age: Int)

object SparkSQLTestCase1App {
 def main(args: Array[String]) {

  val conf = new SparkConf().setAppName("Spark SQL Context TestCase  Application")
  val sc = new SparkContext(conf)

  // sc is an existing SparkContext.
  val sqlContext = new org.apache.spark.sql.SQLContext(sc)

  // createSchemaRDD is used to implicitly convert an RDD to a SchemaRDD.
  import sqlContext.createSchemaRDD

  // Define the schema using a case class.
  // Note: Case classes in Scala 2.10 can support only up to 22 fields. To work around this limit,
  // you can use custom classes that implement the Product interface.
  
  // Create an RDD of Person objects and register it as a table.
  val people = sc.textFile("spark/test/resources/people.txt").map(_.split(",")).map(p => Person(p(0), p(1).trim.toInt))

  people.registerTempTable("people")

  // SQL statements can be run by using the sql methods provided by sqlContext.
  val teenagers = sqlContext.sql("SELECT name FROM people WHERE age >= 13 AND age <= 19")

  // The results of SQL queries are SchemaRDDs and support all the normal RDD operations.
  // The columns of a row in the result can be accessed by ordinal.
  teenagers.map(t => "Name: " + t(0)).collect().foreach(println)
  }
}


