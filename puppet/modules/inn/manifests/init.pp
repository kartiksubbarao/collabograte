class inn {

include collabograte_common
require sympa

Exec { path => $collabograte_common::path,
	   environment => $collabograte_common::environment, logoutput => true }

$packagelist = [ "perl-TimeDate" ]
package { $packagelist: ensure => installed }

# These Perl modules are not available as RPMs, so we install them with CPANPLUS
exec { "install_inn_cpanp":
	command => "cpanp -i News::Article News::Gateway",
	unless => "perl -MNews::Article -MNews::Gateway -e 1 2>/dev/null",
	## These should be added as an RPM dependency for perl-CPANPLUS
	require => [ Package["perl-ExtUtils-MakeMaker"],Package["perl-Archive-Tar"],
				 Package["perl-CPANPLUS"] ]
}

# Add news.$domain as an alias to $domain in /etc/hosts
$domain = $collabograte_common::domain
augeas { "inn_hosts":
    context => "/files/etc/hosts",
    changes => [
        "set *[canonical = '$domain']/alias[last()+1] news.$domain"
    ],
    onlyif => "match *[alias = 'news.$domain'] size == 0"
}

yumrepo { "puias":
	descr => 'PUIAS addons Base $releasever - $basearch',
	baseurl => 'http://puias.princeton.edu/data/puias/$releasever/$basearch/os/Addons/',
	gpgcheck => 1,
	gpgkey => "http://puias.princeton.edu/data/puias/$operatingsystemrelease/$hardwareisa/os/RPM-GPG-KEY-puias",
}

package { "inn":
	ensure => installed,
	require => Yumrepo["puias"],
	before => File["/etc/news/newsfeeds"]
}
## Create /var/run/news, doesn't seem to be created by the RPM. Need to
## report this to the PUIAS folks
exec { "sh -c 'mkdir /var/run/news; chown news:news /var/run/news'":
	unless => "test -d /var/run/news",
	require => Package["inn"],
	before => Service["innd"]
}
file { "/etc/news/readers.conf":
	owner => 'news', group => 'news',
	source => "puppet:///modules/inn/readers.conf",
	require => Package["inn"],
	notify => Service["innd"]
}

service { "innd":
	enable => true,
	ensure => running,
	hasstatus => true,
	hasrestart => true,
	require => Package["inn"]
}

file { "/etc/postfix/inn_virtual_regexp":
	content => template("inn/inn_virtual_regexp.erb")
}
exec { "postmap /etc/postfix/inn_virtual_regexp":
	subscribe => File["/etc/postfix/inn_virtual_regexp"],
	notify => Service["postfix"],
	refreshonly => true
}

file { "/usr/local/bin/ldap_mail2news.pl":
	mode => 755,
	content => template("inn/ldap_mail2news.pl.erb")
}
file { "/usr/local/bin/ldap_news2mail.pl":
	mode => 755,
	content => template("inn/ldap_news2mail.pl.erb")
}
file { "/etc/news/newsfeeds": source => "puppet:///modules/inn/newsfeeds" }

mailalias { "mail2news":
	name => "mail2news",
	recipient => "| /usr/local/bin/ldap_mail2news.pl",
	ensure => present,
	notify => Exec["newaliases"]
}
exec { "newaliases": refreshonly => true }

exec { "configure_inn.pl":
	command => "/etc/puppet/modules/inn/files/configure_inn.pl",
	unless => "grep -q inn_virtual_regexp /etc/postfix/main.cf",
	require => [ Service["innd"],
			File["/etc/postfix/inn_virtual_regexp"],
			Package["perl-LDAP"], Package["perl-TimeDate"] ]
}

}
