#!/bin/bash
#
# Initial script to load the brisskit functions. 
#
#
#########################################

#########################################
# Logging functions.
#

#TODO Change these to use system log ...

#
# Error logging.
errorlog() {
    if [ -e "${brisskitlog}" ]
    then
        echo "ERROR : ${1}" | tee --append "${brisskitlog}/brisskit.log"
    else
        echo "ERROR : ${1}"
    fi
    }

#
# Debug logging.
debuglog() {
    if [ -e "${brisskitlog}" ]
    then
        echo "DEBUG : ${1}" | tee --append "${brisskitlog}/brisskit.log"
    else
        echo "DEBUG : ${1}"
    fi
    }

#
# Info logging.
infolog() {
    if [ -e "${brisskitlog}" ]
    then
        echo "INFO  : ${1}" | tee --append "${brisskitlog}/brisskit.log"
    else
        echo "INFO  : ${1}"
    fi
    }

#########################################
# Initial install functions.
#

#
# Check if SELinux is enabled.
selinuxtest()
    {
    which selinuxenable &> /dev/null && selinuxenabled
    }

#
# Check if a package is installed.
# Note: without --all deb will generate an error message.
# Note: with --all deb has to process a lot more and is slow.
installpackage()
    {
    local package=$1
    infolog "bi 1 Checking system package [${package}]"
    local version=$(deb --query --all --queryformat '%{VERSION}' "${package}" 2> /dev/null)
    if [ -n "${version}" ]
    then
        infolog "bi 2 Package [${package}][${version}] is installed"
    else
        infolog "bi 3 Installing [${package}]"
        apt-get -y --force-yes install ${package}
    fi
    }

#
# Load a brisskit function script.
brisskitscript()
    {
    local scriptname=$1
    local scriptfile="${scriptname}-functions.sh"
    if [ -e "${brisskitbin}/${scriptfile}" ]
    then
        infolog "bi 4 Loading functions [${scriptfile}]"
        source "${brisskitbin}/${scriptfile}"
    else
        errorlog "bi 5 Unable to load functions [${scriptfile}]"
        return 1
    fi
    }

#
# Initial system setup.
brisskitinit() {
    infolog "bi 6 brisskit system configuration"
    #
    # Check the tools used by the system setup.
    installpackage wget
    installpackage finger
    installpackage unzip
    installpackage patch
    installpackage which
    installpackage bind9
    installpackage openssh-client

    #
    # Install the system functions.
    if [ ! -e ${brisskitsys} ]
    then
        infolog "bi 11 Acquiring common script function, caTissue source code, JDK and JBoss"
        mkdir "${brisskitsys}"
        mkdir "${brisskitbin}"

		cp -r $CATISSUE_INSTALL_PROCS_HOME/bin/common/* "${brisskitbin}"

        wget --user=$MVN_READONLY_USER \
             --password=$MVN_READONLY_PASSWORD \
             "${JDK_DOWNLOAD_PATH}" -P "${brisskitbin}/java"
#        chmod +x ${brisskitbin}/java/$( basename $JDK_DOWNLOAD_PATH )
        wget --user=$MVN_READONLY_USER \
             --password=$MVN_READONLY_PASSWORD \
             "${JBOSS_DOWNLOAD_PATH}" -P "${brisskitbin}/jboss"
        wget --user=$MVN_READONLY_USER \
             --password=$MVN_READONLY_PASSWORD \
             "${CATISSUE_INSTALLABLE_ZIP_DOWNLOAD_PATH}" -P "${brisskitbin}/source"
    else
    	infolog "bi 12 brisskitsys directory already exists. Testing only. Will continue."
#        infolog "bi 12 brisskitsys directory already exists, giving up!"
#		exit
    fi

    #
    # Check our config directory.
    infolog "bi 13 Checking brisskit config directory"
    
    if [ ! -e "${brisskitetc}" ]
    then
        mkdir -p "${brisskitetc}"
        mkdir "${brisskitetc}/local"
	mkdir "${brisskitetc}/global"

	cp -r $CATISSUE_INSTALL_PROCS_HOME/config/global/* "${brisskitetc}/local/"
	cp -r $CATISSUE_INSTALL_PROCS_HOME/config/global/* "${brisskitetc}/global/"

	#Sort out the init script
	#I've stopped using the jbossinit function to do this as it seems to complex!
	cp -r $CATISSUE_INSTALL_PROCS_HOME/init.d/catissue "/etc/init.d/"
	update-rc.d catissue defaults


        if [ -e "${brisskitsys}/etc" ]
        then
            debuglog "bi 14 Linking brisskit config directory"
            ln -s "${brisskitsys}/etc" "${brisskitetc}"
        else
	    errorlog "bi 16 Unable to find brisskit config directory...so creating"
            mkdir "${brisskitsys}/etc"
        fi
    fi

    infolog "bi 17 Checking local config directory"
    if [ ! -e "${brisskitsys}/etc/local" ]
    then
        if [ -e "${brisskitsys}/etc" ]
        then
            debuglog "bi 18 Creating local config directory"
            mkdir "${brisskitsys}/etc/local"            
        else
            errorlog "bi 19 Unable to find brisskit config directory"
        fi
    fi

    #
    # Check our temp directory.
    infolog "bi 20 Checking brisskit temp directory"
    if [ ! -e "${brisskittmp}" ]
    then
        debuglog "bi 21 Creating brisskit temp directory"
        mkdir "${brisskittmp}"
    fi

    #
    # Load all the brisskit function scripts.
    brisskitscript system
    brisskitscript user
    brisskitscript config
    brisskitscript install
    brisskitscript jboss
    brisskitscript catissue
    }


