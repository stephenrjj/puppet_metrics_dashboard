# @summary Apply this class to compilers running PuppetDB to configure Telegraf and collect puppetserver and puppetdb metrics
#
# @param influxdb_urls
#   An Array containing urls defining InfluxDB instances for Telegraf.
#
# @param timeout
#   Default timeout of http calls.  Defaults to 5 seconds
#
# @param compiler
#   The FQDN of the compiler / master.  Defaults to the FQDN of the server where the profile is applied
#
# @param puppetdb_host
#   Where to query the puppetdb host.  Defaults to localhost.
#
# @param cm_port
#   The port that the puppetserver service listens on on your compiler.  Defaults to 8140
#
# @param db_port
#   The port that the puppetdb service listens on on your compiler.  Defaults to 8081
#
# @param interval
#   The frequency that telegraf will poll puppetserver metrics.  Defaults to '5s'
#
class puppet_metrics_dashboard::profile::dbcompiler::install (

  Array[String] $influxdb_urls,
  String[2] $timeout                                          = lookup('puppet_metrics_dashboard::http_response_timeout'),
  Variant[String,Tuple[String, Integer]] $compiler            = $facts['networking']['fqdn'],
  Variant[String,Tuple[String, Integer]] $puppetdb_host       = 'localhost',
  Integer[1] $cm_port                                         = 8140,
  Integer[1] $db_port                                         = 8081,
  String[2] $interval                                         = '5s',
  Puppet_metrics_dashboard::Puppetdb_metric $puppetdb_metrics = puppet_metrics_dashboard::puppetdb_metrics(),
  ){

  class { 'telegraf':
        interval => $interval,
        logfile  => '/var/log/telegraf/telegraf.log',
        outputs  => {
          'influxdb' => [
            {
              'urls'              => $influxdb_urls,
              'database'          => lookup(puppet_metrics_dashboard::telegraf_db_name),
              'write_consistency' => 'any',
              'timeout'           => '5s',
            },
          ],
        },
      }

  puppet_metrics_dashboard::profile::compiler{$trusted['certname']:
    timeout  => lookup('puppet_metrics_dashboard::http_response_timeout'),
    compiler => $compiler,
    port     => $cm_port,
    interval => $interval,
  }
  puppet_metrics_dashboard::profile::puppetdb{$trusted['certname']:
    timeout            => lookup('puppet_metrics_dashboard::http_response_timeout'),
    puppetdb_host      => $puppetdb_host,
    puppetdb_metrics   => $puppetdb_metrics,
    port               => $db_port,
    interval           => $interval,
    enable_client_cert => false,
  }
}