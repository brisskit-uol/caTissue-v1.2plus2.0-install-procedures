#!/bin/bash
# Shell script functions to install and configure user accounts.
#
# Based on code developed by Wizzard Solutions Ltd.
# Original code was licensed under the GNU General Public License version 3.
#

#########################################
# User accounts.
#

#
# Get the user ID for a Unix account.
useruid() {
    local name=$1
    local uid=$(id -u ${name} 2> /dev/null)
    if [ $? -eq 0 ]
    then
        echo ${uid}
    fi
    }

#
# Get the primary group ID for a Unix account.
usergid() {
    local name=$1
    local gid=$(id -g ${name} 2> /dev/null)
    if [ $? -eq 0 ]
    then
        echo ${gid}
    fi
    }

#
# Get the primary group name for a Unix account.
usergroup() {
    local name=$1
    local gid=$(id -g -n ${name} 2> /dev/null)
    if [ $? -eq 0 ]
    then
        echo ${gid}
    fi
    }

#
# Get the home directory for a Unix account.
userhome()
    {
    local name=$1
    local home=$(finger -m -p ${name} 2> /dev/null | sed -e '/^Directory/!d' -e 's/Directory: *//' -e 's/ *\t.*//g')
    if [ $? -eq 0 ]
    then
        echo ${home}
    fi
    }

#
# Get the group ID for a unix group.
# Note: this only works for local groups.
groupgid() {
    local group=$1
    sed -n '
        s|^'"${group}"':x:\([^:]\{1,\}\):\(.*\)$|\1|p
        ' /etc/group
    }

#
# Check a user account, create if required.
useraccount() {
    local useruid=$1
    local username=$2
    local usercomment=${3:-''}
    infolog "Checking user account [${username}][${useruid}]"
    #
    # Check for an empty uid.
    if [ -z "${useruid}" ]
    then
        errorlog "Account UID required"
        return 1
    fi
    #
    # Check for an empty name.
    if [ -z "${username}" ]
    then
        errorlog "Account name required"
        return 1
    fi
    #
    # Check if the user account exists.
    local before=`useruid ${username}`
    if [ -n "${before}" ]
    then
        debuglog "Found user account [${username}][${useruid}]"
        #
        # Check the identifiers match.
        if [ "${before}" != ${useruid} ] 
        then
            errorlog "User identifiers don't match [${username}][${useruid}][${before}]"
            return 2
        fi
    #
    # If the user account doesn't exist yet.
    else
        #
        # Check for an empty comment.
        if [ -z "${usercomment}" ]
        then
            usercomment=${username}
        fi
        #
        # Create the user account.
        infolog "Creating user account [${username}][${useruid}]"
        /usr/sbin/useradd  \
            --create-home \
            --uid "${useruid}" \
            --groups users \
            --comment "${usercomment}" \
            "${username}"
        #
        # Check it worked.
        local after=`useruid ${username}`
        if [ -n "${after}" ]
        then
            debuglog "Created user account [${username}][${after}]"
            #
            # Check the identifiers match.
            if [ "${after}" != "${useruid}" ] 
            then
                errorlog "User identifiers don't match [${username}][${useruid}][${after}]"
                return 2
            fi
        #
        # If it didn't work.
        else
            errorlog "Failed to create user account [${username}][${useruid}]"
            return 3
        fi
    fi
    }

#
# Create a group for a service.
servicegroup() {
    local groupgid=$1
    local groupname=$2

    infolog "Checking group [${groupname}][${groupgid}]"
    if [ -z $(groupgid ${groupname}) ]
    then
        infolog "Creating group [${groupname}][${groupgid}]"
        groupadd \
            -g "${groupgid}" \
            "${groupname}"
    else
        if [ $(groupgid ${groupname}) != ${groupgid} ]
        then
            errorlog "Existing group has wrong GID [${groupname}][$(groupgid ${svngroup})][${groupgid}]"
        fi
    fi

    }

#
# Create an account for a service.
# This expects the home directory to already exist.
serviceaccount() {
    local accountuid=$1
    local accountgid=$2
    local accountname=$3
    local accounthome=$4
    local accountdesc=${6:-${accountname}}

    #
    # Check for empty fields.
    # uid
    # gid
    # name
    # home
    # comment

    infolog "Checking account [${accountname}][${accountuid}][${accountgid}]"
    if [ -z $(useruid ${accountname}) ]
    then
        infolog "Creating account [${accountname}][${accountuid}][${accountgid}]"
        useradd \
            -M -n -r \
            --uid    "${accountuid}" \
            --gid    "${accountgid}" \
            --home "${accounthome}" \
            --comment "${accountdesc}" \
            "${accountname}"
    else
        if [ $(useruid ${accountname}) != ${accountuid} ]
        then
            errorlog "Existing account has the wrong UID [${accountname}][$(useruid ${accountname})][${accountuid}]"
        fi
        if [ $(usergid ${accountname}) != ${accountgid} ]
        then
            errorlog "Existing account has the wrong GID [${accountname}][$(usergid ${accountname})][${accountgid}]"
        fi
    fi
    }


#
# This function replicates usermod -a (append) on Suze.
usergroupadd()
    {
    local username=$1
    local groupname=$2
    #
    # Check for an empty name.
    if [ -z "${username}" ]
    then
        errorlog "Account identifier required"
        return 1
    fi
    #
    # Check for an empty group.
    if [ -z "${groupname}" ]
    then
        errorlog "Group name required"
        return 1
    fi

#
# TODO Check the group exists.

#
# BUG Fails with 'unknown group' if the user isn't in any extra groups.
# (updated starts with a comma ',')

    infolog "Checking user [${username}] is in group [${groupname}]"
    #
    # Get the current list groups.
    local current=$(id --groups --name ${username})
    #
    # Check if the group name is already in the list.
    if [ $(echo "${current}" | grep -c "\\<${groupname}\\>") -eq 0 ]
    then
        infolog "Adding user [${username}] to group [${groupname}]"
        local first=$(id --group  --name ${username})
        local extra=$(id --groups --name ${username} | sed 's/\<'${first}'\> *//' | sed 's/ /,/g')
        local updated="${extra},${groupname}"
        usermod --groups "${updated}" "${username}"
    fi
    }

#########################################
# SSH keys.
#

#
# Install a USER ssh key.
sshuserkey()
    {
    local username=${1:-''}
    local keyhref=${2:-''}

    #
    # Check for an empty user name.
    if [ -z "${username}" ]
    then
        errorlog "Account name required"
        return 1
    fi
    #
    # Check for an empty key href.
    if [ -z "${keyhref}" ]
    then
        errorlog "SSH key location required"
        return 1
    fi

    #
    # Check the user exists.
    local userident=$(useruid ${username})
    if [ -z "${userident}" ]
    then
        errorlog "Unknown user [${username}]"
        return 1
    fi

    #
    # Get the users primary group.
    usergroup=$(usergroup ${username})

    debuglog "Found user ident [${username}][${userident}]"

    local userhome=$(userhome ${username})
    local keyname=$(basename ${keyhref})

    infolog "Checking user ssh key [${username}][${keyname}]"

    #
    # Check the home directory exists.
    debuglog "Checking home directory [${userhome}]"
    if [ -z "${userhome}" ]
    then
        errorlog "Home directory is not set [${username}]"
        return 1
    fi
    if [ ! -d "${userhome}" ]
    then
        errorlog "Unable to find home directory [${username}][${userhome}]"
        return 1
    fi

    debuglog "Checking ssh directory [${userhome}/.ssh]"
    if [ ! -d "${userhome}/.ssh" ]
    then
        debuglog "Creating ssh directory [${userhome}/.ssh]"
        mkdir "${userhome}/.ssh"
        chown "${username}"  "${userhome}/.ssh"
        chgrp "${usergroup}" "${userhome}/.ssh"
        chmod u=rwx,g=,o=    "${userhome}/.ssh"
        if selinuxtest
        then
            debuglog "Running restorecon on ssh directory [${userhome}/.ssh]"
            restorecon "${userhome}/.ssh"
        fi
    fi

    #
    # Check if the key is already in place.
    # This assumes that if the key file is here then it has been added to authorized_keys.
#TODO Use grep to check if key is in place.
    debuglog "Checking ssh key [${keyname}]"
    if [ -f "${userhome}/.ssh/users/${keyname}" ]
    then
        debuglog "Found ssh key [${keyname}]"
    else
        debuglog "Checking ssh users directory"
        if [ ! -d "${userhome}/.ssh/users" ]
        then
            debuglog "Creating ssh users directory"
            mkdir "${userhome}/.ssh/users"
        fi
        #
        # Download and install the ssh key.
        infolog "Downloading ssh key [${keyhref}]"
        wget -q -P "${userhome}/.ssh/users" "${keyhref}"
        if [ $? -ne 0 ]
        then
            errorlog "Failed to download ssh key [${keyhref}]"
            return 1
        fi
        if [ ! -f "${userhome}/.ssh/users/${keyname}" ]
        then
            errorlog "Failed to find ssh key [${keyname}]"
            return 1
        fi
        if [ ! -s "${userhome}/.ssh/users/${keyname}" ]
        then
            errorlog "Zero size ssh key [${keyname}]"
            return 1
        fi
        #
        # Add the key to authorized_keys
        infolog "Installing ssh key [${keyname}]"
        cat "${userhome}/.ssh/users/${keyname}" >> "${userhome}/.ssh/authorized_keys2"

        debuglog "Setting permissions"
        chown "${username}"  "${userhome}/.ssh/users/${keyname}"
        chgrp "${usergroup}" "${userhome}/.ssh/users/${keyname}"
        chmod u=rwx,g=,o=    "${userhome}/.ssh/users/${keyname}"

        chown "${username}"  "${userhome}/.ssh/authorized_keys2"
        chgrp "${usergroup}" "${userhome}/.ssh/authorized_keys2"
        chmod u=rwx,g=r,o=r  "${userhome}/.ssh/authorized_keys2"
        if selinuxtest
        then
            debuglog "Running restorecon on ssh directory [${userhome}/.ssh/*]"
            restorecon "${userhome}/.ssh/*"
        fi
    fi

    }

#########################################
# Standard BRICCS accounts.
#

#
# Create the BRICCS user accounts.
briccsusers()
    {
    infolog "Checking BRICCS user accounts"
    useraccount '4125'   'jl99'  'Jeff Lusted'
    useraccount '4126'   'nrh11' 'Nick Holden'
    useraccount '4127'   'vs114' 'Vasil Stezhka'
    useraccount '4134'   'dm241' 'Dave Morris'


    infolog "Checking user ssh keys"
    sshuserkey 'dm241' 'http://data.briccs.org.uk/sshkeys/dave.briccs.org.uk.pub'
    sshuserkey 'jl99'  'http://data.briccs.org.uk/sshkeys/jeff.briccs.org.uk.pub'
    sshuserkey 'nrh11' 'http://data.briccs.org.uk/sshkeys/nick.briccs.org.uk.pub'
    sshuserkey 'nrh11' 'http://data.briccs.org.uk/sshkeys/nick.laptop.pub'

    infolog "Checking root ssh keys"
    sshuserkey 'root' 'http://data.briccs.org.uk/sshkeys/dave.briccs.org.uk.pub'
    sshuserkey 'root' 'http://data.briccs.org.uk/sshkeys/jeff.briccs.org.uk.pub'
    sshuserkey 'root' 'http://data.briccs.org.uk/sshkeys/nick.briccs.org.uk.pub'

    }
    
    




