#!/bin/bash
#
# Simple script to automate the installtion of the Koji build system.

# Install Koji dependencies & platform binaries
yum -y install httpd mod_ssl openssl postgresql-server mod_wsgi yum-utils mock \
rpm-build createrepo git pyOpenSSL python-krbV python-cheetah cvs svn \
postgresql-python python-qpid libvirt-python python-virtinst qemu-img \
mod_auth_kerb wget htop iftop screen vim tree links dos2unix maven mlocate \
java-1.7.0-openjdk-devel python-virtinst virt-install python-pudb.noarch

# Configure Java version
alternatives --remove java /usr/lib/jvm/java-1.7.0-openjdk-1.7.0.60-2.4.3.0.fc19.x86_64/jre/bin/java
alternatives --install /usr/bin/java java /usr/lib/jvm/java-1.7.0-openjdk-1.7.0.60-2.4.3.0.fc19.x86_64/bin/java 0

# Install Jenkins
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key
yum install jenkins
systemctl enable jenkins.service

# Install Koji from latest sources
wget http://download.devel.redhat.com/rel-eng/brew/fedora/19/brew.repo -P /etc/yum.repos.d
cd /tmp
git clone git://git.fedorahosted.org/koji
cd koji/
make rpm
rpm -Uvh --force --nodeps noarch/*
cd -

# Create Koji user and SSL directories
useradd koji
echo koji | passwd koji --stdin
mkdir -p /home/koji/.koji
chown koji:apache /home/koji/.koji
mkdir -p /etc/pki/koji
cd /etc/pki/koji
mkdir {certs,confs,private}
touch /etc/pki/CA/index.txt
echo 01 > /etc/pki/CA/serial
cd -

# Create koji build directories
mkdir /mnt/koji
cd /mnt/koji
mkdir {packages,repos,work,scratch}
chown apache.apache *
cd -

## Create custom config files

# /etc/profile.d/custom.sh
cat > /etc/profile.d/custom.sh << 'EOF'
# Prompt colors
if [ `whoami` != "root" ]; then
    export PS1='\[\e[0;32m\][\u@\h \W]\$ '
else
    export PS1='\[\e[0;31m\][\u@\h \W]\$ '
fi

# Aliases
alias m='less /var/log/messages'
alias h='history'
alias vi='vim'
alias tasks='koji list-tasks'

# Configure bash history 
HISTSIZE='1000000'
HISTIGNORE=' *:&:?:??'
HISTCONTROL='ignoreboth:erasedups'

export HISTSIZE HISTIGNORE HISTCONTROL

# Turn on bash history options
shopt -s histappend histreedit histverify

# Sync term history
history() {
  history_sync
  builtin history "$@"
}

history_sync() {
  builtin history -a         
  HISTFILESIZE=$HISTSIZE     
  builtin history -c         
  builtin history -r         
}

PROMPT_COMMAND=history_sync
EOF

# /etc/hosts
cp -p /etc/hosts /etc/hosts.orig
cat > /etc/hosts << 'EOF'
27.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.122.2	koji koji.localdomain
EOF

# /etc/vimrc
cp -p /etc/vimrc /etc/vimrc.orig
cat >> /etc/vimrc << 'EOF'

set paste
set tabstop=4
set shiftwidth=4
set softtabstop=4
set smarttab
set expandtab

EOF

# /etc/security/limits.conf
cp -p /etc/security/limits.conf /etc/security/limits.conf.orig
cat > /etc/security/limits.conf << 'EOF'
# /etc/security/limits.conf
#
#This file sets the resource limits for the users logged in via PAM.
#It does not affect resource limits of the system services.
#
#Also note that configuration files in /etc/security/limits.d directory,
#which are read in alphabetical order, override the settings in this
#file in case the domain is the same or more specific.
#That means for example that setting a limit for wildcard domain here
#can be overriden with a wildcard setting in a config file in the
#subdirectory, but a user specific setting here can be overriden only
#with a user specific setting in the subdirectory.
#
#Each line describes a limit for a user in the form:
#
#<domain>        <type>  <item>  <value>
#
#Where:
#<domain> can be:
#        - an user name
#        - a group name, with @group syntax
#        - the wildcard *, for default entry
#        - the wildcard %, can be also used with %group syntax,
#                 for maxlogin limit
#
#<type> can have the two values:
#        - "soft" for enforcing the soft limits
#        - "hard" for enforcing hard limits
#
#<item> can be one of the following:
#        - core - limits the core file size (KB)
#        - data - max data size (KB)
#        - fsize - maximum filesize (KB)
#        - memlock - max locked-in-memory address space (KB)
#        - nofile - max number of open files
#        - rss - max resident set size (KB)
#        - stack - max stack size (KB)
#        - cpu - max CPU time (MIN)
#        - nproc - max number of processes
#        - as - address space limit (KB)
#        - maxlogins - max number of logins for this user
#        - maxsyslogins - max number of logins on the system
#        - priority - the priority to run user process with
#        - locks - max number of file locks the user can hold
#        - sigpending - max number of pending signals
#        - msgqueue - max memory used by POSIX message queues (bytes)
#        - nice - max nice priority allowed to raise to values: [-20, 19]
#        - rtprio - max realtime priority
#
#<domain>      <type>  <item>         <value>
#

#*               soft    core            0
#*               hard    rss             10000
#@student        hard    nproc           20
#@faculty        soft    nproc           20
#@faculty        hard    nproc           50
#ftp             hard    nproc           0
#@student        -       maxlogins       4
koji			 hard	 priority		-5

# End of file
EOF

# /etc/koji.conf
cp -p /etc/koji.conf /etc/koji.conf.orig
cat > /etc/koji.conf << 'EOF'
[koji]

;configuration for koji cli tool

;url of XMLRPC server
server = http://koji.localdomain/kojihub

;url of web interface
weburl = http://koji.localdomain/koji

;url of package download site
topurl=http://koji.localdomain/kojifiles

;path to the koji top directory
;topdir = /mnt/koji

;configuration for Kerberos authentication

;the service name of the principal being used by the hub
;krbservice = host

;configuration for SSL authentication

;client certificate
cert = ~/.koji/client.crt

;certificate of the CA that issued the client certificate
ca = ~/.koji/serverca.crt

;certificate of the CA that issued the HTTP server certificate
serverca = ~/.koji/serverca.crt
EOF

# /etc/httpd/conf.d/kojihub.conf
cp -p /etc/httpd/conf.d/kojihub.conf /etc/httpd/conf.d/kojihub.conf.orig
cat > /etc/httpd/conf.d/kojihub.conf << 'EOF'
#
# koji-hub is an xmlrpc interface to the Koji database
#

Alias /kojihub /usr/share/koji-hub/kojixmlrpc.py

<Directory "/usr/share/koji-hub">
    Options ExecCGI
    SetHandler wsgi-script
    Require all granted
</Directory>

# Support for mod_python is DEPRECATED. If you still need mod_python support,
# then use the following directory settings instead:
#
# <Directory "/usr/share/koji-hub">
#         SetHandler mod_python
#         PythonHandler kojixmlrpc
#         PythonOption ConfigFile /etc/koji-hub/hub.conf
#         PythonDebug Off
#         PythonAutoReload Off
# </Directory>

# Also serve /mnt/koji
Alias /kojifiles "/mnt/koji/"

<Directory "/mnt/koji">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
    AddType application/octet-stream .signature
</Directory>

# uncomment this to enable authentication via SSL client certificates
 <Location /kojihub/ssllogin>
         SSLVerifyClient require
         SSLVerifyDepth  10
         SSLOptions +StdEnvVars
 </Location>

# If you need to support koji < 1.4.0 clients using SSL authentication, then use the following instead:
# <Location /kojihub>
#         SSLOptions +StdEnvVars
# </Location>
# In this case, you will need to enable these options globally (in ssl.conf):
# SSLVerifyClient require
# SSLVerifyDepth  10
EOF

# /etc/httpd/conf.d/kojiweb.conf
cat > /etc/httpd/conf.d/kojiweb.conf << 'EOF'
# We use wsgi by default
Alias /koji "/usr/share/koji-web/scripts/wsgi_publisher.py"
#(configuration goes in /etc/kojiweb/web.conf)

<Directory "/usr/share/koji-web/scripts/">
    Options ExecCGI
    SetHandler wsgi-script
    Require all granted
</Directory>

# Support for mod_python is DEPRECATED. If you still need mod_python support,
# then use the following directory settings instead:
#
# <Directory "/usr/share/koji-web/scripts/">
#     # Config for the publisher handler
#     SetHandler mod_python
#     # Use kojiweb's publisher (provides wsgi compat layer)
#     # mod_python's publisher is no longer supported
#     PythonHandler wsgi_publisher
#     PythonOption koji.web.ConfigFile /etc/kojiweb/web.conf
#     PythonAutoReload Off
#     # Configuration via PythonOptions is DEPRECATED. Use /etc/kojiweb/web.conf
#     Order allow,deny
#     Allow from all
# </Directory>

# uncomment this to enable authentication via Kerberos
# <Location /koji/login>
#     AuthType Kerberos
#     AuthName "Koji Web UI"
#     KrbMethodNegotiate on
#     KrbMethodK5Passwd off
#     KrbServiceName HTTP
#     KrbAuthRealm EXAMPLE.COM
#     Krb5Keytab /etc/httpd.keytab
#     KrbSaveCredentials off
#     Require valid-user
#     ErrorDocument 401 /koji-static/errors/unauthorized.html
# </Location>

# uncomment this to enable authentication via SSL client certificates
 <Location /koji/login>
     SSLVerifyClient require
     SSLVerifyDepth  10
     SSLOptions +StdEnvVars
 </Location>

Alias /koji-static/ "/usr/share/koji-web/static/"

<Directory "/usr/share/koji-web/static/">
    Options None
    AllowOverride None
    Require all granted
</Directory>
EOF

# /etc/kojid/kojid.conf
cp -p /etc/kojid/kojid.conf /etc/kojid/kojid.conf.orig
cat > /etc/kojid/kojid.conf << 'EOF'
[kojid]
; The number of seconds to sleep between tasks
; sleeptime=15

; The maximum number of jobs that kojid will handle at a time
maxjobs=20

; The minimum amount of free space (in MBs) required for each build root
; minspace=8192

; The directory root where work data can be found from the koji hub
; topdir=/mnt/koji

; The directory root for temporary storage
; workdir=/tmp/koji

; The directory root for mock
; mockdir=/var/lib/mock

; The user to run as when doing builds
; mockuser=kojibuilder

; The vendor to use in rpm headers
; vendor=Koji

; The packager to use in rpm headers
; packager=Koji

; The distribution to use in rpm headers
; distribution=Koji

; The _host string to use in mock
; mockhost=koji-linux-gnu

; The URL for the xmlrpc server
server=http://koji.localdomain/kojihub

; The URL for the file access
topurl=http://koji.localdomain/kojifiles

; A space-separated list of hostname:repository[:use_common] tuples that kojid is authorized to checkout from (no quotes).
; Wildcards (as supported by fnmatch) are allowed.
; If use_common is specified and is one of "false", "no", "off", or "0" (without quotes), then kojid will not attempt to checkout
; a common/ dir when checking out sources from the source control system.  Otherwise, it will attempt to checkout a common/
; dir, and will raise an exception if it cannot.
;allowed_scms=scm.localdomain:/cvs/example git.example.org:/example svn.example.org:/users/*:no
allowed_scms=koji.localdomain:/rpms/*:false:rhpkg,sources svn.apache.org:/repos/*:no git.app.eng.bos.redhat.com:*:false:rhpkg,sources git.engineering.redhat.com:*:false:rhpkg,sources github.com:*:false:rhpkg,sources forge.fusesource.com:*:false:rhpkg,sources

; The mail host to use for sending email notifications
smtphost=koji.localdomain

; The From address used when sending email notifications
from_addr=Koji Build System <buildsys@localdomain>

;configuration for Kerberos authentication

;the format of the principal used by the build hosts
;%s will be replaced by the FQDN of the host
;host_principal_format = compile/%s@EXAMPLE.COM

;location of the keytab
;keytab = /etc/kojid/kojid.keytab

;the service name of the principal being used by the hub
;krbservice = host

;configuration for SSL authentication

;client certificate
cert = /etc/pki/koji/kojibuilder1.pem

;certificate of the CA that issued the client certificate
ca = /etc/pki/koji/koji_ca_cert.crt

;certificate of the CA that issued the HTTP server certificate
serverca = /etc/pki/koji/koji_ca_cert.crt
EOF

# /etc/koji-hub/hub.conf
cp -p /etc/koji-hub/hub.conf /etc/koji-hub/hub.conf.orig
cat > /etc/koji-hub/hub.conf << 'EOF'
[hub]

## ConfigParser style config file, similar to ini files
## http://docs.python.org/library/configparser.html
##
## Note that multiline values can be set by indenting subsequent lines
## (which means you should not indent regular lines)

## Basic options ##
DBName = koji
DBUser = koji
#DBHost = localhost.localdomain
#DBPass = koji
KojiDir = /mnt/koji


##  Kerberos authentication options  ##

# AuthPrincipal = host/kojihub@EXAMPLE.COM
# AuthKeytab = /etc/koji.keytab
# ProxyPrincipals = koji/kojiweb@EXAMPLE.COM
## format string for host principals (%s = hostname)
# HostPrincipalFormat = compile/%s@EXAMPLE.COM

## end Kerberos auth configuration


##  SSL client certificate auth configuration  ##
#note: ssl auth may also require editing the httpd config (conf.d/kojihub.conf)

## the client username is the common name of the subject of their client certificate
# DNUsernameComponent = CN
## separate multiple DNs with |
# ProxyDNs = /C=US/ST=Massachusetts/O=Example Org/OU=Example User/CN=example/emailAddress=example@example.com
ProxyDNs = /C=XX/ST=SomeState/L=SomeCity/O=SomeOrganization/OU=SomeOrganizationalUnit/CN=kojiweb/emailAddress=koji@localdomain

## end SSL client certificate auth configuration


##  Other options  ##
LoginCreatesUser = On
KojiWebURL = http://kojiweb.localdomain/koji
# The domain name that will be appended to Koji usernames
# when creating email notifications
#EmailDomain = example.com
# whether to send the task owner and package owner email or not on success.  this still goes to watchers
NotifyOnSuccess = True
## Disables all notifications
DisableNotifications = True

## Extended features
## Support Maven builds
EnableMaven = True
## Support Windows builds
# EnableWin = False

## Koji hub plugins
## The path where plugins are found
# PluginPath = /usr/lib/koji-hub-plugins
## A space-separated list of plugins to load
# Plugins = echo

## If KojiDebug is on, the hub will be /very/ verbose and will report exception
## details to clients for anticipated errors (i.e. koji's own exceptions --
## subclasses of koji.GenericError).
# KojiDebug = On

## Determines how much detail about exceptions is reported to the client (via faults)
## Meaningful values:
##   normal - a basic traceback (format_exception)
##   extended - an extended traceback (format_exc_plus)
##   anything else - no traceback, just the error message
## The extended traceback is intended for debugging only and should NOT be
## used in production, since it may contain sensitive information.
# KojiTraceback = normal

## These options are intended for planned outages
# ServerOffline = False
# OfflineMessage = temporary outage
# LockOut = False
## If ServerOffline is True, the server will always report a ServerOffline fault (with
## OfflineMessage as the fault string).
## If LockOut is True, the server will report a ServerOffline fault for all non-admin
EOF

# /etc/kojira/kojira.conf
cp -p /etc/kojira/kojira.conf /etc/kojira/kojira.conf.orig
cat > /etc/kojira/kojira.conf << 'EOF'
[kojira]
; For user/pass authentication
; user=kojira
; password=kojira

; For Kerberos authentication
; the principal to connect with
principal=koji/repo@EXAMPLE.COM
; The location of the keytab for the principal above
keytab=/etc/kojira.keytab

; The URL for the koji hub server
server=http://koji.localdomain/kojihub

; The directory containing the repos/ directory
topdir=/mnt/koji

; Logfile
logfile=/var/log/kojira.log

; Include srpms in repos? (not needed for normal operation)
with_src=no

;configuration for Kerberos authentication

;the kerberos principal to use
;principal = kojira@EXAMPLE.COM

;location of the keytab
;keytab = /etc/kojira/kojira.keytab

;the service name of the principal being used by the hub
;krbservice = host

;configuration for SSL authentication

;client certificate
cert = /etc/pki/koji/kojira.pem

;certificate of the CA that issued the client certificate
ca = /etc/pki/koji/koji_ca_cert.crt

;certificate of the CA that issued the HTTP server certificate
serverca = /etc/pki/koji/koji_ca_cert.crt
EOF

# /etc/kojiweb/web.conf
cat > /etc/kojiweb/web.conf << 'EOF'
[web]
SiteName = koji
#KojiTheme = mytheme

# Key urls
KojiHubURL = http://koji.localdomain/kojihub
KojiFilesURL = http://koji.localdomain/kojifiles

# Kerberos authentication options
# WebPrincipal = koji/web@EXAMPLE.COM
# WebKeytab = /etc/httpd.keytab
# WebCCache = /var/tmp/kojiweb.ccache

# SSL authentication options
WebCert = /etc/pki/koji/certs/kojiweb.crt
ClientCA = /etc/pki/koji/certs/clientca.crt
KojiHubCA = /etc/pki/koji/certs/kojihubca.crt

LoginTimeout = 72

# This must be changed and uncommented before deployment
# Secret = CHANGE_ME

LibPath = /usr/share/koji-web/lib
EOF

# /etc/httpd/conf.d/ssl
cp -p /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.orig
sed -e '/SSLCertificateFile/s/^/#/' -e '/SSLCertificateKeyFile/s/^/#/' -e '/#SSLVerifyDepth/{:a;n;/^$/!ba;i\\n#   Koji Configuration\nSSLCertificateFile /etc/pki/koji/certs/kojihub.crt\nSSLCertificateKeyFile /etc/pki/koji/certs/kojihub.key\nSSLCertificateChainFile /etc/pki/koji/koji_ca_cert.crt\nSSLCACertificateFile /etc/pki/koji/koji_ca_cert.crt\nSSLVerifyClient require\nSSLVerifyDepth  10\nBrowserMatch "koji" ssl-accurate-shutdown' -e '}' /etc/httpd/conf.d/ssl.conf > /etc/httpd/conf.d/ssl.tmp
cat /etc/httpd/conf.d/ssl.tmp > /etc/httpd/conf.d/ssl.conf
rm /etc/httpd/conf.d/ssl.tmp

# /etc/yum.repos.d/fedora-mirror.repo
cat > /etc/yum.repos.d/fedora-mirror.repo << 'EOF'
[fedora-mirror]
name=Fedora $releasever - $basearch
failovermethod=priority
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$basearch
EOF

# /etc/sysconfig/network-scripts/ifcfg-eth0
cp -p /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0.orig
cat >  /etc/sysconfig/network-scripts/ifcfg-eth0 << 'EOF'
HWADDR=52:54:00:12:34:56
TYPE=Ethernet
BOOTPROTO=static
IPADDR=192.168.122.2
NETMASK=255.255.255.0
GATEWAY=192.168.122.1
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_PEERDNS=yes
IPV6_PEERROUTES=yes
IPV6_FAILURE_FATAL=no
NAME=eth0
UUID=bd95e2b3-707c-497a-8eb4-a828fad84bc0
ONBOOT=yes
EOF

# /tmp/init.d/99_cfg
cat > /etc/init.d/99_cfg << 'EOF'
#!/bin/bash
#
# kojak: Post configuration routine
#
# chkconfig: 345 99 00
# description: Configuration script.

# Disable firewall
systemctl stop firewalld.service
systemctl disable firewalld.service

# Start the database
postgresql-setup initdb
systemctl enable postgresql.service
systemctl start postgresql.service

#/tmp/users.sql
echo -e "insert into users (name, status, usertype) values ('koji', 0, 0);
insert into user_perms (user_id, perm_id, creator_id) values (1, 1, 1);
insert into users (name, status, usertype) values ('kojiadmin', 0, 0);
insert into user_perms (user_id, perm_id, creator_id) values (2, 1, 1);
\q" >> /tmp/users.sql

# Create the koji server, component and user SSL certs
# Use default certificate authority name
CANAME="koji" 

# Get the systems host and domain name.
HOSTNAME=`hostname -s`
DOMAINNAME=`hostname | cut -d . -f 2,3`

# Certificate directories.
CRTHOME="/etc/pki/koji"
CLCRTHOME="/home/koji/.koji"
CNF="/etc/pki/tls/openssl.cnf"

# Begin certificate generation
echo -e "Generating server key and certificate authority\n"
cd $CRTHOME

# Genrate the private key and certificate authority
openssl genrsa -out private/${CANAME}_ca_cert.key 2048
openssl req -config ${CNF} -new -x509 -days 3650 -subj \
"/C=XX/ST=SomeState/L=SomeCity/O=SomeOrganization/OU=SomeOrganizationalUnit/CN=$HOSTNAME/emailAddress=${CANAME}@${DOMAINNAME}" \
-key private/${CANAME}_ca_cert.key -out ${CANAME}_ca_cert.crt -extensions v3_ca

echo -e "Generating component keys and signing certificates\n"
echo -e "y\ny" > ${CRTHOME}/response.txt

# Create certificates for the koji components.
for USER in koji kojiadmin kojira kojiweb kojihub
do
    echo "creating certificate for ${USER} ..."
    openssl genrsa -out ${CRTHOME}/certs/${USER}.key 2048
    
    cat ${CNF} | sed '0,/${HOSTNAME}/s//'${USER}'/' > ${CRTHOME}/${USER}-ssl.cnf

    openssl req -config ${CRTHOME}/${USER}-ssl.cnf -new -days 3650 -subj \
    "/C=XX/ST=SomeState/L=SomeCity/O=SomeOrganization/OU=SomeOrganizationalUnit/CN=${USER}/emailAddress=root@$HOSTNAME" \
    -out certs/${USER}.csr -key ${CRTHOME}/certs/${USER}.key
    
    < ${CRTHOME}/response.txt openssl ca -config ${CRTHOME}/${USER}-ssl.cnf -keyfile ${CRTHOME}/private/${CANAME}_ca_cert.key -cert ${CRTHOME}/${CANAME}_ca_cert.crt \
    -out ${CRTHOME}/certs/${USER}.crt -outdir ${CRTHOME}/certs -infiles ${CRTHOME}/certs/${USER}.csr
    cat ${CRTHOME}/certs/${USER}.crt ${CRTHOME}/certs/${USER}.key > ${CRTHOME}/${USER}.pem
    mv -f ${CRTHOME}/${USER}-ssl.cnf ${CRTHOME}/confs/${USER}-ssl.cnf

    echo "...done"
done

# Create certificates for the koji builders.
for USER in kojibuilder{1..3}
do
    echo "creating certificate for ${USER} ..."
    openssl genrsa -out ${CRTHOME}/certs/${USER}.key 2048

    cat ${CNF} | sed '0,/${HOSTNAME}/s//'${USER}.${DOMAINNAME}'/' > ${CRTHOME}/${USER}-ssl.cnf

    openssl req -config ${CRTHOME}/${USER}-ssl.cnf -new -days 3650 -subj \
    "/C=XX/ST=SomeState/L=SomeCity/O=SomeOrganization/OU=SomeOrganizationalUnit/CN=${USER}.${DOMAINNAME}/emailAddress=root@$HOSTNAME" \
    -out ${CRTHOME}/certs/${USER}.csr -key ${CRTHOME}/certs/${USER}.key

    < response.txt openssl ca -config ${CRTHOME}/${USER}-ssl.cnf -keyfile ${CRTHOME}/private/${CANAME}_ca_cert.key -cert ${CRTHOME}/${CANAME}_ca_cert.crt \
    -out ${CRTHOME}/certs/${USER}.crt -outdir ${CRTHOME}/certs -infiles ${CRTHOME}/certs/${USER}.csr
    cat ${CRTHOME}/certs/${USER}.crt ${CRTHOME}/certs/${USER}.key > ${USER}.pem
    mv -f ${CRTHOME}/${USER}-ssl.cnf ${CRTHOME}/confs/${USER}-ssl.cnf

    echo "...done"
done
rm -f response.txt

# Copy the client certficates to the koji users home directory.
echo -e "Deploying certificates...\n"

cp -f /etc/pki/koji/kojiadmin.pem /home/koji/.koji/client.crt
cp -f /etc/pki/koji/${CANAME}_ca_cert.crt /home/koji/.koji/clientca.crt
cp -f /etc/pki/koji/${CANAME}_ca_cert.crt /home/koji/.koji/serverca.crt

# Set the appropriate permissions
chown -R koji:apache /home/koji/.koji/
cd -

# /var/lib/pgsql/data/postgresql.conf
cp -p /var/lib/pgsql/data/postgresql.conf /var/lib/pgsql/data/postgresql.conf.orig
sed -i -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/data/postgresql.conf

# /var/lib/pgsql/data/pg_hba.conf
cp /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf.orig

echo -e "
# Koji
local   koji        koji                                         trust
local   koji        apache                                       trust
host    koji        koji                127.0.0.1/32             trust
host    koji        apache              127.0.0.1/32             trust
host    koji        koji                ::1/128                  trust
host    koji        apache              ::1/128                  trust
host    koji        koji                192.168.122.89/32        trust
host    koji        apache              192.168.122.89/32        trust" >> /var/lib/pgsql/data/pg_hba.conf

sed -i -e "s/local   all             all                                     peer/local   all             all                                     trust/g" /var/lib/pgsql/data/pg_hba.conf
chown postgres:postgres /var/lib/pgsql/data/pg_hba.conf.orig

# Create the database tables
su -l postgres -c "createuser koji; createdb -O koji koji"
su -l koji -c "psql koji koji < /usr/share/doc/koji-1.8.0/docs/schema.sql"
su -l koji -c "psql koji koji < /tmp/users.sql"

# Restart database services
systemctl restart postgresql.service
systemctl restart httpd.service

# Begin Koji configuration
su -l koji -c "

# Add hosts and channels
koji add-host kojibuilder1.localdomain x86_64
koji add-host-to-channel kojibuilder1.localdomain appliance
koji add-host-to-channel kojibuilder1.localdomain createrepo
koji add-host-to-channel kojibuilder1.localdomain livecd
koji add-host-to-channel kojibuilder1.localdomain maven
koji add-host-to-channel kojibuilder1.localdomain vm

# Add tags
koji add-tag fedora-19 --maven-support --include-all --arches="x86_64"
koji add-tag fedora-19-candidate --maven-support --include-all --parent=fedora-19 --arches="x86_64"
koji add-tag fedora-19-build --maven-support --include-all --parent=fedora-19 --arches="x86_64"
koji add-tag maven-build --maven-support --include-all --parent=fedora-19 --arches="x86_64"
koji add-tag maven-import --maven-support --include-all --parent=maven-build

# Add tag inheritance
koji add-tag-inheritance fedora-19-build maven-import --priority 10

# Add target
koji add-target fedora-19-candidate fedora-19-build fedora-19-candidate

# Add external repo
koji add-external-repo -t fedora-19 fedora-mirror http://mirrors.kernel.org/fedora/releases/19/Everything/x86_64/os/

# Add groups
#
# build
koji add-group fedora-19-build build
koji add-group-pkg fedora-19-build build bash bzip2 cpio diffutils fedora-release findutils gawk gcc gcc-c++ info make redhat-rpm-config rpm-build sed shadow-utils unzip util-linux-ng which xz
#
# srpm-build
koji add-group fedora-19-build srpm-build
koji add-group-pkg fedora-19-build srpm-build bash curl cvs fedora-release fedpkg gnupg2 make redhat-rpm-config rpm-build shadow-utils
#
# appliance-build
koji add-group fedora-19-build appliance-build
koji add-group-pkg fedora-19-build appliance-build appliance-tools bash coreutils grub parted perl policycoreutils selinux-policy shadow-utils
#
# maven-build
koji add-group fedora-19-build maven-build
# Fedora Package group
koji add-group-pkg fedora-19-build maven-build bash coreutils java-1.7.0-openjdk-devel maven subversion liberation-sans-fonts liberation-serif-fonts liberation-mono-fonts git
# Red Hat packages group
#koji add-group-pkg fedora-19-build maven-build bash coreutils java-1.7.0-openjdk-devel maven3 subversion liberation-sans-fonts liberation-serif-fonts liberation-mono-fonts git
#
# livecd-build
koji add-group fedora-19-build livecd-build
koji add-group-pkg fedora-19-build livecd-build bash bzip2 coreutils cpio diffutils fedora-logos fedora-release findutils gawk gcc gcc-c++ grep gzip info livecd-tools make patch policycoreutils python-dbus redhat-rpm-config rpm-build sed selinux-policy-targeted shadow-utils squashfs-tools tar unzip util-linux which yum

# Ramp up capacity
koji edit-host --capacity 10.0 kojibuilder1.localdomain

# Add required build packages
koji add-pkg --owner=kojiadmin fedora-19 bash binutils
"

# Restart Koji services
systemctl enable httpd.service
systemctl restart httpd.service
systemctl enable kojid.service
systemctl restart kojid.service
systemctl enable kojira.service
systemctl restart kojira.service

# Grant permissions
su -l koji -c "koji grant-permission repo kojira"
su -l koji -c "koji grant-permission build kojibuilder1.localdomain"

# Maven installation
cd /tmp
wget http://mirror.karneval.cz/pub/linux/fedora/linux/releases/19/Everything/source/SRPMS/m/maven-3.0.5-3.fc19.src.rpm
wget http://mirror.karneval.cz/pub/linux/fedora/linux/releases/19/Everything/x86_64/os/Packages/m/maven-3.0.5-3.fc19.noarch.rpm
su -l koji -c "koji import --create-build /tmp/maven-3.0.5-3.fc19.src.rpm /tmp/maven-3.0.5-3.fc19.noarch.rpm"
su -l koji -c "koji add-pkg --owner=kojiadmin fedora-19-build maven"
su -l koji -c "koji tag-pkg fedora-19-build maven-3.0.5-3.fc19"

# Create workspace for tool chain downloads
mkdir /home/koji/workspace
chown -R koji:koji /home/koji

# Clean up files
rm /tmp/*.rpm
rm -rf /tmp/koji
rm -f /etc/init.d/99_cfg
cd -

# Update system
yum -y update
EOF

chmod +x /etc/init.d/99_cfg
systemctl enable 99_cfg.service

%end