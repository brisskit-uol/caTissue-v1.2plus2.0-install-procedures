#!/bin/bash
# Shell script functions to install system packages.
#
# Based on code developed by Wizzard Solutions Ltd.
# Original code was licensed under the GNU General Public License version 3.
#

#########################################
# Config functions.
#

installedget()
    {
    local group=$1
    local field=$2
    brisskitconfigget 'installed' "${group}" "${field}"
    }

installedset()
    {
    local group=$1
    local field=$2
    local value=$3
    brisskitconfigset 'installed' "${group}" "${field}" "${value}"
    }

#########################################
# Download functions.
#

#
# Get the path for a downloaded file.
downloadpath()
    {
    local filename=$1
    echo "${brisskittmp}/downloads/${filename}"
    }

#
# Download a file.
downloadfile()
    {
    local source=$1
    local target=$(basename ${source})
    infolog "Downloading file [${target}]"

    #
    # Create our temp directory.
    debuglog "Checking brisskit temp directory [${brisskittmp}]"
    if [ ! -d "${brisskittmp}" ]
    then
        debuglog "Creating brisskit temp directory [${brisskittmp}]"
        mkdir -p "${brisskittmp}"
    fi

    #
    # Create our temp directory.
    debuglog "Checking brisskit downloads directory [${brisskittmp}/downloads]"
    if [ ! -d "${brisskittmp}/downloads" ]
    then
        debuglog "Creating brisskit temp directory [${brisskittmp}/downloads]"
        mkdir -p "${brisskittmp}/downloads"
    fi

    #
    # Download the file.
    debuglog "Checking download file [${target}]"
    if [ ! -f "${brisskittmp}/downloads/${target}" ]
    then
        debuglog "Downloading [${target}] from [${source}]"
        cp "${source}" "${brisskittmp}/downloads/"
    fi
    }

#########################################
# Install functions.
#

#
# Install one or more system packages.
installpackage()
    {
    local package=$1
#    infolog "Checking system package [${package}]"
#TODO Need to handle space separated list of packages.
#    local version=$(deb --query --all --queryformat '%{VERSION}' "${package}" 2> /dev/null)
#    if [ -n "${version}" ]
#    then
#        infolog "Package [${package}][${version}] is installed"
#    else
#        infolog "Installing [${package}]"
#        apt-get -y install ${package}
#    fi
    infolog "Installing system packages [${package}]"
    apt-get -y --force-yes install ${package}
    }

#
# Install a deb package.
#TODO Add a check to see if is already installed.
installdeb()
    {
    local source=$1
    local filename=$(basename ${source})
    infolog "Installing DEB file [${filename}]"

    debuglog "Checking for DEB file [${filename}]"
    filepath=$(downloadpath "${filename}")
    if [ ! -e "${filepath}" ]
    then
        downloadfile "${source}"
    fi

    debuglog "Installing DEB file [${filename}]"
    if [ ! -e "${filepath}" ]
    then
        errorlog "Can't find DEB file [${filename}] at [${filepath}]"
    else

#
# Compare installed and target versions ...
local packagename=$(deb --query --package ${filepath} --queryformat '%{NAME}')
local packageversion=$(deb --query --package ${filepath} --queryformat '%{VERSION}')
local currentversion=$(deb --query --all --queryformat '%{VERSION}' "${packagename}")

        debuglog "Package name    [${packagename}]"
        debuglog "Package version [${packageversion}]"
        debuglog "Current version [${currentversion}]"

        apt-get -y --force-yes install "${filepath}"
    fi
    }

#
# Install a zip package.
installzip()
    {
    local source=$1
    local target=$2
    local filename=$(basename ${source})
    infolog "Installing ZIP file [${filename}]"

    debuglog "Checking ZIP file [${filename}]"
    filepath=$(downloadpath "${filename}")
    if [ ! -e "${filepath}" ]
    then
        downloadfile "${source}"
    fi

    debuglog "Unpacking ZIP file [${filename}]"
    if [ ! -e "${filepath}" ]
    then
        errorlog "Can't find ZIP file [${filename}] at [${filepath}]"
    else
        debuglog "Unpacking ZIP zipfile [${filename}] to [${target}]"
        unzip -q -d "${target}" "${filepath}"
    fi
    }

#
# Apply a brisskit patch.
# The patch MUST add the patchname to the target.
# This function checks the target file for a line containing the patch name,
# and only applies the patch if it isn't found.
# TODO Check the return code from patch to check it worked.
applypatch()
    {
    local target=$1
    local patchname=$2
#    local patchfile=${brisskitbin}/patch/${patchname}.patch
    local patchfile=${CATISSUE_INSTALL_PROCS_HOME}/patch/${patchname}.patch
    local result=0 

    infolog  "Applying patch [${patchname}]"
    debuglog "Checking [${target}] for patch [${patchname}]"
    if [ $(grep --count "${patchname}" "${target}") -ne 0 ]
    then
        debuglog "[${patchname}] already applied"
        return 1
    else
        debuglog "[${patchname}] not applied yet"
        infolog "Patching [${target}] with patch [${patchname}]"
        patch -s "${target}" "${patchfile}"
        return 0
    fi
    }


#
# Install an init.d script.
installinit()
    {
    local initname=$1
    local initfile=$2
    local initpath="/etc/init.d"

    infolog "Checking init.d script for [${initname}]"
    if [ ! -e "${initpath}/${initname}" ]
    then
        infolog "Linking init.d script for [${initname}]"
        ln -s "${initfile}" "${initpath}/${initname}"
    fi

    if [ ! -e "${initpath}/${initname}" ]
    then
        errorlog "Missing init.d script for [${initname}]"
    else
        infolog "Installing init.d script for [${initname}]"
        #
        # Use initd installer if it exists. 
        if [ -x /usr/lib/lsb/install_initd ]
        then
            debuglog "Installing [${initname}] init script using initd installer"
            /usr/lib/lsb/install_initd "${initpath}/${initname}"
        #
        # Use chkconfig if it exists. 
        elif [ -x /sbin/chkconfig ]
        then
            debuglog "Installing [${initname}] init script using chkconfig"
            /sbin/chkconfig --add "${initname}"
        #
        # Add symlinks manually. 
        else
            debuglog "Installing [${initname}] init script using symlinks"
#            for i in 2 3 4 5
#            do
#                ln -sf "${initpath}/${initname}" "/etc/rc.d/rc${i}.d/S90${initname}"
#            done
#            for i in 1 6
#            do
#                ln -sf "${initpath}/${initname}" "/etc/rc.d/rc${i}.d/K10${initname}"
#            done
        fi

    fi
    }

