# Set spark version
cd ${WORKSPACE}/spark
mvn versions:set -DnewVersion=$SPARK_VERSION

# Build spark
# For spark 2.0.1 and 2.0.2
mvn -Phadoop-2.7 -Phive-thriftserver -Phadoop-provided -Phive-provided -Psparkr -Pyarn -Pkinesis-asl -DskipTests -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true -Dfindbugs.skip=true clean package 

if [ $? -ne "0" ] ; then
  echo "fail - build failed"
  exit -99
fi