#!/bin/bash
#
# Default settings used by scripts within the bin directory
# 
#-------------------------------------------------------------------

#Put everything in a catissue sub directory
defaultetc=/etc/brisskit/catissue
defaultvar=$CATISSUE_INSTALL_DIRECTORY
defaultsys=${defaultvar}/system
defaultbin=${defaultvar}/system/bin
defaulttmp=${defaultvar}/system/tmp
defaultlog=/var/log

set +o nounset
export brisskitetc=${brisskitetc:=${defaultetc}}
export brisskitvar=${brisskitvar:=${defaultvar}}
export brisskitsys=${brisskitsys:=${defaultsys}}
export brisskitbin=${brisskitbin:=${defaultbin}}
export brisskittmp=${brisskittmp:=${defaulttmp}}
export brisskitlog=${brisskitlog:=${defaultlog}}

echo "DEBUG SECTION FOLLOWS..."
echo "brisskitetc = ${brisskitetc}"
echo "brisskitvar = ${brisskitvar}"
echo "brisskitsys = ${brisskitsys}"
echo "brisskitbin = ${brisskitbin}"
echo "brisskittmp = ${brisskittmp}"
echo "brisskitlog = ${brisskitlog}"

# We need a user and password for wget to maven repo
export MVN_READONLY_USER=readonly
export MVN_READONLY_PASSWORD=readonly.....

# Acquisition paths:
#export JDK_DOWNLOAD_PATH=http://maven.brisskit.org/nexus/content/repositories/thirdparty/oracle/jdk/jdk/7u17-linux/jdk-7u17-linux-x64.tar.gz
export JDK_DOWNLOAD_PATH=http://maven.brisskit.org/nexus/content/repositories/thirdparty/oracle/jdk/jdk/6u39-linux/jdk-6u39-linux-x64.bin
export JBOSS_DOWNLOAD_PATH=http://maven.brisskit.org/nexus/content/repositories/thirdparty/jboss/jboss-server/jboss/4.2.3.GA/jboss-4.2.3.GA.zip
export CATISSUE_INSTALLABLE_ZIP_DOWNLOAD_PATH=http://maven.brisskit.org/nexus/content/repositories/thirdparty/catissue/caTissue_Plus/v3.0.2_Installable/caTissue_Plus-v3.0.2_Installable.zip
export CATISSUE_INTEGRATION_WS_DOWNLOAD_PATH=http://maven.brisskit.org/nexus/content/repositories/releases/org/brisskit/app/catissue/caTissue-v1.2plus-WS/1.0-RC1/caTissue-v1.2plus-WS-1.0-RC1.war
export CATISSUE_ADMIN_PROCEDURES_DOWNLOAD_PATH=http://maven.brisskit.org/nexus/content/repositories/releases/org/brisskit/app/catissue/catissue-admin-procedures/1.0-RC1/catissue-admin-procedures-1.0-RC1.zip
export JERSEY_BUNDLE_DOWNLOAD_PATH=http://maven.brisskit.org/nexus/content/repositories/central/com/sun/jersey/jersey-bundle/1.3/jersey-bundle-1.3.jar

export CATISSUE_DIRECTORY_NAME=$( basename ${CATISSUE_INSTALLABLE_ZIP_DOWNLOAD_PATH} .zip )
export JBOSS_DIRECTORY_NAME=$( basename ${JBOSS_DOWNLOAD_PATH} .zip )
#export JDK_DIRECTORY_NAME=jdk1.7.0_17
export JDK_DIRECTORY_NAME=jdk1.6.0_39
export JAVA_HOME=${brisskitvar}/java/${JDK_DIRECTORY_NAME}

# Working directories used by the admin/integration scripts to extract
# catissue data to prior to transferring to the i2b2 VM...
export CATISSUE_SOURCE_PDO=${defaultvar}/temp/pdo
export CATISSUE_SOURCE_ENUMS=${defaultvar}/temp/enums

export casjbossserverhost="catissue"
export jbossserverhost="catissue"    
export jbosshomedir="${brisskitvar}/jboss/${CATISSUE_DIRECTORY_NAME}"    
export jbosscontainersecure="no" 
export applicationenvironment="<b>Development Enviornment</b>"
export Applicationurl="http://localhost:8080/catissuecore"
export loadbalancerurl="http://localhost:8080/catissuecore"

#Get the DB config 
export catissue_databaseport=3306
export catissue_databasetype=mysql
export catissue_databasename="$(brisskit_db_param catissue name)"
export catissue_databasehost="$(brisskit_db_param catissue host)"
export catissue_databaseuser="$(brisskit_db_param catissue user)"
export catissue_databasepass="$(brisskit_db_param catissue pass)"

#Get the other DB config - what is this?!
# (Optionally used for authentication. We have it switched off)
export csmdatabaseport=3306
export csmdatabasetype=mysql
export csmdatabasename="$(brisskit_db_param catissue name)"
export csmdatabasehost="$(brisskit_db_param catissue host)"
export csmdatabaseusername="$(brisskit_db_param catissue user)"
export csmdatabasepassword="$(brisskit_db_param catissue pass)"

set -o nounset