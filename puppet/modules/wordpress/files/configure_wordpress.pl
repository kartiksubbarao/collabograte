#! /usr/bin/perl

use DBI;
use WWW::Mechanize;
use File::Copy;

use strict;

my $dbh = DBI->connect('DBI:mysql:database=mysql;host=localhost',
					   'root',
					   $ENV{COLLABOGRATE_MYSQL_ROOTPASSWORD},
					   { RaiseError => 1 });
$dbh->do("create database wordpress");
$dbh->do("grant all privileges on wordpress.* to wordpress identified by 'wordpress'");
$dbh->do("grant all privileges on wordpress.* to wordpress\@localhost identified by 'wordpress'");
$dbh->do("grant all privileges on wordpress.* to wordpress\@'%' identified by 'wordpress'");
$dbh->do("flush privileges");
$dbh->disconnect;

copy("/etc/puppet/modules/wordpress/files/wp-config.php", "/etc/wordpress");

my $mech = WWW::Mechanize->new;

#$mech->add_handler("request_send", sub { shift->dump; return });
#$mech->add_handler("response_done", sub { shift->dump; return });

# Use hostname instead of localhost during the install process, since 
# otherwise followup URLs will be redirected to localhost, causing remote 
# sessions to fail
$mech->get("http://$ENV{HOSTNAME}/wordpress/wp-admin/install.php");
$mech->form_name('setup');
$mech->set_fields(weblog_title => 'Collabograte',
				  user_name => 'admin',
				  admin_password => $ENV{COLLABOGRATE_WORDPRESS_ADMINPASSWORD},
				  admin_password2 =>$ENV{COLLABOGRATE_WORDPRESS_ADMINPASSWORD},
				  admin_email => "root\@$ENV{COLLABOGRATE_DOMAIN}");
$mech->submit;

# Log in
$mech->get("http://$ENV{HOSTNAME}/wordpress/wp-login.php");
$mech->form_name('loginform');
$mech->set_fields(log => 'admin', pwd => 'admin123');
$mech->submit;

# Enable multisite -- this is a multi-step process
system q(perl -i -pe '/, stop editing/ and print
q|
define("WP_ALLOW_MULTISITE", true);
|' /etc/wordpress/wp-config.php);
$mech->get("http://$ENV{HOSTNAME}/wordpress/wp-admin/network.php");
$mech->submit_form(form_number => 1);
system qq(perl -i -pe '/, stop editing/ and print
qq|
define("MULTISITE", true);
define("SUBDOMAIN_INSTALL", false);
\\\$base = "/wordpress/";
define("DOMAIN_CURRENT_SITE", "$ENV{HOSTNAME}");
define("PATH_CURRENT_SITE", "/wordpress/");
define("SITE_ID_CURRENT_SITE", 1);
define("BLOG_ID_CURRENT_SITE", 1);

|' /etc/wordpress/wp-config.php);
copy("/etc/puppet/modules/wordpress/files/htaccess", "/usr/share/wordpress/.htaccess");
# Necessary for .htaccess to work
system("perl -i -pe 's/AllowOverride Options/AllowOverride All/' /etc/httpd/conf.d/wordpress.conf");
system("/sbin/service httpd restart > /dev/null 2>&1");

# Log in again
$mech->get("http://$ENV{HOSTNAME}/wordpress/wp-login.php");
$mech->form_name('loginform');
$mech->set_fields(log => 'admin',
				  pwd => $ENV{COLLABOGRATE_WORDPRESS_ADMINPASSWORD});
$mech->submit;

# Activate and configure the wpDirAuth plugin
$mech->get("http://$ENV{HOSTNAME}/wordpress/wp-admin/network/plugins.php");
$mech->follow_link(url_regex => qr/action=activate.*plugin=wpdirauth/);
$mech->get("http://$ENV{HOSTNAME}/wordpress/wp-admin/options-general.php?page=wpDirAuth.php");
$mech->form_name('dir_auth_options');
$mech->set_fields(dirAuthEnable => 1,
				  dirAuthControllers => 'localhost',
				  dirAuthFilter => 'uid',
				  dirAuthBaseDn => $ENV{COLLABOGRATE_BASEDN},
				  dirAuthInstitution => 'Collabograte',
				  dirAuthLoginScreenMsg => 'Login with your LDAP uid and password');
$mech->submit;
