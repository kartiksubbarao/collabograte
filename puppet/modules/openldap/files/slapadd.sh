#! /bin/sh

# Load LDIF into the directory

perl -p00e 's/\n //gm' /etc/puppet/modules/openldap/files/Example.ldif \
	| egrep -v '^aci:|^ns' > /tmp/Example.ldif

/usr/sbin/slapadd -q -b $COLLABOGRATE_BASEDN -l /tmp/Example.ldif

rm /tmp/Example.ldif
