# yb

#### Table of Contents

1. [Overview](#overview)
2. [Instructions](#instructions)
3. [Screencast Demo](#screencast-demo)
4. [Ehnancements](#enhancements)

---

## Overview

Wordpress "hello world" infrastructure on AWS using Docker.  Nagios monitoring configs are created for imaginary nagios server instance.  Iptables and ec2 security groups used for firewalling.  Puppet used to provision and manage all components.  Puppet master is hosted on a separate system currently outside AWS.

Wordpress infrastructure on AWS using Docker (ubuntu 14.04 host) on AWS.  

The infrastructure is comprised of:

  * AWS
    * EC2
      * t2.micro instance - ubuntu-trusty-14.04-amd64-server-20150325 (ami-d05e75b8)
    * RDS
      * db.t2.micro instance - MySQL database
    * Security group 
      * MySQL is exposed to all systems within the same security group.
      * Ports 22,80,443 are permitted from my home ISP connection.
    * Key Pair
      * New key pair created for this environment.

  * Docker - Applicaiton container engine.  
    * Docker v1.7.1 used (inherited from ubutu LTS release)
    * Wordpress official image used - https://hub.docker.com/_/wordpress/

  * IPtables - host firewall
    * Restrict access to my home IP address only
    * Defense in depth.  Protect against security group misconfiguration, etc.

  * Nagios - monitoring
    * Basic configuration files generated by puppet
  
  * Puppet - Configuration management.  Set up to perform initial server configuration and retain ability to manage configuration over time.
    * Managed resources
      * Package repositories
      * IPtables
      * Docker
      * Nagios  

    * Modules used:
      * puppetlabs/firewall
      * garethr/docker

---

## Instructions

Database prep:

Create an RDS MySQL instance 
  * Make note of of the admin credentials (securly).  You'll need them later 
  * Create or associate with a security group.  All wordpress related instances will need to be in the same security group.
  * Log in with the MySQL administrator/root level account from a system permitted to connect.  (controlled by security group)
    * Create a wordpress database 
    * Create a wordpress user for the application to connect as

    # #mysql -h yourhost.us-east-1.rds.amazonaws.com -u root -p
    #
    # mysql> CREATE DATABASE wordpress;
    #
    # mysql> GRANT ALL PRIVILEGES ON `wordpress`.* TO 'wordpress'@'%' identified by 'PASSWORD_HERE';

Create an Ubuntu EC2 instance using image ubuntu-trusty-14.04-amd64-server-20150325 (ami-d05e75b8)

Supply user-data to enable hand-off to puppet on boot.

    #cloud-config
    #
    # add security patches and bug fixes
    package_update: true
    package_upgrade: true
    #
    # install puppet
    packages:
     - puppet
    #
    # associate an IPv4 address with that puppet name
    # be careful not to add another line after every reboot
    bootcmd:
     - grep puppet /etc/hosts || echo 71.19.144.24 puppet >> /etc/hosts
     - puppet agent --enable
     - update-rc.d puppet enable
     - wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb
     - dpkg -i puppetlabs-release-trusty.deb
     - apt-get update
     - sed -i '/\[main\]/a waitforcert=5' /etc/puppet/puppet.conf
     - sed -i 's/^START=no/START=yes/' /etc/default/puppet
    #
    # clean up
    final_message: 'The Puppet agent is ready.'
    power_state:
     mode: reboot
     message: Rebooting
     timeout: 30

Associated with a security group that allows SSH, HTTP and HTTPS access from your location as well as access to your RDS mysql db

Launch the instance.

Wait for the newly created puppet agent to request a certificate from the puppet master and sign the certificate.

Once the certificate has been signed the puppet run will begin.  Puppet run progress can be seen in /var/log/messages.

After the puppet run has finished connect to the EC2 instances public IP via HTTP.  You will see a hello world message indicating which app instance served the request.  Requests are load balanced in a round robin fashion so you should see the app instance change when reloading the site.

---

## Screencast Demo

---

## Enhancements 

Future enhancements and known limitations

  * Tested on Ubunutu 14.04 only

  * Node classification - kept simple for demo purposes by using default node, should be split into separate configs and use external node classifier at scale.

  * Nagios config files are only written (on second puppet run due to exported resources).  Alerting will require matching nagios server configuration.

  * Speed - This configuration favors simplicity over speed.

  * Wordpress container is useful for simple POC work - need to incorporate volume support and other functionality to run at scale

  * Load balancing - This config could be load balanced after integration of central storage repo and load balancer
