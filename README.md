Kojak - "Koji in an box"
========================

Kojak is a Koji virtual appliance complete with Mead extensions.  It is part of a productization effort to encourage the
adoption of the Kojak/Mead build system.  The scripts included in this repository create a fully operational Koji/Mead
virtual machine running on Fedora 18.  They utilize the Libvirtd visualization API and a kickstart file, based on a vanilla
Fedora installation, to provide an automated "out of the box" solution, which may be used for development and
educational purposes.

For more information about Koji see http://fedoraproject.org/wiki/Koji for more information.

Installation Prerequisites
---------------------------

This installation comprises of a virtual appliance server which is used to build and deploy the virtual appliance.  Kojak 
has been successfully installed and tested on Fedora 18 installed with the virtualization rpm package group. 

See http://fedoraproject.org/wiki/Getting_started_with_virtualization for more information

It is recommended that the system be updated before beginning the installation.  A fast internet connection and is also 
required in order to facilitate the downloading of any package dependancies.

Minimum System Requirements
--------------------------- 

The virtual appliance is configured with the following default specifications:

1. 4GB RAM
2. 32 GB Disk Space

The Virtual Appilance Server should be configured with the following minimum specifications:

1. Fedora 18 with virtualization package group
2. 8GB RAM
3. 120 GB Disk Space 

Installation Instructions
------------------------

1.  Check and modify the env_vars.sh, vm_create.sh and kojak_ks.cfg to suit your particular environment.
2.  Execute install.sh to create the Kojak virtual appliance.  The script requires root privileges to run. 
3.  Login and execute the post_install.sh script under /root to complete the configuration.

Configuration Notes
-------------------

The Kojak virtual appliance is configured with a set of default options.  These can be easily modified by editing the 
variables in install.sh.  Installation directories, iso location and virtual machine resources allocations
(Mem, CPU and Storage etc) can all be reconfigured as required.  The appliance is configured with with a static ipaddress 
taken from the pool of ip addresses from the "default" network that is configured with libvirt.

You can access the appliance via ssh at 192.168.122.2 using the following credentials:

username: root
password: root

Currently Kojak uses SSL certificates as the preferred method of authentication. To utilize the client certificate for
browser based logins you will need to import the certificate. The certificate is can be accessed from /home/koji/.koji.
Certificates are created for a default set of users which includes koji, kojiadmin, kojira and 3 kojibuilders.

Access to http://download.devel.redhat.com/ is required for the current version of Maven that is used.

Known Issues
------------

14/06/2013  - Fixed

This installation ships with a patched version of schema.sql with resolves a number of database schema issues.  The
issue is resolved as of version 1.8.0.1 and Kojak will be updated accordingly once the packages are made available for 
general consumption.

