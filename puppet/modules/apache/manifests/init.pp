class apache {

package { "httpd": ensure => installed }

service { "httpd":
	require => Package["httpd"],
	enable => true,
	ensure => "running"
}

}
