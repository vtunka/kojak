Kojak - Koji in a box
=====================

Kojak is a Koji virtual appliance complete with Mead extentions.  It is part of a productisation effort to encourage the
adoption of the Koji/Mead build system.  The scripts included in this repository create a fully operational Koji/Mead
virtual machine.  They utilise the Libvirtd virtualization API and a kickstart file, based on a vanilla 
Fedora installation, which provide an automated "out of the box" solution, which may be used for developement and 
educational purposes.

Installation Intructions
========================

1.  Check and modify the env_vars.sh to suit your particular environment.
2.  Execute install.sh to create the Kojak virtual appliance.
3.  Copy over the schema.sql and users.sql to the /tmp dir on the virtual appliance.
4.  Execute the post_install.sh script under /root to complete the configuration.

Configuration Notes
===================

The virtual appliance is configured with a static ip address taken from the pool of ip addresses of the "default" network.
You can access the appliance via ssh at 192.168.122.2.

Currently Kojak uses SSL certificates as the preffered method of authentication.

Known Issues
============

This installation ships with a patched version of schema.sql with resolves a number of issues database schmea issues.
