#!/usr/bin/python
# Python program to set a value in the brisskit config file.
# This file should be installed in /var/local/brisskit/system/bin
#
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
parser.add_argument('value')

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
# Function to set a property. 
def configset(filepath, block, field, value):

    config = ConfigParser.SafeConfigParser()

    if os.path.isfile(filepath):

        config.readfp(
            open(
                filepath
                )
            )

    if not config.has_section(
        block
        ):
        config.add_section(
            block
            )

    config.set(
        block,
        field,
        value,
        )

    output = open(
        filepath,
        'wb'
        )
    config.write(
        output
        )
    output.close

#
# Update the 'local' config.
result = configset(
    configfile(
        'local',
        inputs.config
        ),
    inputs.block,
    inputs.field,
    inputs.value
    )




