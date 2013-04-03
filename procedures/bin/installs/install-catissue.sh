#!/bin/bash
#-----------------------------------------------------------------------------------------------
# Main driver procedure for installing caTissue
#
# Mandatory: the CATISSUE_INSTALL_PROCS_HOME environment variable to be set.
#
# Author: Jeff Lusted (jl99@leicester.ac.uk)
#-----------------------------------------------------------------------------------------------
source $CATISSUE_INSTALL_PROCS_HOME/bin/common/setenv.sh
source $CATISSUE_INSTALL_PROCS_HOME/bin/common/briccs-init.sh

#==================================================
# Install minor prerequisite packages.
# Acquire major software (jdk, JBoss, caTissue).
# Setup appropriate directories for install.
#==================================================
brisskitinit

#==================================================
# This bootstraps everything else and
# installs and deploys caTissue
#==================================================
catissueinstall