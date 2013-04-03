#!/bin/bash
# Shell script functions to configure system settings.
#
# Based on code developed by Wizzard Solutions Ltd.
# Original code was licensed under the GNU General Public License version 3.
#

#########################################
# SELinux functions.
#

#
# Check if SELinux is enabled.
selinuxtest()
    {
    which selinuxenabled &> /dev/null && selinuxenabled
    }

#
# Resote SELinux permissions.
selinuxrestore()
    {
    local target=$1
    if $(which restorecon &> /dev/null)
    then
        restorecon "${target}"
    fi
    }

#########################################
# Operating system detection.
#

#
# Simple stub for now.
ostype() {
    echo "redhat"
    }

#########################################
# Network functions.
#

#
# Detect our external IP address.
ethaddress()
    {

    #
    # Using DNS
    #echo $(host $(hostname) | sed 's/.* address \([0-9.]*\)$/\1/')
    
    #
    # Using ifconfig
    echo $(ifconfig eth0 | sed -n 's/ *inet addr:\([0-9.]*\) .*/\1/p')

    }

#########################################
# Password functions.

#
# Create a semi-random password.
# Based on a suggestion in the comments section on this page.
# http://www.osix.net/modules/article/?id=570 
randompass()
    {
    local size=${1:-'20'}
    tr -dc '[:alnum:]' < /dev/urandom | fold -w "${size}" | head -n 1
    }



#########################################
# Database URL functions.
# Note: We need to handle userpass and hostport as separate patterns because sed regular expressions only support nine bracketed groups. 
# type://username:password@host:port/database
# TODO Move these to a separate file for generic database functions.

#
# Create a database URL from params.
makedburl()
    {
    local type=$1
    local name=$2
    local user=${3:-''}
    local pass=${4:-''}
    local host=${5:-''}
    local port=${6:-''}
    local userpass=''
    local hostport=''

    if [ -n "${user}" ]
    then
        if [ -n "${pass}" ]
        then
            userpass="${user}:${pass}@"
        else
            userpass="${user}@"
        fi
    fi

    if [ -n "${host}" ]
    then
        if [ -n "${port}" ]
        then
            hostport="${host}:${port}/"
        else
            hostport="${host}/"
        fi
    fi

    echo "${type}://${userpass}${hostport}${name}"
    
    }

#
# Regular expressions for parsing a database URL.
dburlpattern='\(\(.*\)://\)\{0,1\}\(\(\(.*\)\)@\)\{0,1\}\(\(\([^/]*\)/\{1,\}\)\{0,1\}\(.*\)\)'
dburlhostport='\([^:]*\)\(:\(.*\)\)\{0,1\}'
dburluserpass='\([^:]*\)\(:\(.*\)\)\{0,1\}'

#
# Split a database URL into its component parts.
parsedburl()
    {    
    echo $1 | sed '
        s|^'"${dburlpattern}"'$|type[\2] userpass[\5] hostport[\8] name[\9]|
        '
    }

#
# Get the database type from a URL.
parsedbtype()
    {    
    echo $1 | sed -n '
        s|^'"${dburlpattern}"'$|\2|p
        '
    }

#
# Get the database name from a URL.
parsedbname()
    {    
    echo $1 | sed -n '
        s|^'"${dburlpattern}"'$|\9|p
        '
    }

#
# Get the database host and port number from a URL.
parsedbhostport()
    {    
    echo $1 | sed -n '
        s|^'"${dburlpattern}"'$|\8|p
        '
    }

#
# Get the database host from a URL.
parsedbhost()
    {    
    echo $1 \
    | sed -n '
        s|^'"${dburlpattern}"'$|\8|p
        ' \
    | sed -n '
        s|^'"${dburlhostport}"'$|\1|p
        '
    }

#
# Get the database port from a URL.
parsedbport()
    {    
    echo $1 \
    | sed -n '
        s|^'"${dburlpattern}"'$|\8|p
        ' \
    | sed -n '
        s|^'"${dburlhostport}"'$|\3|p
        '
    }

#
# Get the username and password from a URL.
parsedbuserpass()
    {
    echo $1 \
    | sed -n '
        s|^'"${dburlpattern}"'$|\5|p
        '
    }

#
# Get the username from a URL.
parsedbuser()
    {
    echo $1 \
    | sed -n '
        s|^'"${dburlpattern}"'$|\5|p
        ' \
    | sed -n '
        s|^'"${dburluserpass}"'$|\1|p
        '
    }

#
# Get the password from a URL.
parsedbpass()
    {
    echo $1 \
    | sed -n '
        s|^'"${dburlpattern}"'$|\5|p
        ' \
    | sed -n '
        s|^'"${dburluserpass}"'$|\3|p
        '
    }

#########################################
# Firewall functions.

#
# Disable unused netbios rules.
# Note: This is specific to RedHat/CentOS.
iptablesunused()
    {
    #
    # Remove modules for unused services. 
    sed -i '
        s/ip_conntrack_netbios_ns//
        ' /etc/sysconfig/iptables-config
    #
    # Remove ports for unused services. 
    sed -i '
        /-p 50/d
        /-p 51/d
        /--dport 631/d
        /--dport 5353/d
        ' /etc/sysconfig/iptables
    #
    # Restart the service.
    service iptables restart
    }

#
# Add a simple iptables accept rule.
# Note:  This is specific to RedHat/CentOS.
# Param: The port number to accept, e.g. 80 or 8080. 
iptablesaccept()
    {
    local port=$1
    #
    # Add an accept rule for port 80, 
    if [ $(grep --count -e "--dport ${port}" "/etc/sysconfig/iptables") -ne 0 ]
    then
        echo "Port [${port}] already enabled"
    else
        echo "Adding accept rule for port [${port}]"
        sed -i '
            /icmp-host-prohibited/ i\
-A RH-Firewall-1-INPUT -m state --state NEW -m tcp -p tcp --dport '"${port}"' -j ACCEPT
            ' /etc/sysconfig/iptables
    fi
    #
    # Restart the service.
    service iptables restart
    }



