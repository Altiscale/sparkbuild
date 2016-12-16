# Set spark version
cd ${WORKSPACE}/spark
mvn versions:set -DnewVersion=$SPARK_VERSION

# Build spark
mvn -Phadoop-2.7 -Phadoop-provided -Phive-provided -Psparkr -Pyarn -Pkinesis-asl -DskipTests -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true -Dfindbugs.skip=true clean package

if [ $? -ne "0" ] ; then
  echo "fail - build failed"
  exit -99
fi

cd sql/hive-thriftserver
mvn -Phadoop-2.7 -Phadoop-provided -Phive-provided -Psparkr -Pyarn -DskipTests -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true -Dfindbugs.skip=true package

if [ $? -ne "0" ] ; then
  echo "fail - build failed"
  exit -99
fi
