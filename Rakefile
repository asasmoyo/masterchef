require_relative 'lib/config.rb'
require_relative 'lib/registry.rb'
require_relative 'lib/executor.rb'

config = Masterchef::Config.new
config.from_file('config.rb')

namespace :apply do
  desc 'Run chef-solo on all nodes'
  task :all do
    Dir.glob('./nodes/*.json') do |node|
      name = node.sub('./nodes/', '').sub('.json', '')
      node = Masterchef::Registry.node_by_name(name)
      node.apply_config!(config)
      Masterchef::Executor.run(node)
    end
  end
end
