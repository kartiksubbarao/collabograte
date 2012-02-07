class postfix {

include collabograte_common

package { "postfix": ensure => installed }

service { "postfix":
	require => Package["postfix"], 
	enable => true,
	ensure => running
}

augeas { "postfix_main":
	context => "/files/etc/postfix/main.cf",
	changes => [
		"set smtp_host_lookup native",
		"set recipient_delimiter +",
		"set inet_interfaces all",
	],
	notify => Service["postfix"],
	onlyif => "match smtp_host_lookup size == 0"
}

}
