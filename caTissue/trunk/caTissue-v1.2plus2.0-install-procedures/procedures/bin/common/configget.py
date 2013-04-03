#!/usr/bin/python
# Python program to get a value in the brisskit config file.
# This file should be installed in /var/local/brisskit/system/bin
#
#! /usr/bin/env python
import os
import sys
import argparse
import ConfigParser

#
# Set the config file suffix.
suffix='.cfg'

#
# Parse our command line arguments.
parser = argparse.ArgumentParser(
    description='brisskit system config parser'
    )
parser.add_argument('config')
parser.add_argument('block')
parser.add_argument('field')

inputs = parser.parse_args()

#
# Get the global config path.
def configroot():

    if 'brisskitetc' in os.environ:
        return os.environ['brisskitetc']
    else:
        return '/etc/brisskit'

#
# Create a config file name.
def configfile(type, name):

    return os.path.join(
        configroot(),
        type,
        name + suffix
        )

#
# Function to get a property. 
def configget(filepath, block, field):

    if os.path.isfile(filepath):

        config = ConfigParser.SafeConfigParser()
        config.readfp(
            open(
                filepath
                )
            )

        if config.has_option(
            block,
            field
            ):

            return config.get(
                block,
                field
                )

#
# Check the 'local' config first.
result = configget(
    configfile(
        'local',
        inputs.config
        ),
    inputs.block,
    inputs.field
    )

#
# Check the 'global' config.
if not result:
    result = configget(
        configfile(
            'global',
            inputs.config
            ),
        inputs.block,
        inputs.field
        )

#
# Print our result.
if result:
    print os.path.expandvars(
        result
        )

