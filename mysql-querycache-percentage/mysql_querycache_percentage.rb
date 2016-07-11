if ENV['MACKEREL_AGENT_PLUGIN_META'] == '1'
  require 'json'

  meta = {
    :graphs => {
      'mysql.QueryCache' => {
        :label   => 'MySQL QueryCache',
        :unit    => 'percentage',
        :metrics => [
          {
            :name  => 'QueryCacheHitPercentage',
            :label => 'QueryCacheHitPercentage'
          }
        ]
      }
    }
  }

  puts '# mackerel-agent-plugin'
  puts meta.to_json
  exit 0
end

require 'yaml'

dir = File.expand_path(File.dirname($0))

config = YAML.load_file("#{dir}/config.yml")


using_column = ['Com_select', 'Qcache_hits']

now = Time.now.to_i
cmd_result = `mysql -h#{config['mysql']['host']} -u#{config['mysql']['user']} -p#{config['mysql']['password']}  -e"SHOW STATUS WHERE Variable_name = 'Com_select' || Variable_name = 'Qcache_hits' || Variable_name = 'Qcache_lowmem_prunes'"`
#puts cmd_result


metrics = {}
cmd_result.split("\n").each_with_index do |line,i|
  separate_line = line.split(/\s+/)

  if using_column.include?(separate_line[0])
    #puts [ "mysql.QueryCache.#{separate_line[0]}", separate_line[1], now ].join("\t")
    metrics[separate_line[0]] = separate_line[1].to_f
  end
end
percent = (metrics['Qcache_hits'] / (metrics['Qcache_hits'] + metrics['Com_select'])) * 100

puts [ "mysql.QueryCache.QueryCacheHitPercentage", percent.round(1), now ].join("\t")

