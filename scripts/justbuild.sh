# Set spark version
cd ${WORKSPACE}/spark
mvn versions:set -DnewVersion=$SPARK_VERSION

# Build spark
# For spark 2.0.2
mvn -Phadoop-2.7 -Phive-thriftserver -Phadoop-provided -Phive-provided -Psparkr -Pyarn -Pkinesis-asl -DskipTests -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true -Dfindbugs.skip=true clean package 

if [ $? -ne "0" ] ; then
  echo "fail - build failed"
  exit -99
fi

# Add RELEASE
# Spark 2.0.0 built for Hadoop 2.2.0
# Build flags: -Psparkr -Phadoop-provided -Pyarn -DzincPort=3038

# For spark 2.0, 2.0.1
#mvn -Phadoop-2.7 -Phive-thriftserver -Phadoop-provided -Phive-provided -Psparkr -Pyarn -Pkinesis-asl -DskipTests -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true -Dfindbugs.skip=true clean package
#
#cd sql/hive-thriftserver
#mvn -Phadoop-2.7 -Phadoop-provided -Phive-provided -Psparkr -Pyarn -DskipTests -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true -Dfindbugs.skip=true package
