#!/bin/bash

# Install the required rpm binaries
yum -y install httpd mod_ssl postgresql-server mod_wsgi mock setarch rpm-build createrepo koji koji-builder koji-hub koji-hub-plugins koji-utils koji-vm koji-web

# Added the koji user and set the passwd
useradd koji
echo koji | passwd koji --stdin

# Create the koji server, component and user SSL certs
../make-koji-certs

# Initialise the postgresql database
postgresql-setup initdb

# Backup the original configuration and copy other the updated files over.
mv /etc/bashrc /etc/bashrc.orig && cp etc/bashrc /etc/bashrc
mv /etc/koji.conf /etc/koji.confi.orig && cp etc/koji.conf /etc/koji.conf
mv /etc/profile /etc/profile.orig && cp etc/profile /etc/profile
mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.orig && cp etc/http/conf/httpd.conf /etc/httpd/conf/httpd.conf
mv /etc/httpd/conf.d/kojihub.conf /etc/httpd/conf.d/kojihub.conf.orig && cp etc/http/conf.d/kojihub.conf /etc/httpd/conf.d/
mv /etc/httpd/conf.d/kojiweb.conf /etc/httpd/conf.d/kojiweb.conf.orig && cp etc/http/conf.d/kojiweb.conf /etc/httpd/conf.d/
mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.orig && cp etc/http/conf.d/ssl.conf /etc/httpd/conf.d/
mv /etc/koji-hub/hub.conf /etc/koji-hub/hub.conf.orig && cp etc/koji-hub/hub.conf /etc/koji-hub/hub.conf
mv /etc/kojid/kojid.conf /etc/kojid/kojid.conf.orig && cp etc/kojid/kojid.conf /etc/kojid/kojid.conf
mv /etc/kojira/kojira.conf /etc/kojira/kojira.conf.orig && cp etc/kojira/kojira.conf /etc/kojira/kojira.conf
mv /etc/kojiweb/web.conf /etc/kojiweb/web.conf.orig && cp etc/kojiweb/web.conf /etc/kojiweb/web.conf
mv /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf.orig && cp var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf
mv /var/lib/pgsql/data/postgresql.conf /var/lib/pgsql/data/postgresql.conf.orig && cp var/lib/pgsql/data/postgresql.conf /var/lib/pgsql/data/postgresql.conf
cat /etc/koji.conf > /home/koji/.koji/config
chown postgres:postgres /var/lib/pgsql/data/pg_hba.conf
chown postgres:postgres /var/lib/pgsql/data/postgresql.conf
chown koji:apache /home/koji/.koji/config

# Bring the datatbase up
chkconfig postgresql on
service postgresql start

# Create the koji table spaces
su - postgres
createuser koji
createdb -O koji koji
logout
su - koji
psql koji koji < /usr/share/doc/koji*/docs/schema.sql
insert into users (name, status, usertype) values ('kojiadmin', 0, 0);
insert into user_perms (user_id, perm_id, creator_id) values (1, 1, 1);
/q

# Create koji build directories
cd /mnt
mkdir koji
cd koji
mkdir {packages,repos,work,scratch}
chown apache.apache /mnt/koji
cd -

# Disable firewall
systemctl disable firewalld.service
systemctl stop firewalld.service
systemctl disable iptables.service
systemctl stop iptables.service
systemctl disable ip6tables.service
systemctl stop ip6tables.service

