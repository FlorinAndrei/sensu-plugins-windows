#! /usr/bin/env ruby
#
#   uptime-windows
#
# DESCRIPTION:
#   This is metrics which outputs the uptime in seconds in Graphite acceptable format.
#
# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Windows
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: socket
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Copyright 2015 <miguelangel.garcia@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'socket'
require 'time'
require 'csv'

class UptimeMetric < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to .$interface.$metric',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.system.network"
  option :interface,
         description: 'Metric naming scheme, text to prepend to .$parent.$child',
         long: '--interface INTERFACE',
         default: '*'

  def run
    interface = config[:interface]
    timestamp = Time.now.utc.to_i
    IO.popen("typeperf -sc 1 \"\\Network Interface(#{interface})\\*\" ") do |io|
      CSV.parse(io.read, headers: true) do |row|
        row.each do |k, v|
          next unless v && k
          break if v.start_with? 'Exiting'

          path = k.split('\\')
          ifz = path[3]
          metric = path[4]
          next unless ifz && metric

          ifz_name = ifz[18, ifz.length - 19].gsub('.', ' ')
          value = format('%.2f', v.to_f)
          name = [config[:scheme], ifz_name, metric].join('.').gsub(' ', '_').tr('{}', '').tr('[]', '')

          output name, value, timestamp
        end
      end
    end
    ok
  end
end
