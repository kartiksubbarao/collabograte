Summary: Collabograte puppet-related configuration files
Name: collabograte-puppet
Version: 1.0
Release: 1
License: FreeBSD
Group: Applications/System
URL: https://github.com/kartiksubbarao/collabograte
Source0: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: puppet
# We manage application dependencies outside of the RPM
AutoReqProv: no

%description
Collabograte puppet-related configuration files

%prep
%setup -q

%install
rm -rf %{buildroot}
install -d %{buildroot}%{_sysconfdir}/puppet
cp -r modules %{buildroot}%{_sysconfdir}/puppet
wget -O %{buildroot}%{_sysconfdir}/puppet/modules/openldap/files/Example.ldif "http://git.fedorahosted.org/git/?p=389/ds.git;a=blob_plain;f=ldap/ldif/Example.ldif"
# This reformats the ns-mail schema file and gets rid of improper attributes
wget -O - "http://git.fedorahosted.org/git/?p=389/ds.git;a=blob_plain;f=ldap/schema/50ns-mail.ldif" \
| perl -ne '
	next if /^dn:/ || /-oid/ || /nsMessagingServerUser/;
	s/^attributeTypes:/attributetype/i;
	s/^objectclasses:/objectclass/i;
	s/\$\s(multiLineDescription|nsmsgDisallowAccess|mgrpApprovePassword)//i;
	s/(1.3.6.1.4.1.1466.115.121.1.15)/$1 EQUALITY caseIgnoreMatch SUBSTR caseIgnoreSubstringsMatch/;
	print' > %{buildroot}%{_sysconfdir}/puppet/modules/openldap/files/ns-mail.schema
## It would be better to have this packaged in an RPM like 
## mediawiki-ldapauthentication
wget -r --no-parent -e robots=off --no-directories -P %{buildroot}%{_sysconfdir}/puppet/modules/mediawiki/files/LdapAuthentication http://svn.wikimedia.org/svnroot/mediawiki/branches/REL1_16/extensions/LdapAuthentication/
## It would be better to have this packaged in an RPM like
## wordpress-plugin-wpdirauth
wget -P %{buildroot}%{_sysconfdir}/puppet/modules/wordpress/files http://svn.wp-plugins.org/wpdirauth/trunk/wpDirAuth.php

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%{_sysconfdir}/puppet/modules/*
