cd $WORKSPACE
ALTISCALE_RELEASE=${ALTISCALE_RELEASE:-4.0.0}
RPM_DESCRIPTION="Apache spark ${ARTIFACT_VERSION}\n\n${DESCRIPTION}"
SPARK_HOME=${WORKSPACE}/spark

# convert the tarball into an RPM
#create the installation directory (to stage artifacts)
mkdir -p --mode 0755 ${INSTALL_DIR}

OPT_DIR=${INSTALL_DIR}/opt
DISTDIR=${OPT_DIR}/alti-spark-${ARTIFACT_VERSION}
mkdir -p --mode 0755 ${DISTDIR}

# Make directory for spark packages
# 1. This code is from spark/dev/make-distributed.sh
# 1.1 copy jars
mkdir -p --mode 0755 "${DISTDIR}/jars"
cp "$SPARK_HOME"/assembly/target/scala*/jars/* "$DISTDIR/jars"

# 1.2 Only create the yarn directory if the yarn artifacts were build.
if [ -f "$SPARK_HOME"/common/network-yarn/target/scala*/spark-*-yarn-shuffle.jar ]; then
  mkdir "$DISTDIR"/yarn
  cp "$SPARK_HOME"/common/network-yarn/target/scala*/spark-*-yarn-shuffle.jar "$DISTDIR/yarn"
fi

# 1.3 Copy examples and dependencies
mkdir -p "$DISTDIR/examples/jars"
cp "$SPARK_HOME"/examples/target/scala*/jars/* "$DISTDIR/examples/jars"

# 1.4 Deduplicate jars that have already been packaged as part of the main Spark dependencies.
for f in "$DISTDIR/examples/jars/"*; do
  name=$(basename "$f")
  if [ -f "$DISTDIR/jars/$name" ]; then
    rm "$DISTDIR/examples/jars/$name"
  fi
done

# 1.5 Copy example sources (needed for python and SQL)
mkdir -p "$DISTDIR/examples/src/main"
cp -r "$SPARK_HOME"/examples/src/main "$DISTDIR/examples/src/"

# 1.6 Copy license and ASF files
cp "$SPARK_HOME/LICENSE" "$DISTDIR"
cp -r "$SPARK_HOME/licenses" "$DISTDIR"
cp "$SPARK_HOME/NOTICE" "$DISTDIR"

if [ -e "$SPARK_HOME"/CHANGES.txt ]; then
  cp "$SPARK_HOME/CHANGES.txt" "$DISTDIR"
fi

# 1.7 Copy data files
cp -r "$SPARK_HOME/data" "$DISTDIR"

# 1.8 Copy other things
#mkdir -p "$DISTDIR"/conf
#cp "$SPARK_HOME"/conf/*.template "$DISTDIR"/conf
cp "$SPARK_HOME/README.md" "$DISTDIR"
# except XXX.cmd
cp -r "$SPARK_HOME/bin" "$DISTDIR"
cp -r "$SPARK_HOME/python" "$DISTDIR"
cp -r "$SPARK_HOME/sbin" "$DISTDIR"
# Copy SparkR if it exists
if [ -d "$SPARK_HOME"/R/lib/SparkR ]; then
  mkdir -p "$DISTDIR"/R/lib
  cp -r "$SPARK_HOME/R/lib/SparkR" "$DISTDIR"/R/lib
  cp "$SPARK_HOME/R/lib/sparkr.zip" "$DISTDIR"/R/lib
fi

# 2. Copy other extra jars
# 2.1 Copy extra jars
EXTRA_JARS_DIR="external/kinesis-asl external/kinesis-asl-assembly external/kafka-0-8 external/kafka-0-8-assembly external/flume external/flume-sink external/flume-assembly sql/hive sql/hive-thriftserver"
for EXTRA_DIR in $EXTRA_JARS_DIR; do
  srcname="$SPARK_HOME/$EXTRA_DIR/target/spark*$PROJECT_VERSION.jar"
  dstdir="$DISTDIR/${EXTRA_DIR%/*}"
  mkdir -p $dstdir
  cp $srcname $dstdir
done

# 2.2 Copy config directory
ETC_DIR=${INSTALL_DIR}/etc/alti-spark-${ARTIFACT_VERSION}
mkdir -p --mode 0755 ${ETC_DIR}
cp -rp ${SPARK_HOME}/conf/* ${ETC_DIR}

# 2.3 Copy sources to source directory
mkdir -p --mode 0755 ${DISTDIR}/sources
for name in `find ${SPARK_HOME} -name spark*sources.jar -print`; do
  cp $name ${DISTDIR}/sources
done

# convert all the etc files to config files
cd ${INSTALL_DIR}
find etc -type f -print | awk '{print "/" $1}' > /tmp/$$.files
export CONFIG_FILES=""
for i in `cat /tmp/$$.files`; do CONFIG_FILES="--config-files $i $CONFIG_FILES "; done
export CONFIG_FILES
rm -f /tmp/$$.files

# 3. Build RPM
mkdir -p ${RPM_DIR}
cd ${RPM_DIR}

export RPM_NAME=`echo alti-spark-${ARTIFACT_VERSION}`
fpm --verbose \
--maintainer support@altiscale.com \
--vendor Altiscale \
--provides ${RPM_NAME} \
--replaces alti-spark \
--url ${GITREPO} \
--license "Apache License v2" \
-s dir \
-t rpm \
-n ${RPM_NAME}  \
-v ${ARTIFACT_VERSION} \
--iteration ${DATE_STRING} \
--description "${RPM_DESCRIPTION}" \
${CONFIG_FILES} \
--rpm-user root \
--rpm-group root \
-C ${INSTALL_DIR} \
opt etc
