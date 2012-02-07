#! /usr/bin/perl

use DBI;
use Net::LDAP;
use Net::LDAP::Entry;

use strict;

system "mysql -u root --password='$ENV{COLLABOGRATE_MYSQL_ROOTPASSWORD}' < /usr/share/sympa/bin/create_db.mysql";

my $dbh = DBI->connect('DBI:mysql:database=mysql;host=localhost',
					   'root', $ENV{COLLABOGRATE_MYSQL_ROOTPASSWORD},
					   { RaiseError => 1 });
$dbh->do("grant all privileges on sympa.* to sympa\@localhost identified by 'sympa'");
$dbh->do("flush privileges");
$dbh->disconnect;

my $domain = $ENV{COLLABOGRATE_DOMAIN};
## Need to create an Augeas lens for /etc/sympa/sympa.conf
system qq(perl -i -pe '
s/^syslog/syslog MAIL/;
s/^domain.*/domain lists.$domain/;
s/^listmaster.*/listmaster root\\\@$domain/;
s/^db_user.*/db_user sympa/;
s/^db_passwd.*/db_passwd sympa/;
s#^wwsympa_url.*#wwsympa_url http://lists.$domain/sympa#;
' /etc/sympa/sympa.conf);

# Enable access to Sympa web interface
system "perl -i -pe 's/Deny from all/Allow from all/g' /etc/httpd/conf.d/sympa.conf";

my $basedn = $ENV{COLLABOGRATE_BASEDN};
my $ldap = Net::LDAP->new("localhost") or die "LDAP: $!\n";
my $r = $ldap->bind(dn => $ENV{COLLABOGRATE_ROOTDN},
					password => $ENV{COLLABOGRATE_ROOTDN_PASSWORD});
$r->code && die("LDAP bind: ", $r->error, "\n");

# Create a couple of groups to be used as Sympa lists
my $group1 = Net::LDAP::Entry->new(
	"cn=Product_Development,ou=groups,$basedn",
	objectclass => [ qw(top groupOfNames mailGroup) ],
	cn => "Product_Development",
	mail => "product_development\@lists.$domain",
	owner => "uid=kwinters,ou=people,$basedn");
my $mesg = $ldap->search(base => "ou=People,$basedn",
                         filter => "(ou=Product Development)",
                         attrs => ['member']);
$mesg->code && die($mesg->error . "\n");
$group1->add(member => [ map { $_->dn } $mesg->entries ]);
$group1->update($ldap);

my $group2 = Net::LDAP::Entry->new(
	"cn=Accounting,ou=groups,$basedn",
	objectclass => [ qw(top groupOfNames mailGroup) ],
	cn => "Accounting",
	mail => "accounting\@lists.$domain",
	owner => "uid=scarter,ou=people,$basedn");
$mesg = $ldap->search(base => "ou=People,$basedn",
                         filter => "(ou=Accounting)",
                         attrs => ['member']);
$mesg->code && die($mesg->error . "\n");
$group2->add(member => [ map { $_->dn } $mesg->entries ]);
$group2->update($ldap);

# Create the lists in Sympa
system "sympa.pl --create_list --input_file /etc/puppet/modules/sympa/files/product_development.xml";
system "sympa.pl --create_list --input_file /etc/puppet/modules/sympa/files/accounting.xml";
