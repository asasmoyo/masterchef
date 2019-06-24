require 'chef/config'
require 'chef/knife/core/ui'

module Masterchef
  class Executor
    class << self
      Chef::Config[:color] = true

      def ui
        @ui ||= Chef::Knife::UI.new(STDOUT, STDERR, STDIN, {})
      end

      def msg(node_name, message)
        ui.log("#{ui.color('[Masterchef]', :green, :bold)} #{ui.color(node_name, :blue, :bold)}: #{message}")
      end

      def run(node)
        msg(node.name, "Provisioning '#{node.name}'...")

        msg(node.name, 'Creating local temporary directory...')
        node.prepare_local_temp_dir!

        msg(node.name, 'Synchronizing remote workspace...')
        files = [
          './workspace/',
          "./tmp/#{node.name}/attributes.json",
        ]
        opts = {
          'excludes' => [
            '.berkshelf', # berksfile cache
            '.cache', # chef-solo cache
            'local-mode-cache', # seems like chef-solo cache as well
            'ohai',
            'chef_guid',
            'nodes',
            'site-cookbooks', # where cookbooks is taken from when running chef on remote machine
            'Berksfile.lock',
          ],
          'delete' => true,
        }
        node.write_temp_file!('attributes.json', JSON.dump(node.attributes))
        node.rsync(files, '~/masterchef', opts)

        msg(node.name, 'Running chef-solo on remote machine...')
        exit_code = node.ssh_command(<<~EOF, ui.stdout)
          export BERKSHELF_PATH=#{berkshelf_path}

          cd ~/masterchef
          berks install
          berks vendor ./site-cookbooks --delete

          sudo chef-solo \
            --config ~/masterchef/solo.rb \
            --json-attributes ~/masterchef/attributes.json \
            --node-name "$(hostname)"
        EOF

        if exit_code == 0
          msg(node.name, 'chef-solo exitted successfully!')
        else
          ui.error("chef-solo returned with exit code: #{exit_code}.")
          ui.error("See chef-solo logs above for reason.")
          exit(exit_code)
        end
      end

      private

      def berkshelf_path
        '~/masterchef/.berkshelf'
      end
    end
  end
end
