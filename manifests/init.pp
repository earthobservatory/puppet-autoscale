#####################################################
# autoscale class
#####################################################

class autoscale inherits verdi {

  #####################################################
  # install AWS credentials and config
  #####################################################

  file { "/home/$user/.aws":
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => 0700,
  }


  file { "/home/$user/.aws/credentials":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => 0600,
    content => template('autoscale/aws_credentials'),
    replace => false,
  }


  file { "/home/$user/.aws/config":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => 0600,
    content => template('autoscale/aws_config'),
    replace => false,
  }


  file { "/home/$user/.boto":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => 0600,
    content => template('autoscale/boto'),
    replace => false,
  }


  file { "/home/$user/.s3cfg":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => 0600,
    content => template('autoscale/s3cfg'),
    replace => false,
  }

  
  #####################################################
  # install Azure credentials and config
  #####################################################

  file { "/home/$user/.azure":
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => 0700,
  }


  file { "/home/$user/.azure/azure_credentials.json":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => 0600,
    content => template('autoscale/azure_credentials.json'),
    replace => false,
  }


  file { "/home/$user/.azure/config":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => 0600,
    content => template('autoscale/azure_config'),
    replace => false,
  }


  #####################################################
  # install gof3r config
  #####################################################

  file { "/home/$user/.gof3r.ini":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => 0644,
    content => template('autoscale/gof3r.ini'),
    replace => false,
  }


  #####################################################
  # install docker-compose
  #####################################################

  file { '/usr/local/bin':
    ensure  => directory,
    mode    => 0755,
  }


  file { "/usr/local/bin/docker-compose":
    ensure  => file,
    mode    => 0755,
    source => 'puppet:///modules/autoscale/docker-compose',
    require => [
        File['/usr/local/bin'],
    ],
  }


  #####################################################
  # harikiri service
  #####################################################

  file { '/etc/systemd/system/harikiri.d':
    ensure  => directory,
    mode    => 0755,
  }


  file { '/etc/systemd/system/harikiri.d/harikiri.py':
    ensure  => present,
    mode    => 0755,
    content => template('autoscale/harikiri.py'),
    require => File['/etc/systemd/system/harikiri.d'],
  }


  file { '/etc/systemd/system/harikiri.service':
    ensure  => present,
    mode    => 0644,
    content => template('autoscale/harikiri.service'),
    require => File['/etc/systemd/system/harikiri.d/harikiri.py'],
    notify  => Exec['daemon-reload'],
  }


  service { 'harikiri':
    ensure  => stopped,
    enable  => true,
    require => [
                File['/etc/systemd/system/harikiri.service'],
                File["/home/$user/.aws/credentials"],
                File["/home/$user/.aws/config"],
                Exec['daemon-reload'],
               ],
  }


  # disable requiretty because harikiri running via systemd
  # fails to run 'sudo shutdown -h now'
  augeas { "turn_off_sudo_requiretty":
    changes => [
      'set /files/etc/sudoers/Defaults[*]/requiretty/negate ""',
    ],
  }


  #####################################################
  # spot_termination_detector service
  #####################################################

  file { '/etc/systemd/system/spot_termination_detector.d':
    ensure  => directory,
    mode    => 0755,
  }


  file { '/etc/systemd/system/spot_termination_detector.d/spot_termination_detector.py':
    ensure  => present,
    mode    => 0755,
    content => template('autoscale/spot_termination_detector.py'),
    require => File['/etc/systemd/system/spot_termination_detector.d'],
  }


  file { '/etc/systemd/system/spot_termination_detector.service':
    ensure  => present,
    mode    => 0644,
    content => template('autoscale/spot_termination_detector.service'),
    require => File['/etc/systemd/system/spot_termination_detector.d/spot_termination_detector.py'],
    notify  => Exec['daemon-reload'],
  }


  service { 'spot_termination_detector':
    ensure  => stopped,
    enable  => true,
    require => [
                File['/etc/systemd/system/spot_termination_detector.service'],
                File["/home/$user/.aws/credentials"],
                File["/home/$user/.aws/config"],
                Exec['daemon-reload'],
               ],
  }


  #####################################################
  # set instance shutdown behavior to terminate
  #####################################################

  file { '/etc/systemd/system/instance_shutdown_behavior.d':
    ensure  => directory,
    mode    => 0755,
  }


  file { '/etc/systemd/system/instance_shutdown_behavior.d/set_terminate.sh':
    ensure  => present,
    mode    => 0755,
    content => template('autoscale/set_terminate.sh'),
    require => File['/etc/systemd/system/instance_shutdown_behavior.d'],
  }


  file { '/etc/systemd/system/instance_shutdown_behavior.service':
    ensure  => present,
    mode    => 0644,
    content => template('autoscale/instance_shutdown_behavior.service'),
    require => File['/etc/systemd/system/instance_shutdown_behavior.d/set_terminate.sh'],
    notify  => Exec['daemon-reload'],
  }


  service { 'instance_shutdown_behavior':
    ensure  => stopped,
    enable  => true,
    require => [
                File['/etc/systemd/system/instance_shutdown_behavior.service'],
                File["/home/$user/.aws/credentials"],
                File["/home/$user/.aws/config"],
                Exec['daemon-reload'],
               ],
  }


  #####################################################
  # provision-verdi service
  #####################################################

  file { '/etc/systemd/system/provision-verdi.d':
    ensure  => directory,
    mode    => 0755,
  }


  file { '/etc/systemd/system/provision-verdi.d/provision-verdi.sh':
    ensure  => present,
    mode    => 0755,
    content => template('autoscale/provision-verdi.sh'),
    require => File['/etc/systemd/system/provision-verdi.d'],
  }


  file { '/etc/systemd/system/provision-verdi.service':
    ensure  => present,
    mode    => 0644,
    content => template('autoscale/provision-verdi.service'),
    require => File['/etc/systemd/system/provision-verdi.d/provision-verdi.sh'],
    notify  => Exec['daemon-reload'],
  }


  service { 'provision-verdi':
    ensure  => stopped,
    enable  => true,
    require => [
                File['/etc/systemd/system/provision-verdi.service'],
                File["/home/$user/.aws/credentials"],
                File["/home/$user/.aws/config"],
                File["/home/$user/.gof3r.ini"],
                Exec['daemon-reload'],
               ],
  }


  #####################################################
  # start-verdi service
  #####################################################

  file { '/etc/systemd/system/start-verdi.d':
    ensure  => directory,
    mode    => 0755,
  }


  file { '/etc/systemd/system/start-verdi.d/start-verdi.sh':
    ensure  => present,
    mode    => 0755,
    content => template('autoscale/start-verdi.sh'),
    require => File['/etc/systemd/system/start-verdi.d'],
  }


  file { '/etc/systemd/system/start-verdi.service':
    ensure  => present,
    mode    => 0644,
    content => template('autoscale/start-verdi.service'),
    require => File['/etc/systemd/system/start-verdi.d/start-verdi.sh'],
    notify  => Exec['daemon-reload'],
  }


  service { 'start-verdi':
    ensure  => stopped,
    enable  => true,
    require => [
                File['/etc/systemd/system/start-verdi.service'],
                File["/home/$user/.aws/credentials"],
                File["/home/$user/.aws/config"],
                File["/home/$user/.gof3r.ini"],
                Exec['daemon-reload'],
               ],
  }


  #####################################################
  # docker-ephemeral-lvm service
  #####################################################

  file { '/etc/systemd/system/docker-ephemeral-lvm.d':
    ensure  => directory,
    mode    => 0755,
  }


  file { '/etc/systemd/system/docker-ephemeral-lvm.d/docker-ephemeral-lvm.sh':
    ensure  => present,
    mode    => 0755,
    content => template('autoscale/docker-ephemeral-lvm.sh'),
    require => File['/etc/systemd/system/docker-ephemeral-lvm.d'],
  }


  file { '/etc/systemd/system/docker-ephemeral-lvm.service':
    ensure  => present,
    mode    => 0644,
    content => template('autoscale/docker-ephemeral-lvm.service'),
    require => File['/etc/systemd/system/docker-ephemeral-lvm.d/docker-ephemeral-lvm.sh'],
    notify  => Exec['daemon-reload'],
  }


  service { 'dm-event':
    ensure  => running,
    enable  => true,
    require => Exec['daemon-reload'],
  }


  service { 'docker-ephemeral-lvm':
    ensure  => stopped,
    enable  => true,
    require => [
                Service['dm-event'],
                File['/etc/systemd/system/docker-ephemeral-lvm.service'],
                File["/home/$user/.aws/credentials"],
                File["/home/$user/.aws/config"],
                Exec['daemon-reload'],
               ],
  }


  #####################################################
  # supervisord service
  #####################################################

  #file { '/etc/systemd/system/supervisord.service':
  #  ensure  => present,
  #  mode    => 0644,
  #  content => template('autoscale/supervisord.service'),
  #  notify  => Exec['daemon-reload'],
  #}


  #service { 'supervisord':
  #  ensure  => stopped,
  #  enable  => true,
  #  require => [
  #              File['/etc/systemd/system/supervisord.service'],
  #              File["/home/$user/.aws/credentials"],
  #              File["/home/$user/.aws/config"],
  #              Service['docker-ephemeral-lvm'],
  #              Service['provision-verdi'],
  #              Exec['daemon-reload'],
  #             ],
  #}


  #####################################################
  # disable httpd
  #####################################################

  if defined(Service["httpd"]) {
    Service['httpd'] {
      ensure     => stopped,
      enable     => false,
      hasrestart => true,
      hasstatus  => true,
      require => [
                  Exec['daemon-reload'],
                 ], 
    }
  }

  #####################################################
  # remove docker to mitigate Azure quirks
  #####################################################

  exec { 'remove_docker':
    command => '/bin/yum remove docker-ce -y; /bin/nmcli connection delete docker0 || true',
    require => Service['docker'],
    returns => 0,
  }


}
