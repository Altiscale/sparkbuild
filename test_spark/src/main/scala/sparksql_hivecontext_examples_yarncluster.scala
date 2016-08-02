/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// scalastyle:off println

import org.apache.spark.{SparkConf, SparkContext}

// $example on:spark_hive$
import org.apache.spark.sql.Row
import org.apache.spark.sql.SparkSession
// $example off:spark_hive$

object SparkSQLTestCase1HiveContextYarnClusterApp {

  // $example on:spark_hive$
  case class Record(key: Int, value: String)
  // $example off:spark_hive$

  def main(args: Array[String]) {
    // A hive context adds support for finding tables in the MetaStore and writing queries
    // using HiveQL. Users who do not have an existing Hive deployment can still create a
    // HiveContext. When not configured by the hive-site.xml, the context automatically
    // creates metastore_db and warehouse in the current directory.

    // $example on:spark_hive$
    // This applies the runtime container directory as the 
    // val warehouseLocation = "file:${system:user.dir}/spark-warehouse"

    val spark = SparkSession
      .builder()
      .appName("SparkSQLTestCase1HiveContextYarnClusterApp")
      .enableHiveSupport()
      .getOrCreate()

    import spark.implicits._
    import spark.sql

    sql("CREATE TABLE IF NOT EXISTS src (key INT, value STRING)")
    sql(s"LOAD DATA INPATH 'spark/test/resources/kv1.txt' INTO TABLE src")

    // Queries are expressed in HiveQL
    println("Result of 'SELECT *': ")
    sql("SELECT * FROM src").collect().foreach(println)
    sql("SELECT * FROM src").show()

    // Aggregation queries are also supported.
    val count = sql("SELECT COUNT(*) FROM src").collect().head.getLong(0)
    println(s"COUNT(*): $count")
    sql("SELECT COUNT(*) FROM src").show()

    // The results of SQL queries are themselves DataFrames and support all normal functions.
    val sqlDF = sql("SELECT key, value FROM src WHERE key < 10 ORDER BY key")

    // The items in DaraFrames are of type Row, which allows you to access each column by ordinal.
    val stringsDS = sqlDF.map {
      case Row(key: Int, value: String) => s"Key: $key, Value: $value"
    }
    // Default shows the top 20 rows
    stringsDS.show()

    // You can also use DataFrames to create temporary views within a HiveContext.
    val recordsDF = spark.createDataFrame((1 to 100).map(i => Record(i, s"val_$i")))
    recordsDF.createOrReplaceTempView("records")

    // Queries can then join DataFrame data with data stored in Hive.
    println("Result of 'SELECT *' from registered temp tables: ")
    sql("SELECT * FROM records r JOIN src s ON r.key = s.key").show()

    sql("SELECT * FROM records r JOIN src s ON r.key = s.key").collect().foreach(println)
    // $example off:spark_hive$

    spark.stop()
  }
}
// scalastyle:on println
