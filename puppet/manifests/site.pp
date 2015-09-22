
node default { 

# --- Begin firewall configuration section ---
#

# Use the puppetlabs-firewall module to set up a basic host firewall using iptables
class { 'firewall': }

# Allow related stateful input traffic and ssh from keith's house
firewall {
  "000 Allow related traffic":
    proto   => 'all',
    state => ['RELATED', 'ESTABLISHED'],
    action  => 'accept';

  '001 accept all trafic on lo interface':
    proto   => 'all',
    iniface => 'lo',
    action  => 'accept';

  "010 Allow SSH":
    port     => 22,
    proto    => "tcp",
    source    => '98.110.209.133',
    action   => "accept";

  "010 Allow inbound tcp port 80":
    port     => 80,
    proto    => "tcp",
    source    => '98.110.209.133',
    action   => "accept";

  "010 Allow inbound tcp port 443 ":
    port     => 443,
    proto    => "tcp",
    source    => '98.110.209.133',
    action   => "accept";
}

# Set default input policy to drop
firewallchain { 'INPUT:filter:IPv4':
  purge  => true,
  policy => drop;
}

#
# --- End firewall configuation section ---

# --- Begin package/repo section ---
#

file {
  '/etc/apt/sources.list.d/puppetlabs.list':
    ensure => present,
    content => template("puppetlabs.list");

  '/etc/apt/trusted.gpg.d/puppetlabs-nightly-keyring.gpg':
    ensure => present,
    content => template("puppetlabs-nightly-keyring.gpg");

  '/etc/apt/trusted.gpg.d/puppetlabs-keyring.gpg':
    ensure => present,
    content => template("puppetlabs-keyring.gpg");
}

package { "facter":
  ensure => latest,
  require => File["/etc/apt/sources.list.d/puppetlabs.list", "/etc/apt/trusted.gpg.d/puppetlabs-nightly-keyring.gpg", "/etc/apt/trusted.gpg.d/puppetlabs-keyring.gpg" ],
}

#
# --- End package/repo section ---


# --- Begin docker configuration section ---
#

# use the garethr-docker module to manage docker images and processes
class { 'docker':
  version => '1.7.1',
}

docker::image { 'wordpress':
  image_tag => 'latest'
}

docker::run { 'wordpress':
  image   => 'wordpress',
  env => ['WORDPRESS_DB_HOST=wordpress.cv4zohn9blle.us-east-1.rds.amazonaws.com:3306', 'WORDPRESS_DB_NAME=wordpress_yb', 'WORDPRESS_DB_USER=wordpress_yb', 'WORDPRESS_DB_PASSWORD="secret_password"'],
  ports   => ['80:80','443:443'],
}

#
# --- End docker configuration section ---

# --- Begin nagios configuration section ---
#

  # collect resources and populate /etc/nagios/nagios_*.cfg for nagios server
  Nagios_host <<||>>
  Nagios_service <<||>>
  Nagios_hostextinfo <<||>>

  file { "/etc/nagios":
	ensure => directory,
  }

  @@nagios_host { $ec2_public_hostname:
    ensure => present,
    alias => $fqdn,
    address => $ec2_public_ipv4,
    use     => "generic-host",
    hostgroups => "default",
    require => [ Package["facter"], File["/etc/nagios"] ],
  } 

  @@nagios_service { "check_ping_${ec2_public_hostname}":
    check_command       => "check_ping!100.0,20%!500.0,60%",
    use                 => "generic-service",
    host_name           => "$ec2_public_hostname",
    notification_period => "24x7",
    service_description => "${ec2_public_hostname} ping status",
    hostgroup_name => "default",
    require => [ Package["facter"], File["/etc/nagios"] ],
  }

  @@nagios_service { "check_http_status_${ec2_public_hostname}":
    check_command       => "check_http_status",
    use                 => "generic-service",
    host_name           => "$ec2_public_hostname",
    notification_period => "24x7",
    service_description => "${ec2_public_hostname} http status",
    hostgroup_name => "default",
    require => [ Package["facter"], File["/etc/nagios"] ],
  }

  @@nagios_service { "check_docker_${ec2_public_hostname}":
    check_command       => "check_docker",
    use                 => "generic-service",
    host_name           => "$ec2_public_hostname",
    notification_period => "24x7",
    service_description => "${ec2_public_hostname} docker status",
    hostgroup_name => "default",
    require => [ Package["facter"], File["/etc/nagios"] ],
  }

  @@nagios_service { "check_disk_${ec2_public_hostname}":
    check_command       => "check_disk",
    use                 => "generic-service",
    host_name           => "$ec2_public_hostname",
    notification_period => "24x7",
    service_description => "${ec2_public_hostname} disk status",
    hostgroup_name => "default",
    require => [ Package["facter"], File["/etc/nagios"] ],
  }

  @@nagios_service { "check_load_${ec2_public_hostname}":
    check_command       => "check_load",
    use                 => "generic-service",
    host_name           => "$ec2_public_hostname",
    notification_period => "24x7",
    service_description => "${ec2_public_hostname} system load",
    hostgroup_name => "default",
    require => [ Package["facter"], File["/etc/nagios"] ],
  }

  @@nagios_service { "check_iowait_${ec2_public_hostname}":
    check_command       => "check_iowait",
    use                 => "generic-service",
    host_name           => "$ec2_public_hostname",
    notification_period => "24x7",
    service_description => "${ec2_public_hostname} iowait status",
    hostgroup_name => "default",
    require => [ Package["facter"], File["/etc/nagios"] ],
  }

#
# --- End nagios configuration section ---

}
