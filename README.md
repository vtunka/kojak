Kojak - "Koji in an box"
========================

Kojak is a Koji virtual appliance complete with Mead extensions.  It is part of a productization effort to encourage the
adoption of the Kojak/Mead build system.  The scripts included in this repository create a fully operational Koji/Mead
virtual machine.  They utilize the Libvirtd visualization API and a kickstart file, based on a vanilla
Fedora installation, to provide an automated "out of the box" solution, which may be used for development and
educational purposes.

Minimum System Requirements
---------------------------

Currently Kojak requires an updated Fedora 18 installation installed with the packages in the @virtualization rpm 
package group. See http://fedoraproject.org/wiki/Getting_started_with_virtualization for more information. 

The virtual appliance is configured with he following default specifications:

1. 4GB RAM
2. 50 GB Disk Space
3. IP Address 192.168.122.2

Installation Instructions
------------------------

1.  Check and modify the env_vars.sh, vm_create.sh and kojak_ks.cfg to suit your particular environment.
2.  Execute install.sh to create the Kojak virtual appliance.  The script requires root privileges to run successfully. 
3.  Copy over the schema.sql and users.sql to the /tmp dir on the virtual appliance.
4.  Execute the post_install.sh script under /root to complete the configuration.

Configuration Notes
-------------------

The Kojak virtual appliance is configured with a set of default options.  These can be easily modified by editing either
the variables in env_var.sh, for directory locations, iso images and associated configuration files, or create_vm.sh for
virtual machine resources allocations (Mem, CPU and Storage etc).  The appliance is configured with with a static ip
address taken from the pool of ip addresses from the "default" network that is configured with libvirt.

You can access the appliance via ssh at 192.168.122.2 using the following credentials:

username: root
password: root

Currently Kojak uses SSL certificates as the preferred method of authentication. To utilize the client certificate for
browser based logins you will need to import the certificate. The certificate is can be accessed from /home/koji/.koji.
Certificates are created for a default set of users which includes koji, kojiadmin, kojira and 3 kojibuilders.

Known Issues
------------

14/06/2013

This installation ships with a patched version of schema.sql with resolves a number of database schema issues.  The
issue is resolved as of version 1.8.0 and Kojak will be updated accordingly once the packages are made available for 
general consumption.

