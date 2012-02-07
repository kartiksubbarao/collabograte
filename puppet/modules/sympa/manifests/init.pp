class sympa {

include collabograte_common
include apache
include postfix
include cyrusimap
require mysql
require openldap

Exec { path => $collabograte_common::path,
	   environment => $collabograte_common::environment, logoutput => true }

$domain = $collabograte_common::domain
# Add lists.$domain as an alias to $domain in /etc/hosts
augeas { "sympa_hosts":
    context => "/files/etc/hosts",
    changes => [
        "set *[canonical = '$domain']/alias[last()+1] lists.$domain"
    ],
    onlyif => "match *[alias = 'lists.$domain'] size == 0"
}

yumrepo { "sympa-ja.org":
	descr => 'RHEL$releasever - Sympa - stable',
	baseurl =>'http://Sympa-JA.org/download/rhel/$releasever/stable/$basearch/',
	gpgcheck => 1,
	gpgkey => "http://Sympa-JA.org/download/RPM-GPG-KEY-sympa-ja_org",
}

package { "perl-Unicode-LineBreak": ensure => installed }
package { "sympa":
	ensure => installed,
	## perl-Unicode-LineBreak and perl-LDAP are not included as dependencies 
	## in the sympa RPM
	require => [ Yumrepo["sympa-ja.org"],
				 Package["perl-Unicode-LineBreak"], Package["perl-LDAP"] ],
	before => [ File["/etc/sympa/auth.conf"],
				File["/etc/sympa/data_sources"],
				File["/etc/sympa/create_list_templates/ldap-public"],
				File["/etc/sympa/create_list_templates/ldap-private"],
				File["/usr/share/sympa/default/scenari/send.intranet"] ],
}
package { "sympa-httpd":
	ensure => installed,
	require => Yumrepo["sympa-ja.org"],
	notify => Service["httpd"]
}
package { "mailx": ensure => installed }

service { "sympa":
	enable => true,
	ensure => running,
	hasstatus => true,
	hasrestart => true,
	require => [ Package["sympa"],
				 Exec["configure_sympa.pl"],
				 File["/etc/sympa/data_sources"],
				 File["/usr/share/sympa/default/scenari/send.intranet"] ]
}

file { "/etc/sympa/auth.conf": content => template("sympa/auth.conf.erb") }
file { "/etc/sympa/data_sources": ensure => directory }
file { "/etc/sympa/data_sources/owner_ldap.incl": content => template("sympa/owner_ldap.incl.erb") }
file { "/etc/sympa/create_list_templates/ldap-public": ensure => directory }
file { "/etc/sympa/create_list_templates/ldap-public/config.tt2": content => template("sympa/ldap-public/config.tt2.erb") }
file { "/etc/sympa/create_list_templates/ldap-public/comment.tt2": source => "puppet:///modules/sympa/ldap-public/comment.tt2" }
file { "/etc/sympa/create_list_templates/ldap-private": ensure => directory }
file { "/etc/sympa/create_list_templates/ldap-private/config.tt2": content => template("sympa/ldap-private/config.tt2.erb") }
file { "/etc/sympa/create_list_templates/ldap-private/comment.tt2": source => "puppet:///modules/sympa/ldap-private/comment.tt2" 
}
## This file should be in /etc/sympa/scenari, which should override
## the version in /usr/share/sympa/default/scenari, but it doesn't seem to 
## work. Possible bug or packaging issue
file { "/usr/share/sympa/default/scenari/send.intranet":
	content => template("sympa/send.intranet.erb"),
	require => Package["sympa"]
}

augeas { "sympa_postfix_main":
	context => "/files/etc/postfix/main.cf",
	changes => [
		"set sympa_destination_recipient_limit 1",
		"set sympabounce_destination_recipient_limit 1",
		## Enhance Augeas postfix lens to support postfix "array" parameters so
		## that we can append to them instead of overwriting them. For example:
		## set transport_maps/[last()+1] regexp:...
		'set transport_maps "regexp:$config_directory/sympa_transport_regexp"',
		'set virtual_alias_maps "regexp:$config_directory/sympa_virtual_regexp"'
	],
	notify => Service["postfix"],
	onlyif => "match sympa_destination_recipient_limit size == 0"
}

augeas { "sympa_postfix_master":
	context => "/files/etc/postfix/master.cf",
	changes => [
		"set sympa/type unix",
		"set sympa/private -",
		## Spelling error in the Augeas postfix lens
		## https://fedorahosted.org/augeas/ticket/234
		"set sympa/unpriviliged n",
		"set sympa/chroot n",
		"set sympa/wakeup 0",
		"set sympa/limit 0",
		'set sympa/command "pipe flags=R user=sympa argv=/usr/libexec/sympa/queue ${recipient}"',
		"set sympabounce/type unix",
		"set sympabounce/private -",
		## Spelling error in the Augeas postfix lens
		## https://fedorahosted.org/augeas/ticket/234
		"set sympabounce/unpriviliged n",
		"set sympabounce/chroot n",
		"set sympabounce/wakeup 0",
		"set sympabounce/limit 0",
		'set sympabounce/command "pipe flags=R user=sympa argv=/usr/libexec/sympa/bouncequeue ${recipient}"'
	],
	notify => Service["postfix"],
	onlyif => "match sympa size == 0"
}

file { "/etc/postfix/sympa_transport_regexp":
	content => template("sympa/sympa_transport_regexp.erb")
}
exec { "postmap /etc/postfix/sympa_transport_regexp":
	subscribe => File["/etc/postfix/sympa_transport_regexp"],
	notify => Service["postfix"],
	refreshonly => true
}

file { "/etc/postfix/sympa_virtual_regexp":
	content => template("sympa/sympa_virtual_regexp.erb")
}
exec { "postmap /etc/postfix/sympa_virtual_regexp":
	subscribe => File["/etc/postfix/sympa_virtual_regexp"],
	notify => Service["postfix"],
	refreshonly => true
}

exec { "configure_sympa.pl":
	command => "/etc/puppet/modules/sympa/files/configure_sympa.pl",
	unless => "test -d /var/lib/mysql/sympa",
	require => [ Package["sympa"], Package["sympa-httpd"],
			 File["/etc/sympa/create_list_templates/ldap-public/config.tt2"],
			 File["/etc/sympa/create_list_templates/ldap-private/config.tt2"],
			 File["/etc/sympa/data_sources/owner_ldap.incl"],
				 Package["perl-DBD-MySQL"], Package["perl-LDAP"] ],
	notify => [ Service["sympa"], Service["httpd"] ]
}

}
