#! /usr/bin/perl

use WWW::Mechanize;

use strict;

my $mech = WWW::Mechanize->new;

#$mech->add_handler("request_send", sub { shift->dump; return });
#$mech->add_handler("response_done", sub { shift->dump; return });

my $mwdir = '/var/www/html/mediawiki';

chmod 0777, "$mwdir/config";

$mech->get('http://localhost/mediawiki/config/index.php');
$mech->form_name('config');
$mech->set_fields(Sitename => 'Collabograte',
				  SysopPass => $ENV{COLLABOGRATE_ADMIN_PASSWORD},
				  SysopPass2 => $ENV{COLLABOGRATE_ADMIN_PASSWORD},
				  DBpassword => $ENV{COLLABOGRATE_MEDIAWIKI_PASSWORD},
				  DBpassword2 => $ENV{COLLABOGRATE_MEDIAWIKI_PASSWORD},
				  useroot => 'on',
				  RootUser => 'root',
				  RootPW => $ENV{COLLABOGRATE_MYSQL_ROOTPASSWORD});
$mech->submit;

rename "$mwdir/config/LocalSettings.php", "$mwdir/LocalSettings.php";
chmod 0755, "$mwdir/config";
