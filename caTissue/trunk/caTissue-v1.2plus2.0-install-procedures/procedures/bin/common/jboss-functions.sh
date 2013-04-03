#!/bin/bash
# Shell script functions to install system packages.
#
# Based on code developed by Wizzard Solutions Ltd.
# Original code was licensed under the GNU General Public License version 3.
#

#TODO Add patch to fix the HTTP security problem.

#########################################
# Config functions.
#

#
# Get the default version of JBoss.
jbossdefault()
    {
    local installed=$(installedget 'jboss' 'version')
    if [ -n "${installed}" ]
    then
        echo "${installed}"
    else
        brisskitconfigget 'jboss' 'default' 'version'
    fi
    }

#
# Get the installed JBoss version.
jbossversion()
    {
    installedget 'jboss' 'version'
    }

#
# Get the JBoss path.
# Param: Optional version to check.
jbosspath()
    {
    local version=${1:-''}
    if [ -n "${version}" ]
    then
        echo "$(jbossroot)/${version}"
    else
        installedget 'jboss' 'path'
    fi
    }

#
# Get the root JBoss path.
jbossroot()
    {
    echo "${brisskitvar}/jboss"
    }

#
# Get the name of the JBoss configuration.
jbossconf()
    {
    brisskitconfigget 'jboss' 'config' 'conf'
    }

#
# Get the full path to the JBoss configuration.
jbossconfdir()
    {
    echo "$(jbosspath)/server/$(jbossconf)"
    }

#
# Get the full path to the JBoss logs.
jbosslogdir()
    {
    echo "$(jbossconfdir)/log"
    }

#
# Get the JBoss Unix account user name.
jbossuser()
    {
    brisskitconfigget 'jboss'  'user' 'name'
    }

#########################################
# Install functions.
#

#
# Install JBoss.
jbossinstall()
    {
    #local version=${1:-$(jbossdefault)}
    local version=$( basename $JBOSS_DOWNLOAD_PATH .zip) 
    echo "jbossversion 2 ${version}"
    #
    # Install the JBoss user account.
    jbossinstalluser

    #
    # Unpack the core JBoss zipfile.
    jbossinstallcore "${version}"

    #
    # Fix the jmx-console security-constraint.
    # http://trac.brisskit.org.uk/ticket/36
    jboss20111328143530

    #
    # Install the Jboss config script.
    jbossinstallconf

    #
    # Install the Jboss init scipt.
#    jbossinstallinit
#Stopped this in favour of doing it simply in the briccs-init script.

    #
    # Configure the the Jboss working directories.
    jbossinstallwork

    sed -i '        
        s|^#*\(   JAVA_OPTS\)=.*|\1='"\"-server -Xms128m -Xmx1024m -XX:PermSize=64m -XX:MaxPermSize=256m\""'|
        ' "$(jbosspath)/bin/run.conf"

    }

#
# Install the core JBoss zipfile.
jbossinstallcore()
    {
    local version=${1:-$(jbossdefault)}

    local jbossroot=$(jbossroot)
    local jbosspath=$(jbosspath "${version}")

    infolog "jb25 Installing Java JDK"
    local jdkinstallpath=${brisskitvar}/java
    local jdkpackagename=$( basename $JDK_DOWNLOAD_PATH )
    mkdir -p ${jdkinstallpath}
    cp ${brisskitbin}/java/${jdkpackagename} ${jdkinstallpath}
    cd ${jdkinstallpath}
    chmod a+x ${jdkpackagename}
	tar -xvf ${jdkpackagename}
	rm ${jdkpackagename}
	
# Uncomment the following line to have Mozilla browsers (i.e. Firefox) load the Java 6 plugin
# ln -s ${brisskitbin}/java/${JDK_DIRECTORY_NAME}/jre/plugin/i386/ns7/libjavaplugin_oji.so ~/.mozilla/plugins

   infolog "jb2 Installing JBoss [${version}] jbossfunct"

    debuglog "jb3 Checking JBoss parent directory [${jbossroot}]"
    if [ ! -d "${jbossroot}" ]
    then
        debuglog "jb4 Creating JBoss parent directory [${jbossroot}]"
        mkdir -p "${jbossroot}"
    fi

    debuglog "jb5 Checking JBoss directory [${jbosspath}]"
    if [ ! -d "${jbosspath}" ]
    then
        debuglog "jb6 Installing JBoss [${version}]"
        installzip \
            "$(brisskitconfigget jboss ${version} source)" \
            "${jbossroot}"
    fi

    debuglog "jb7 Checking for JBoss [${version}] at [${jbosspath}]"
    if [ -d "${jbosspath}" ]
    then
        debuglog "jb8 Updating installed config"
        installedset 'jboss' 'version' "${version}"
        installedset 'jboss' 'path'    "${jbosspath}"
    else
        errorlog "jb9 Unable to locate JBoss [${version}] at [${jbosspath}]"
    fi


    }

#
# Install our init scipt.
jbossinstallinit()
    {

    local initname=jboss
    local initfile=${brisskitbin}/init.d/jboss

    infolog "jb10 Installing JBoss init.d script"

    chmod a+x   "${initfile}"
    installinit "${initname}" "${initfile}"

    infolog "jb11 Setting JBoss to start on boot"
    chkconfig jboss on

    infolog "jb12 Checking JBoss pid directory"
    jbosscheckwork /var/run/jboss
    
    }

#
# Install the JBoss user account.
jbossinstalluser()
    {
    local useruid=$(brisskitconfigget  'jboss'  'user' 'uid')
    local usergid=$(brisskitconfigget  'jboss'  'user' 'gid')
    local username=$(jbossuser)
    local userhome=$(jbossroot)
    local userdesc='JBoss user'

    infolog "jb13 Checking JBoss user account [${username}]"

    servicegroup \
        "${usergid}"  \
        "${username}"

    serviceaccount \
        "${useruid}" \
        "${usergid}" \
        "${username}" \
        "${userhome}" \
        "${userdesc}"

    }

#
# Check a JBoss working directory.
jbosscheckwork()
    {
    local target=$1
    infolog "jb14 Checking JBoss directory [${target}]"
    #
    # If missing, then create the directory.
    if [ ! -d "${target}" ]
    then
        debuglog "jb15 Creating JBoss directory [${target}]"
        mkdir "${target}"
    fi
    #
    # Check the access permissions.
    local uid=$(brisskitconfigget 'jboss'  'user' 'uid')
    local gid=$(brisskitconfigget 'jboss'  'user' 'gid')

    if [ -d "${target}" ]
    then
        debuglog "jb16 Updating permissions on [${target}]"
        chown -R "${uid}" "${target}"
        chgrp -R "${gid}" "${target}"
        chmod -R g+w "${target}"
        chmod -R u+w "${target}"
        chmod g+s    "${target}"
        chmod u+s    "${target}"
    fi

    }

#
# Update permissions for the working directories.
jbossinstallwork()
    {
    local confdir=$(jbossconfdir)

    jbosscheckwork ${confdir}/tmp
    jbosscheckwork ${confdir}/log
    jbosscheckwork ${confdir}/work
    jbosscheckwork ${confdir}/data

    }

#
# Create the config script used by the JBoss init script.
jbossinstallconf()
    {
    local target=/etc/jboss/jboss.conf
    local parent=$(dirname "${target}")

    infolog "jb17 Checking JBoss config script"

    debuglog "jb18 Checking JBoss config directory [${parent}]"
    if [ ! -d "${parent}" ]
    then
        debuglog "jb19 Creating JBoss config directory [${parent}]"
        mkdir "${parent}"
    fi

    debuglog "jb20 Checking JBoss config file [${target}]"
    if [ -e "${target}" ]
    then
        debuglog "jb21 Found existing JBoss config, skipping."
    else

cat > ${target} << EOF
#!/bin/bash
#
# JBoss config file, created by brisskit install script.
# $(date)

#
# JBoss path.
export JBOSS_HOME=$(jbosspath)

#
# JBoss user account.
export JBOSS_USER=$(jbossuser)

#
# JBoss configuration.
export JBOSS_CONF=$(jbossconf)

#
# JBoss bind interface.
export JBOSS_BIND=$(brisskitconfigget 'jboss' 'config' 'bind')

#
# Admin access
#JBOSS_ADMIN_USER
#JBOSS_ADMIN_PASS

#
# Java path.
#export JAVA_HOME=$(javapath)

#
# Java options.
#JAVA_OPTS

EOF
    fi
    }

#
# Fix the jmx-console security-constraint.
# http://trac.brisskit.org.uk/ticket/36
jboss20111328143530()
    {
    infolog "jb22 Patching JBoss jmx-console security-constraint"
    #
    # Patch the MySQL config file.
    applypatch "$(jbosspath)/server/default/deploy/jmx-console.war/WEB-INF/web.xml" brisskit-20111328-143530
    }

#########################################
# Control functions.
#

#
# Start the JBoss service.
jbossstart()
    {
    infolog "jb23 Starting JBoss"
    service jboss start
    }

#
# Start the JBoss service.
jbossstop()
    {
    infolog "jb24 Stopping JBoss"
    service jboss stop
    }


