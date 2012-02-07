class openldap {

include collabograte_common

Exec { path => $collabograte_common::path,
	   environment => $collabograte_common::environment, logoutput => true }

$packagelist = ["openldap", "openldap-clients", "openldap-servers", "php-ldap"]
package { $packagelist: ensure => installed }

service { "slapd":
	enable => true,
	ensure => running,
	hasstatus => true,
	hasrestart => true,
	require => [ Package["openldap-servers"],
				 Exec["slapadd"], 
				 File["/etc/openldap/slapd.conf"],
				 File["/etc/rsyslog.d/openldap.conf"],
				 File["/etc/openldap/ldap.conf"],
				 File["/etc/openldap/schema/ns-mail.schema"] ]
}

file { "/etc/openldap": ensure => directory }
file { "/etc/openldap/slapd.d":
	ensure => absent,
	force => true,
	require => Package["openldap-servers"],
}
file { "/etc/openldap/slapd.conf":
	content => template("openldap/slapd.conf.erb"),
	require => Package["openldap-servers"],
	notify => Service["slapd"]
}
file { "/etc/openldap/ldap.conf":
	content => template("openldap/ldap.conf.erb"),
	require => Package["openldap-servers"]
}
file { "/etc/openldap/schema/ns-mail.schema":
	source => "puppet:///modules/openldap/ns-mail.schema",
	require => Package["openldap-servers"]
}
file { "/var/log/openldap": ensure => directory }
file { "/etc/rsyslog.d/openldap.conf":
	source => "puppet:///modules/openldap/rsyslog.conf",
	require => Exec["rsyslog_config"],
	notify => Service["rsyslog"]
}
file { "/etc/logrotate.d/openldap": source => "puppet:///modules/openldap/openldap.logrotate" }
	
exec { "slapadd":
	command => "/etc/puppet/modules/openldap/files/slapadd.sh",
	user => 'ldap',
	creates => "/var/lib/ldap/id2entry.bdb",
	require => [ Package["openldap-servers"],
				 File["/etc/openldap/slapd.d"],
				 File["/etc/openldap/slapd.conf"],
				 File["/etc/openldap/schema/ns-mail.schema"] ],
	notify => Service["slapd"],
}

}
