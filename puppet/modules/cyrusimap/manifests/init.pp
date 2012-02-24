class cyrusimap {

include collabograte_common
include apache
include postfix
require openldap

Exec { path => $collabograte_common::path,
	   environment => $collabograte_common::environment, logoutput => true }

package { "cyrus-imapd":
	ensure => installed,
	require => Package["cyrus-sasl"]	
}
package { "cyrus-sasl": ensure => installed }
package { "squirrelmail": ensure => installed }
file { "/etc/squirrelmail/config_local.php":
	require => Package["squirrelmail"],
	content => template("cyrusimap/config_local.php.erb")
}
file { "/etc/httpd/conf.d/squirrelmail.conf":
	require => Package["squirrelmail"],
	source => "puppet:///modules/cyrusimap/squirrelmail.httpd.conf",
	notify => Service["httpd"]
}

service { "cyrus-imapd":
	enable => true,
	ensure => running,
	hasstatus => true,
	hasrestart => true,
	require => Package["cyrus-imapd"]
}

service { "saslauthd":
	enable => true,
	ensure => running,
	hasstatus => true,
	hasrestart => true,
	require => Package["cyrus-sasl"]
}

file { "/etc/imapd.conf":
	source => "puppet:///modules/cyrusimap/imapd.conf",
	notify => Service["cyrus-imapd"]
}

augeas { "cyrusimap_postfix_main":
	context => "/files/etc/postfix/main.cf",
	changes => [
		'set local_recipient_maps "proxy:unix:passwd.byname, $alias_maps, ldap:$config_directory/ldap-local.cf"',
		'set fallback_transport lmtp:unix:/var/lib/imap/socket/lmtp',
	],
	notify => Service["postfix"],
	onlyif => "match fallback_transport size == 0"
}

file { "/etc/postfix/ldap-local.cf":
	content => template("cyrusimap/ldap-local.cf.erb"),
	notify => Service["postfix"]
}

file { "/etc/sysconfig/saslauthd":
	source => "puppet:///modules/cyrusimap/saslauthd.sysconfig",
	notify => Service["saslauthd"]
}
file { "/etc/saslauthd.conf":
	content => template("cyrusimap/saslauthd.conf.erb"),
	notify => Service["saslauthd"]
}

}
