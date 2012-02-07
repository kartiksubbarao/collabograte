class mediawiki {

include collabograte_common
include apache
require mysql
require openldap

Exec { path => $collabograte_common::path,
	   environment => $collabograte_common::environment, logoutput => true }

$mwpackage = "mediawiki116"
package { $mwpackage:
	ensure => installed,
	notify => Service["httpd"]
}

$mwdir = "/var/www/html/mediawiki"
file { $mwdir: 
	ensure => link,
	target => "/var/www/$mwpackage",
	require => Package[$mwpackage] 
}

## Ideally these would be packaged in a mediawiki-ldapauthentication rpm
file { "$mwdir/extensions/LdapAuthentication":
	ensure => directory,
	require => File[$mwdir]
}
file { "$mwdir/extensions/LdapAuthentication/LdapAuthentication.i18n.php":
	source => "puppet:///modules/mediawiki/LdapAuthentication/LdapAuthentication.i18n.php"
}
file { "$mwdir/extensions/LdapAuthentication/LdapAuthentication.php":
	source => "puppet:///modules/mediawiki/LdapAuthentication/LdapAuthentication.php"
}
file { "$mwdir/extensions/LdapAuthentication/LdapAutoAuthentication.php":
	source => "puppet:///modules/mediawiki/LdapAuthentication/LdapAutoAuthentication.php"
}

exec { "configure_mediawiki.pl":
	command => "/etc/puppet/modules/mediawiki/files/configure_mediawiki.pl",
	unless => "test -e $mwdir/LocalSettings.php",
	require => [ Package[$mwpackage],
				 Package["perl-WWW-Mechanize"],
				 Service["httpd"],
				 File[$mwdir] ]
}

file { "$mwdir/LdapAuthentication_config.php":
	content => template("mediawiki/LdapAuthentication_config.php.erb")
}
exec { "LdapAuthentication config":
	command => "echo -e '\\nrequire_once '\\''LdapAuthentication_config.php'\\'';' >> $mwdir/LocalSettings.php",
	unless => "grep -q LdapAuthentication $mwdir/LocalSettings.php",
	require => Exec["configure_mediawiki.pl"]
}

}
