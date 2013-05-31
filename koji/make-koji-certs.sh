#!/bin/bash
#
# Simple script to automate the creation of SSL certificates for koji components.

# Note...check for creation of time stamp file which should indicate the
# successful execution of the script.

## Declare environment variables.
#
# Use default certificate authority name
CANAME="koji" 

# Get the systems host and domain name.
HOSTNAME=`hostname -s`
DOMAINNAME=`hostname | cut -d . -f 2,3`

# Certificate directories.
CRTHOME="/etc/pki/koji/"
CLCRTHOME="/home/koji/.koji"

# Run some basic checks to ensure that the directories exist and are empty.
if [ -d "$CRTHOME" ]; then
    rm -rf $CRTHOME && mkdir $CRTHOME
else
    mkdir $CRTHOME
fi

if [ -d "$CLCRTHOME" ]; then
    rm -rf $CLCRTHOME && mkdir $CLCRTHOME
else
    mkdir $CLCRTHOME
fi

# Begin certificate generation
echo -e "Generating server key and certificate authority\n"
cp ssl.cnf $CRTHOME
cd $CRTHOME
mkdir {certs,confs,private}
touch index.txt
echo 01 > serial

# Genrate the private key and certificate authority
openssl genrsa -out private/${CANAME}_ca_cert.key 2048
openssl req -config ssl.cnf -new -x509 -days 3650 -subj \
"/C=XX/ST=SomeState/L=SomeCity/O=SomeOrganization/OU=SomeOrganizationalUnit/CN=$HOSTNAME/emailAddress=${CANAME}@${DOMAINNAME}" \
-key private/${CANAME}_ca_cert.key -out ${CANAME}_ca_cert.crt -extensions v3_ca

echo -e "Generating component keys and signing certificates\n"
echo -e "y\ny" > response.txt

# Create certificates for the koji components.
for USER in kojiadmin kojiuser kojira kojiweb kojihub
do
    echo "creating certificate for ${USER} ..."
    openssl genrsa -out certs/${USER}.key 2048
    
    cat ssl.cnf | sed '0,/${HOSTNAME}/s//'${USER}'/' > ${USER}-ssl.cnf

    openssl req -config ${USER}-ssl.cnf -new -days 3650 -subj \
    "/C=XX/ST=SomeState/L=SomeCity/O=SomeOrganization/OU=SomeOrganizationalUnit/CN=${USER}/emailAddress=root@$HOSTNAME" \
    -out certs/${USER}.csr -key certs/${USER}.key
    
    < response.txt openssl ca -config ${USER}-ssl.cnf -keyfile private/${CANAME}_ca_cert.key -cert ${CANAME}_ca_cert.crt \
    -out certs/${USER}.crt -outdir certs -infiles certs/${USER}.csr
    cat certs/${USER}.crt certs/${USER}.key > ${USER}.pem
    mv ${USER}-ssl.cnf confs/${USER}-ssl.cnf

    echo "...done"
done

# Create certificates for the koji builders.
for USER in kojibuilder{1..3}
do
    echo "creating certificate for ${USER} ..."
    openssl genrsa -out certs/${USER}.key 2048

    cat ssl.cnf | sed '0,/${HOSTNAME}/s//'${USER}.${DOMAINNAME}'/' > ${USER}-ssl.cnf

    openssl req -config ${USER}-ssl.cnf -new -days 3650 -subj \
    "/C=XX/ST=SomeState/L=SomeCity/O=SomeOrganization/OU=SomeOrganizationalUnit/CN=${USER}.${DOMAINNAME}/emailAddress=root@$HOSTNAME" \
    -out certs/${USER}.csr -key certs/${USER}.key

    < response.txt openssl ca -config ${USER}-ssl.cnf -keyfile private/${CANAME}_ca_cert.key -cert ${CANAME}_ca_cert.crt \
    -out certs/${USER}.crt -outdir certs -infiles certs/${USER}.csr
    cat certs/${USER}.crt certs/${USER}.key > ${USER}.pem
    mv ${USER}-ssl.cnf confs/${USER}-ssl.cnf

    echo "...done"
done
rm response.txt

# Copy the client certficates to the koji users home directory.
echo -e "Deploying certificates...\n"

cp -f /etc/pki/koji/kojiadmin.pem /home/koji/.koji/client.crt
cp -f /etc/pki/koji/${CANAME}_ca_cert.crt /home/koji/.koji/clientca.crt
cp -f /etc/pki/koji/${CANAME}_ca_cert.crt /home/koji/.koji/serverca.crt

# Set the appropriate permissions
chown -R koji:apache /home/koji/.koji/

# Restart httpd to effect the changes.
chkconfig httpd on
service httpd restart

# Check to make sure httpd service is up
TSTAMP=$(( `date +%H%M%S` ))
pgrep httpd
RETVAL=$?
if [ $RETVAL = 0 ]; then
    touch $TSTAMP
else 
    echo "The httpd service did not start up correctly please check the certs!"
fi

cd -

echo "...done"

