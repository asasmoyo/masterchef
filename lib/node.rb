require 'json'
require 'net/ssh'

require_relative 'chef_version.rb'

module Masterchef
  class Node
    attr_accessor :name, :ip_address, :attributes, :ssh_user, :ssh_port

    def initialize(name, ip_address, opts = {})
      @name = name
      @ip_address = ip_address
      @attributes = opts['attributes'].nil? ? { 'run_list': [] } : opts['attributes']
      @ssh_user = opts['ssh_user']
      @ssh_port = opts['ssh_port']
    end

    def save!
      dump = JSON.pretty_generate({
        'name' => @name,
        'ip_address' => @ip_address,
        'attributes' => @attributes
      })
      File.write("nodes/#{@name}.json", dump)
    end

    def apply_config!(config)
      if @ssh_user.nil?
        @ssh_user = config.ssh_user
      end
      if @ssh_port.nil?
        @ssh_port = config.ssh_port
      end
    end

    def ssh_command(cmd, output = nil)
      opts = {}
      if ! @ssh_port.nil?
        opts[:port] = @ssh_port
      end

      # assume command exits successfully
      exit_code = 0

      Net::SSH.start(@ip_address, @ssh_user) do |session|
        session.open_channel do |channel|
          channel.request_pty
          channel.exec(cmd) do |_, success|
            raise 'failed to execute command' unless success

            channel.on_data do |ch, data|
              output << data if output
            end

            channel.on_extended_data do |ch, type, data|
              next unless type == 1
              output << data if output
            end

            channel.on_request("exit-status") do |ch, data|
              exit_code = data.read_long
            end
          end
        end.wait
      end

      exit_code
    end

    def rsync(sources, dest, opts = {})
      if opts['excludes']
        excludes = opts['excludes'].map do |item|
          "--exclude #{item}"
        end
      end

      cmd = <<~EOF
        rsync \
          --rsh "#{ssh_options}" \
          --verbose \
          --archive \
          --compress \
          --checksum \
          #{opts['delete'] ? '--delete --force-delete' : ''} \
          #{excludes ? excludes.join(' ') : ''} \
          #{sources.join(' ')} \
          #{@ssh_user}@#{@ip_address}:#{dest}
      EOF
      puts `#{cmd}`
    end

    def bootstrap
      rsync(['./resources/install.sh'], '/tmp/')
      ssh_command("sudo bash /tmp/install.sh -v #{CHEF_VERSION}", STDOUT)
    end

    def prepare_local_temp_dir!
      `mkdir -vp ./tmp/#{@name}`
    end

    def write_temp_file!(name, content)
      File.write("./tmp/#{@name}/#{name}", content)
    end

    def ssh_options
      "ssh -p #{@ssh_port} -o StrictHostKeyChecking=no -o ControlMaster=auto -o ControlPath=./tmp/.control-#{@name} -o ControlPersist=300"
    end
  end
end
