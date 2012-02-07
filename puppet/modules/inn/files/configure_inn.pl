#! /usr/bin/perl

use Net::LDAP;

use strict;

$ENV{PATH} .= ':/usr/libexec/news';

## Enhance Augeas postfix lens to support postfix "array" parameters so
## that we can append to them instead of overwriting them. For example:
## set virtual_alias_maps/[last()+1] regexp:...
system q(perl -i -pe '
/^virtual_alias_maps/ && s|$|, regexp:\$config_directory/inn_virtual_regexp|;
' /etc/postfix/main.cf);

system "postfix reload";

# Configure a bidirectional mail <=> news gateway for the sample mailing lists

my $shortdom = $ENV{COLLABOGRATE_DOMAIN}; $shortdom =~ s/\..*$//;
my $basedn = $ENV{COLLABOGRATE_BASEDN};
my $rootdn = $ENV{COLLABOGRATE_ROOTDN};
my $rootdn_password = $ENV{COLLABOGRATE_ROOTDN_PASSWORD};
my $ldap = Net::LDAP->new("localhost") or die "LDAP: $!\n";
my $r = $ldap->bind(dn => $rootdn, password => $rootdn_password);
$r->code && die("LDAP bind: ", $r->error, "\n");

my $mesg = $ldap->search(base => "ou=groups,$basedn",
						 filter => '(mail=*)',
						 attrs => ['cn']);
foreach my $entry ($mesg->entries) {
	my $groupname = lc $entry->get_value('cn');
	$ldap->modify($entry->dn, 
		add => { mgrpRFC822MailMember => "$shortdom.$groupname\@news.$ENV{COLLABOGRATE_DOMAIN}" });
	system "ctlinnd newgroup $shortdom.$groupname";
}
