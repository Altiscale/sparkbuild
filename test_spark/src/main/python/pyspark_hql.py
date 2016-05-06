from __future__ import print_function

import os
import sys

from pyspark.sql import SparkSession

if __name__ == "__main__":

  # No need to use sqlContext, you will need to use SparkSession to create them now
  # since the older API has been deprecated
  mySqlContext = SparkSession\
    .builder\
    .enableHiveSupport()\
    .appName("Spark PythonSQL")\
    .getOrCreate()

  mySqlContext.sql("CREATE TABLE IF NOT EXISTS spark_python_hive_test_table (key INT, value STRING)")

  mySqlContext.sql("LOAD DATA LOCAL INPATH '/opt/spark/examples/src/main/resources/kv1.txt' INTO TABLE spark_python_hive_test_table")

  # Queries can be expressed in HiveQL.
  results = mySqlContext.sql("FROM spark_python_hive_test_table SELECT key, value").collect()

  # Python 2.7+ Syntax
  for each in results:
    print(each[0])

  mySqlContext.stop()
