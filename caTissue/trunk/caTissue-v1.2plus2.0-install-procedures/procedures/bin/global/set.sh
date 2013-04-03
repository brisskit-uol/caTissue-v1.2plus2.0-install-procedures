#!/bin/bash
#-----------------------------------------------------------------------------------------------------------
# Source this at the start of any shell session.
# (There should be no need to do this as sudo or root)
# Use "source ./set.sh" or ". ./set.sh" at the command line or within a composition script.
# Remember, if you execute any script as sudo, then you must inherit the environment variables; eg:
# > sudo -E ./install-catissue.sh 
#
# NOTES.
# (1) Edit setting for CATISSUE_INSTALL_DIRECTORY.
# (2) Edit setting for INSTALL_PACKAGE_NAME in order to pick up the correct version of the install procedures.
# (3) Edit setting for ADMIN_PACKAGE_NAME in order to pick up the correct version of the admin procedures.
#-----------------------------------------------------------------------------------------------------------
export CATISSUE_INSTALL_DIRECTORY=/var/local/brisskit/catissue
INSTALL_PACKAGE_NAME=catissue-1.2plus2.0-install-procedures-1.0-RC1
ADMIN_PACKAGE_NAME=catissue-admin-procedures-1.0-RC1
export CATISSUE_INSTALL_PROCS_HOME=$CATISSUE_INSTALL_DIRECTORY/$INSTALL_PACKAGE_NAME
export CATISSUE_ADMIN_PROCS_HOME=${CATISSUE_INSTALL_DIRECTORY}/${ADMIN_PACKAGE_NAME}