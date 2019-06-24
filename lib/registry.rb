require_relative 'node.rb'

module Masterchef
  class Registry
    class << self
      def node_by_name(name)
        file = File.read("./nodes/#{name}.json")
        parsed = JSON.parse(file)
        opts = {
          'ssh_user' => parsed['ssh_user'],
          'ssh_port' => parsed['ssh_port'],
          'attributes' => parsed['attributes']
        }
        Node.new(parsed['name'], parsed['ip_address'], opts)
      end

      def add_node(name, ip_address)
        Node.new(name, ip_address)
      end
    end
  end
end
