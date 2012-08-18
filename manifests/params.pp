class nginx::params {
  $confdir  = '/etc/nginx'

  $vhostdir = "vhosts.d"
  $appsdir  = "webapps.d"
  $ssldir   = "ssl"

  $sslcert  = "nginx.crt"
  $sslkey   = "nginx.key"

  $htmldir  = '/srv/www/htdocs'

  $user     = 'nginx'
  $group    = 'nginx'

  $worker_proc = $::physicalprocessorcount
}
