name := "SparkSQLTestSuiteExamples"

version := "1.0"

scalaVersion := "2.10.4"

// BUILD option 1
// You can create a local repository and use the resolvers to include them
// ~/.m2/repository/local/org/apache/spark/
// drwxr-xr-x. 3 makerpm makerpm 4096 Apr 18 02:04 spark-assembly_2.10
// drwxr-xr-x. 3 makerpm makerpm 4096 Apr 18 02:04 spark-catalyst_2.10
// drwxr-xr-x. 3 makerpm makerpm 4096 Apr 18 02:04 spark-core_2.10
// drwxr-xr-x. 3 makerpm makerpm 4096 Apr 18 02:04 spark-sql_2.10

// resolvers += "Local Maven Repository" at "file://"+Path.userHome.absolutePath+"/.m2/repository"

// libraryDependencies += "local.org.apache.spark" % "spark-assembly_2.10" % "1.3.1"

// libraryDependencies += "local.org.apache.spark" % "spark-sql_2.10" % "1.3.1"

// libraryDependencies += "local.org.apache.spark" % "spark-catalyst_2.10" % "1.3.1"

// OR 
// BUILD option 2 (easier)
// just create a lib local directory in the sbt project, and copy the JARs there.

resolvers += "Akka Repository" at "http://repo.akka.io/releases/"

resolvers += "Sonatype OSS Snapshots" at "https://oss.sonatype.org/content/repositories/snapshots"


