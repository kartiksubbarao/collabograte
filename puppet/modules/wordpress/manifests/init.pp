class wordpress {

include collabograte_common
include apache
include openldap
require mysql

package { "wordpress":
	ensure => installed,
	notify => Service["httpd"]
}

Exec { path => $collabograte_common::path,
	   environment => $collabograte_common::environment, logoutput => true }

## Ideally these would be packaged in a wordpress-plugin-wpdirauth rpm
file { "/usr/share/wordpress/wp-content/plugins/wpdirauth":
	ensure => directory,
	require => Package["wordpress"]
}
file { "/usr/share/wordpress/wp-content/plugins/wpdirauth/wpDirAuth.php":
	source => "puppet:///modules/wordpress/wpDirAuth.php"
}

file { "/usr/share/wordpress/wp-content/blogs.dir":
	ensure => directory,
	owner => "apache",
	require => Package["wordpress"]
}

exec { "configure_wordpress.pl":
	command => "/etc/puppet/modules/wordpress/files/configure_wordpress.pl",
	unless => "test -e /usr/share/wordpress/.htaccess",
	require => [ Package["wordpress"],
				 Package["perl-WWW-Mechanize"],
				 Package["perl-DBD-MySQL"],
				 Package["php-ldap"],
				 Service["httpd"],
				 File["/usr/share/wordpress/wp-content/plugins/wpdirauth"],
				 File["/usr/share/wordpress/wp-content/blogs.dir"] ]
}

}
