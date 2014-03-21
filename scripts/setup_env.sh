#!/bin/bash

export JAVA_HOME=/usr/java/default
export MAVEN_HOME=/opt/apache-maven
export ANT_HOME=/opt/apache-ant
export M2_HOME=/opt/apache-maven
export MAVEN_HOME=/opt/apache-maven
export MAVEN_OPTS="-Xmx2048m -XX:MaxPermSize=1024m"
export SCALA_HOME=/opt/scala
export PATH=$PATH:$M2_HOME/bin:$SCALA_HOME/bin:$ANT_HOME/bin:$JAVA_HOME/bin

