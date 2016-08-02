name := "SparkTestSuiteExamples"

version := "2.0"

scalaVersion := "2.11.8"

// This is designed for Spark 1.3, 1.4, 1.5, 1.6. 2.0 has not been officially released yet.

// BUILD option 1
// You can create a local repository and use the resolvers to include them
// ~/.m2/repository/local/org/apache/spark/
// drwxr-xr-x. 3 makerpm makerpm 4096 Apr 18 02:04 spark-assembly_2.11
// drwxr-xr-x. 3 makerpm makerpm 4096 Apr 18 02:04 spark-catalyst_2.11
// drwxr-xr-x. 3 makerpm makerpm 4096 Apr 18 02:04 spark-core_2.11
// drwxr-xr-x. 3 makerpm makerpm 4096 Apr 18 02:04 spark-sql_2.11

// resolvers += "Local Maven Repository" at "file://"+Path.userHome.absolutePath+"/.m2/repository"

// libraryDependencies += "local.org.apache.spark" % "spark-assembly_2.11" % "2.0.0"

// libraryDependencies += "local.org.apache.spark" % "spark-sql_2.11" % "2.0.0"

// libraryDependencies += "local.org.apache.spark" % "spark-catalyst_2.11" % "2.0.0"

// OR 
// BUILD option 2 (easier)
// just create a lib local directory in the sbt project, and copy the JARs there.

resolvers += "Akka Repository" at "http://repo.akka.io/releases/"


