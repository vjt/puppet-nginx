class nginx (
  $package = 'nginx',
) inherits nginx::params {

  service {'nginx':
    ensure  => running,
    require => Package['nginx'],
  }

  package {'nginx':
    name    => $package,
    ensure  => latest,
  }

  user  {$user:
    ensure  => present,
    uid     => 200,
    gid     => 200,
    comment => 'nginx sandbox',
    home    => $confdir,
    system  => true,
  }
  group {$group:
    ensure => present,
    gid    => 200,
    system => true,
  }

  dir { ['/', $ssldir, $appsdir, $vhostdir]: }

  conf {
    'nginx.conf': template => 'nginx.conf';
    'ssl.conf'  : template => 'ssl.conf';
    'mime.types': source   => 'nginx/mime.types';
  }

  define dir {
    $path = "${nginx::confdir}/${title}"

    file {$path:
      ensure  => directory,
      owner   => $nginx::user,
      group   => $nginx::group,
      mode    => '0700',
      purge   => true,
      backup  => false,
      recurse => true,
    }
  }

  define cert($crt, $key) {
    conf {
      "${nginx::ssldir}/${nginx::sslcert}": source => $crt;
      "${nginx::ssldir}/${nginx::sslkey}":  source => $key;
    }
  }

  define conf($source = '', $template = '', $mode = '0600') {
    $path = "${nginx::confdir}/${title}"

    if $source {
      file {$path:
        ensure  => present,
        owner   => $nginx::user,
        group   => $nginx::group,
        mode    => $mode,
        source  => "puppet:///modules/${source}",
        require => Package['nginx'],
        notify  => Service['nginx'],
      }
    } elsif $template {
      file {$path:
        ensure  => present,
        owner   => $nginx::user,
        group   => $nginx::group,
        mode    => $mode,
        content => template("nginx/${template}.erb"),
        require => Package['nginx'],
        notify  => Service['nginx'],
      }
    } else {
      file {$path:
        ensure  => present,
        owner   => $nginx::user,
        group   => $nginx::group,
        mode    => $mode,
        require => Package['nginx'],
        notify  => Service['nginx'],
      }
    }
  }

  define html($server_name) {
    $root = regsubst($title, '^(.+)/.+$', '\1')
    $src  = regsubst($title, '^.+/(.+)$', '\1')

    file {"${title}.html":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("nginx/${src}.html.erb"),
    }
  }

  define vhost(
    $host  = '',
    $port  = 80,
    $root  = $nginx::htmldir,
    $ssl   = false,
    $prio  = 50,
    $mock  = false,
    $apps  = false,
    $redir = {},
  ) {
    $path = "${nginx::vhostdir}/${prio}_${name}.conf"

    $tpl = $mock ? {
      false   => 'vhost',
      default => 'vhost-mock',
    }

    $server_name = $host ? {
      ''      => $::fqdn,
      default => $host,
    }

    if $apps {
      $hostapps = "${nginx::appsdir}/${name}"
      dir {$hostapps: }
    }

    if ! defined( Html["${root}/403"] ) {
      html {["${root}/403"]: server_name => $server_name}
    }

    if ! defined( Html["${root}/404"] ) {
      html {["${root}/404"]: server_name => $server_name}
    }

    if ! defined( Html["${root}/50x"] ) {
      html {["${root}/50x"]: server_name => $server_name}
    }

    if ! defined( File[$root] ) {
      file {$root: ensure => directory }

      if ! defined( Html["${root}/index"] ) {
        html {["${root}/index"]: server_name => $server_name}
      }
    }

    if ! defined( File["${root}/_default"] ) {
      file {"$root/_default":
        ensure  => directory,
        recurse => true,
        source  => "puppet:///modules/nginx/html",
      }
    }

    conf {$path:
      template => $tpl,
    }
  }
}
