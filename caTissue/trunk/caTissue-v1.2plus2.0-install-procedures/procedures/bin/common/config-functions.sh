#!/bin/bash
# Functions for controlling config settings.
# This file should be installed in /var/local/brisskit/system/bin
#
#

#########################################
# Check our global paths are set.
#
set +o nounset
if [ -z ${brisskitetc} ]
then
    echo "ERROR : Need to set brisskit global paths"
fi
if [ -z ${brisskitbin} ]
then
    echo "ERROR : Need to set brisskit global paths"
fi
set -o nounset

#
# Create the brisskit config file.
brisskitconfiginit()
    {

    infolog "Installing config tools"
    apt-get -y --force-yes install python python-argparse

    infolog "Checking config directories"
    infolog "Checking [${brisskitetc}]"
    if [ ! -d ${brisskitetc} ]
    then
        infolog "Creating [${brisskitetc}]"
        mkdir ${brisskitetc}
    fi

    infolog "Checking [${brisskitetc}/global]"
    if [ ! -d ${brisskitetc}/global ]
    then
        infolog "Creating [${brisskitetc}/global]"
        mkdir ${brisskitetc}/global
    fi

    infolog "Checking [${brisskitetc}/local]"
    if [ ! -d ${brisskitetc}/local ]
    then
        infolog "Creating [${brisskitetc}/local]"
        mkdir ${brisskitetc}/local
    fi

    }

#
# Get a brisskit config value.
# Calls a Python program to read the ini file(s).
# Params
#   config file name (without suffix)
#   config block name
#   config field name
brisskitconfigget()
    {
    ${brisskitbin}/configget.py $1 $2 $3
    }

#
# Set a brisskit config value.
# Calls a Python program to read the ini file(s).
# Params
#   config file name (without suffix)
#   config block name
#   config field name
#   config value
brisskitconfigset()
    {
    ${brisskitbin}/configset.py $1 $2 $3 $4
    }


