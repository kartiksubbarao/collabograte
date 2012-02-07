class collabograte_common {

$path = "/usr/bin:/sbin:/usr/sbin:/bin"
$domain = 'example.com'
$ldap_basedn = "dc=example,dc=com"
$ldap_rootdn = "cn=admin,$ldap_basedn"
$ldap_rootpw = "admin123"
$mysql_rootpw = "admin123"
$environment = [ "PATH=/usr/bin:/sbin:/usr/sbin:/bin",
				 "COLLABOGRATE_DOMAIN=$domain",
				 "COLLABOGRATE_BASEDN=$ldap_basedn",
				 # Admin password for generic purposes
				 "COLLABOGRATE_ADMIN_PASSWORD=admin123",
				 # LDAP rootdn and password
				 "COLLABOGRATE_ROOTDN=$ldap_rootdn",
				 "COLLABOGRATE_ROOTDN_PASSWORD=$ldap_rootpw",
				 # Application specific passwords
				 "COLLABOGRATE_MEDIAWIKI_PASSWORD=wiki123",
				 "COLLABOGRATE_MYSQL_ROOTPASSWORD=$mysql_rootpw",
				 "COLLABOGRATE_WORDPRESS_ADMINPASSWORD=admin123" ]

Exec { path => $path, environment => $environment, logoutput => true }

$packagelist = [ "perl-ExtUtils-MakeMaker", "perl-Archive-Tar",
				 "perl-CPANPLUS", "perl-WWW-Mechanize", "perl-LDAP",
				 "perl-DBD-MySQL", "rsyslog" ]
package { $packagelist: ensure => installed }

service { "rsyslog": require => Package["rsyslog"], enable => true }
exec { "rsyslog_config":
	command => 'bash -c "echo \'\$IncludeConfig /etc/rsyslog.d/*.conf\' >> /etc/rsyslog.conf; mkdir /etc/rsyslog.d"',
	unless => "test -d /etc/rsyslog.d",
	require => Package["rsyslog"],
	notify => Service["rsyslog"]
}

}
