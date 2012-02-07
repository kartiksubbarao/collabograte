class ejabberd {

include collabograte_common
require openldap

Exec { path => $collabograte_common::path,
	   environment => $collabograte_common::environment, logoutput => true }

$domain = $collabograte_common::domain
# Add jabber.$domain as an alias to $domain in /etc/hosts
augeas { "ejabberd_hosts":
    context => "/files/etc/hosts",
    changes => [
        "set *[canonical = '$domain']/alias[last()+1] jabber.$domain"
    ],
    onlyif => "match *[alias = 'jabber.$domain'] size == 0"
}

package { "ejabberd": ensure => installed }

service { "ejabberd":
	enable => true,
	ensure => running,
	hasstatus => true,
	hasrestart => true,
	require => [ Package["ejabberd"],
				 Augeas["ejabberd_hosts"],
				 File["/etc/ejabberd/ejabberd.cfg"] ]
}

file { "/etc/ejabberd/ejabberd.cfg":
	owner => 'ejabberd', group => 'ejabberd',
	content => template("ejabberd/ejabberd.cfg.erb"),
	require => Package["ejabberd"],
	notify => Service["ejabberd"]
}


}
