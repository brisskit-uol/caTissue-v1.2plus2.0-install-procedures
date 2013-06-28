#!/bin/bash
# Shell script functions to install and configure caTissue.
#
# Based on code developed by Wizzard Solutions Ltd.
# Original code was licensed under the GNU General Public License version 3.
#


# TODO : Change the default password.
# TODO : Fix the security bug. - Which one (7/1/13)?
# (7/1/13) There are still a lot of explicit jboss version numbers in this, really they should be variables.

#Should just be able to call the directories that are defined in briccs-init.sh
#eg brisskitetc, brisskitvar, brisskitsys, brisskitbin, brisskittmp, brisskitlog
#you will need a slash at the end of each

#########################################
# Configuration functions.
#

#
# Get the default caTissue version.
catissuedefault()
    {
    local installed=$(installedget 'catissue' 'version')
    if [ -n "${installed}" ]
    then
        echo "${installed}"
    else
        brisskitconfigget 'catissue' 'default' 'version'
    fi
    }

#
# Get the installed caTissue version.
catissueversion()
    {
    installedget 'catissue' 'version'
    }

#
# Get the installed caTissue path.
catissuepath()
    {
    installedget 'catissue' 'path'
    }

#
# Get the caTissue root path.
catissueroot()
    {
    echo "${brisskitvar}/catissue"
    }

#
# Get the caTissue temp 
catissuetemp()
    {
    echo "${brisskittmp}/catissue"
    }

#
# Get the path to the caTissue log file.
catissuelogfile()
    {
    echo "$(jbosslogdir)/catissue.log "
    }

#########################################
# caTissue install functions.
#

#
# Unpack a version of caTissue.
catissueunpack()
    {
        echo "Unpacking caTissue Installable source"
        cd "${brisskitbin}/source/"
		
	    unzip -q "${brisskitbin}/source/$( basename $CATISSUE_INSTALLABLE_ZIP_DOWNLOAD_PATH )" \
	          -d "${brisskitbin}/source/$( basename $CATISSUE_INSTALLABLE_ZIP_DOWNLOAD_PATH .zip )"       

        cd "${brisskitbin}/source/$( basename $CATISSUE_INSTALLABLE_ZIP_DOWNLOAD_PATH .zip )"
        touch log4j.properties

        cd "${brisskitvar}/jboss/${JBOSS_DIRECTORY_NAME}/server/default/lib"
        mv hibernate3.jar "${brisskitvar}"
    }


#
# Configure the caTissue deployment properties.
catissueconfigdeploy()
    {
    infolog "ca 2 Configuring caTissue deployment properties"

    local catissuepath="${brisskitbin}/source/${CATISSUE_DIRECTORY_NAME}"

    local jbossservername=default
    local jbossserverport=8080
    local jbossserverhome=$(jbosspath)

    local mailhost=$(brisskitconfigget   'catissue' 'email'  'mailhost')
    local maildest=$(brisskitconfigget   'catissue' 'email'  'maildest')
    local mailfrom=$(brisskitconfigget   'catissue' 'email'  'mailfrom')

    local admindept=$(brisskitconfigget  'catissue' 'admin' 'department')
    local admininst=$(brisskitconfigget  'catissue' 'admin' 'institution')
    local admingroup=$(brisskitconfigget 'catissue' 'admin' 'group')
    local adminmail=$(brisskitconfigget  'catissue' 'admin' 'mail')
    local adminpass=$(brisskitconfigget  'catissue' 'admin' 'pass')

    if [ ! -f "${catissuepath}/caTissueInstall.properties.original" ]
    then
        cp "${catissuepath}/caTissueInstall.properties" \
           "${catissuepath}/caTissueInstall.properties.original"
    fi

# saj begin
 
     sed -i '
        s|^#*\(database.host\)=.*|\1='"${catissue_databasehost}"'|
        s|^#*\(database.name\)=.*|\1='"${catissue_databasename}"'|
        s|^#*\(jboss.server.host\)=.*|\1='"${jbossserverhost}"'|
        s|^#*\(cas.jboss.server.host\)=.*|\1='"${casjbossserverhost}"'|        
        s|^#*\(jboss.home.dir\)=.*|\1='"${jbosshomedir}"'|
        s|^#*\(jboss.container.secure\)=.*|\1='"${jbosscontainersecure}"'|
        s|^#*\(application.environment\)=.*|\1='"${applicationenvironment}"'|
        s|^#*\(Application.url\)=.*|\1='"${Applicationurl}"'|
        s|^#*\(load.balancer.url\)=.*|\1='"${loadbalancerurl}"'|
        s|^#*\(csm.database.type\)=.*|\1='"${csmdatabasetype}"'|
		s|^#*\(csm.database.host\)=.*|\1='"${csmdatabasehost}"'|
		s|^#*\(csm.database.port\)=.*|\1='"${csmdatabaseport}"'|
		s|^#*\(csm.database.name\)=.*|\1='"${csmdatabasename}"'|
		s|^#*\(csm.database.username\)=.*|\1='"${csmdatabaseusername}"'|
		s|^#*\(csm.database.password\)=.*|\1='"${csmdatabasepassword}"'|            
        ' "${catissuepath}/caTissueInstall.properties"
    
# saj end
    
   
    sed -i '
        s|^#*\(jboss.home.dir\)=.*|\1='"${jbossserverhome}"'|
        s|^#*\(jboss.server.name\)=.*|\1='"${jbossservername}"'|
        s|^#*\(jboss.server.port\)=.*|\1='"${jbossserverport}"'|
        ' "${catissuepath}/caTissueInstall.properties"

    sed -i '
        s|^#*\(database.type\)=.*|\1='"${catissue_databasetype}"'|
        s|^#*\(database.port\)=.*|\1='"${catissue_databaseport}"'|
        s|^#*\(database.username\)=.*|\1='"${catissue_databaseuser}"'|
        s|^#*\(database.password\)=.*|\1='"${catissue_databasepass}"'|
        ' "${catissuepath}/caTissueInstall.properties"

    sed -i '
        s|^#*\(use.email.commonpackage.config\)=.*|\1=true|
        s|^#*\(email.mailServer\)=.*|\1='"${mailhost}"'|
        ' "${catissuepath}/caTissueInstall.properties"

    sed -i '
        s|^#*\(email.exception.subject\)=.*|\1=System exception occured|
        s|^#*\(email.sendEmailFrom.name\)=.*|\1=caTissue Server on ['"$(hostname -f)"']|
        ' "${catissuepath}/caTissueInstall.properties"

    sed -i '
        s|^#*\(email.administrative.emailAddress\)=.*|\1='"${maildest}"'|
        s|^#*\(email.sendEmailFrom.emailAddress\)=.*|\1='"${mailfrom}"'|
        s|^#*\(email.sendEmailTo.emailAddress\)=.*|\1='"${maildest}"'|
        s|^#*\(email.admin.support.emailAddress\)=.*|\1='"${maildest}"'|
        ' "${catissuepath}/caTissueInstall.properties"

    sed -i '
        s|^#*\(first.admin.department\)=.*|\1='"${admindept}"'|
        s|^#*\(first.admin.institution\)=.*|\1='"${admininst}"'|
        s|^#*\(first.admin.cancerresearchgroup\)=.*|\1='"${admingroup}"'|
        s|^#*\(first.admin.emailAddress\)=.*|\1='"${adminmail}"'|
        s|^#*\(first.admin.password\)=.*|\1='"${adminpass}"'|
        ' "${catissuepath}/caTissueInstall.properties"

#TODO: Do we need to set these ?
#Hostname or IP address of the machine on which the JBoss server is running.
#CAUTION: This parameter should not be set to localhost. Set the actual hostname or IP address
#jboss.server.host=
#Enter yes/no to specify Secure HTTP connection
#jboss.container.secure=

#
# No need to set this, default is the same.
#    cacoredeployable=./cacore_deployable
#    sed -i '
#        s|^#*\(cacore.deployable.location\)=.*|\1='"${cacoredeployable}"'|
#        ' "${catissuepath}/caTissueInstall.properties"
#

    }


#
# Install the brisskit logos.
catissuebrisskitlogo()
    {
    infolog "ca 3 Adding brisskit logos to caTissue"
 	local catissuepath="${brisskitbin}/source/${CATISSUE_DIRECTORY_NAME}"
    # in v20 images are /var/local/brisskit/system/bin/source/${CATISSUE_DIRECTORY_NAME}/modules/caTissue/images

    if [ ! -e "${catissuepath}/images/uIEnhancementImages/siteman_logo.gif.original" ]
    then
    
        infolog "ca 3a Adding brisskit logos to catissuepath [${catissuepath}]"
    
        mv \
        "${catissuepath}/images/uIEnhancementImages/siteman_logo.gif" \
        "${catissuepath}/images/uIEnhancementImages/siteman_logo.gif.original"
    fi

    cp \
        "${CATISSUE_INSTALL_PROCS_HOME}/config/catissue/customer-logo.gif" \
        "${catissuepath}/modules/caTissue/images/InstitutionLogo.gif"

    cp \
        "${CATISSUE_INSTALL_PROCS_HOME}/config/catissue/customer-logo.gif" \
        "${catissuepath}/images/uIEnhancementImages/siteman_logo.gif"

    }

#
# Install the brisskit text files.
catissuebrisskittext()
    {
    infolog "ca 4 Adding brisskit text to caTissue"
    local catissuepath="${brisskitbin}/source/${CATISSUE_DIRECTORY_NAME}"

    cp \
        "${CATISSUE_INSTALL_PROCS_HOME}/config/catissue/Accessibility.txt" \
        "${catissuepath}/catissuecore-properties/Accessibility.txt"

    cp \
        "${CATISSUE_INSTALL_PROCS_HOME}/config/catissue/ContactUs.txt" \
        "${catissuepath}/catissuecore-properties/ContactUs.txt"

    cp \
        "${CATISSUE_INSTALL_PROCS_HOME}/config/catissue/Disclaimer.txt" \
        "${catissuepath}/catissuecore-properties/Disclaimer.txt"

    cp \
        "${CATISSUE_INSTALL_PROCS_HOME}/config/catissue/PrivacyNotice.txt" \
        "${catissuepath}/catissuecore-properties/PrivacyNotice.txt"

    }

#
# Run the caTissue Ant build.
catissuebuild()
    {
    #
    # Install Ant build tools.
    installpackage ant
    #installpackage ant-nodeps
    #installpackage ant-commons-logging
    #installpackage xml-commons-apis

    #
    # Run the caTissue build script.
    cd "${brisskitbin}/source/$( basename $CATISSUE_INSTALLABLE_ZIP_DOWNLOAD_PATH .zip )"

    if [ ! -e "log4j.properties" ]
    then
        touch "log4j.properties"
    fi

    #
    # Run the Ant build.
        
    #ant build_war        
    ant deploy_all 2>&1 | tee catissue-deploy-$(date +%Y%m%d.%H%M%S).log
    #ant deploy_all 2>2.log 1>1.log
        
    #ant -f deploy.xml deploy_all 2>&1 | tee catissue-deploy-$(date +%Y%m%d.%H%M%S).log
    }


#deploy webservice war file
catissuewebservice()
{
#	cd "${brisskitvar}/jboss/${JBOSS_DIRECTORY_NAME}/server/default/deploy"
	wget --user=$MVN_READONLY_USER \
         --password=$MVN_READONLY_PASSWORD \
         -O /tmp/catissueWS.war \
         $CATISSUE_INTEGRATION_WS_DOWNLOAD_PATH 
    mv /tmp/catissueWS.war "${brisskitvar}/jboss/${JBOSS_DIRECTORY_NAME}/server/default/deploy"
    echo "catissue webservice deployed"
}

#restart catissue
catissuerestart()
{
    eval "${brisskitvar}/jboss/${JBOSS_DIRECTORY_NAME}/bin/shutdown.sh -S"
    sleep 20
    eval "${brisskitvar}/jboss/${JBOSS_DIRECTORY_NAME}/bin/run.sh -b 0.0.0.0 &"
    echo "catissue restarted"
}

#
# install the admin procedures
catissueadminprocs()
{
    cd "${brisskitvar}"
    wget --user=$MVN_READONLY_USER \
         --password=$MVN_READONLY_PASSWORD \
         $CATISSUE_ADMIN_PROCEDURES_DOWNLOAD_PATH

    #
    # Unzip i2b2 admin procedures file...
	unzip $CATISSUE_INSTALL_DIRECTORY/$( basename $CATISSUE_ADMIN_PROCEDURES_DOWNLOAD_PATH ) 
	
	#
	# Make them a little more restrictive...
	chmod -R o-w,o+x $CATISSUE_INSTALL_DIRECTORY/catissue*admin-procedures*
	
	#
	# A couple of symbolic link makes things a little easier...
	ln -s ${CATISSUE_INSTALL_DIRECTORY}/catissue*admin-procedures* catissue-admin-procedures
	ln -s ${CATISSUE_INSTALL_DIRECTORY}/catissue*install-procedures* catissue-install-procedures
	
	#
	# The following connection format is for mysql
	# (NB: these have escape characters in it)...
	local catissue_jdbc_connection="jdbc:${catissue_databasetype}://${catissue_databasehost}:${catissue_databaseport}/${catissue_databasename}"
	
	#
	# Update the admin procedures configuration files and settings...
	sed -i '
        s|^#*\(db.user\)=.*|\1='"${catissue_databaseuser}"'|
        s|^#*\(db.password\)=.*|\1='"${catissue_databasepass}"'|
        s|^#*\(db.connection\)=.*|\1='"${catissue_jdbc_connection}"'|
        s|^#*\(catissue.source.pdo.path\)=.*|\1='"${CATISSUE_SOURCE_PDO}"'|
        s|^#*\(catissue.source.enums.path\)=.*|\1='"${CATISSUE_SOURCE_ENUMS}"'|
        ' "${CATISSUE_INSTALL_DIRECTORY}/catissue-admin-procedures/config/config.properties" 
        
    sed -i '
        s|^#*\(CATISSUE_SOURCE_PDO\)=.*|\1='"${CATISSUE_SOURCE_PDO}"'|
        s|^#*\(CATISSUE_SOURCE_ENUMS\)=.*|\1='"${CATISSUE_SOURCE_ENUMS}"'|
        ' "${CATISSUE_INSTALL_DIRECTORY}/catissue-admin-procedures/config/defaults.sh" 
        	
	#
	# Create the working directories used by the integration layer
	# for extracting catissue data and transferring to i2b2...
	# (These are better created here rather than dynamically by the integration user)...
	mkdir -p ${CATISSUE_SOURCE_PDO}
	chown -Rf integration ${CATISSUE_SOURCE_PDO}	
	mkdir -p ${CATISSUE_SOURCE_ENUMS}
	chown -Rf integration ${CATISSUE_SOURCE_PDO}
	
	#
	# Finally, remove the zip admin package...
	rm $CATISSUE_INSTALL_DIRECTORY/$( basename $CATISSUE_ADMIN_PROCEDURES_DOWNLOAD_PATH )
}

#to modify jboss run.conf
changejbossrunconf()
{
        sed -i '        
        s|^#*\(   JAVA_OPTS\)=.*|\1='"\"-Xms512m -Xmx1024m -Xrs -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000 -XX:MaxPermSize=256m -XX:ReservedCodeCacheSize=64m -XX:+UseConcMarkSweepGC -XX:+CMSPermGenSweepingEnabled -XX:+CMSClassUnloadingEnabled\""'|
        ' "$(jbosspath)/bin/run.conf"
	echo "modified jboss run.conf"
}


#
# Install caTissue.
catissueinstall()
    {
    local version=${1:-$(catissuedefault)}

    echo "jbossversion ${version}"
    #
    # Install and configure JBoss.
    jbossinstall $(brisskitconfigget 'catissue' "${version}" 'jboss')

    #
    # Unpack the caTissue zipfile.
    catissueunpack "${version}"

    #
    # Configure the caTissue properties.
    catissueconfigdeploy

    #
    # Install the brisskit logos and text files.
    #catissuebrisskitlogo
    #catissuebrisskittext

    #
    # Run the caTissue Ant build.
    catissuebuild
    
    #
    #load jersey jar files
    catissueloadjerseyjars

    #
    #deploy webservice war file
    catissuewebservice

    #
    #install admin procedures
    catissueadminprocs
	
    #
    #to modify jboss run.conf
    changejbossrunconf

    #
    #catissue restart
    catissuerestart

    }

#load jersey jar files
catissueloadjerseyjars()
{
	cd ${brisskitvar}/jboss/${JBOSS_DIRECTORY_NAME}/server/default/lib
     
	wget --user=$MVN_READONLY_USER \
         --password=$MVN_READONLY_PASSWORD \
         ${JERSEY_BUNDLE_DOWNLOAD_PATH}
         
    echo "loaded jersey jars"
}
