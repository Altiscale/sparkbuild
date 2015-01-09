import os

from pyspark import SparkContext
# sc is an existing SparkContext.
from pyspark.sql import HiveContext

if __name__ == "__main__":
    sc = SparkContext(appName="PythonSQL")
    sqlContext = HiveContext(sc)

    sqlContext.sql("CREATE TABLE IF NOT EXISTS spark_python_hive_test_table (key INT, value STRING)")
    sqlContext.sql("LOAD DATA LOCAL INPATH '/opt/spark/examples/src/main/resources/kv1.txt' INTO TABLE spark_python_hive_test_table")

    # Queries can be expressed in HiveQL.
    results = sqlContext.sql("FROM spark_python_hive_test_table SELECT key, value").collect()
    for each in results:
        print each[0]

    sc.stop()
