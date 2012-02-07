class mysql {

include collabograte_common

Exec { path => $collabograte_common::path,
       environment => $collabograte_common::environment, logoutput => true }

package { "mysql-server": ensure => installed }

service { "mysqld":
	require => Package["mysql-server"],
	enable => true,
	ensure => "running"
}

$mysql_rootpw = $collabograte_common::mysql_rootpw
exec { "mysqladmin":
	command => "mysqladmin -u root password '$mysql_rootpw'",
	require => Service["mysqld"],
	unless => "mysqladmin status 2>&1 | grep -q 'Access denied'"
}

}
