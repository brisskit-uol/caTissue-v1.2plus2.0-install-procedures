#!/bin/bash
#
# Sets basic environment variables for catissue
# 
# Invocation within another sh script should be:
# source $CATISSUE_INSTALL_PROCS_HOME/bin/common/setenv.sh
#
#-------------------------------------------------------------------
if [ -z $CATISSUE_INSTALL_DEFAULTS_DEFINED ]
then
	export CATISSUE_INSTALL_DEFAULTS_DEFINED=true	
	source $CATISSUE_INSTALL_PROCS_HOME/config/defaults.sh	
fi


