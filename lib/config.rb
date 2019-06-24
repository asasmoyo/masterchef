module Masterchef
  class Config
    attr_accessor :ssh_user, :ssh_port, :ssh_host_key_check

    def initialize
      @ssh_user = nil
      @ssh_port = 22
      @ssh_host_key_check = true
    end

    def from_file(file)
      if ! File.exist?(file)
        return
      end
      instance_eval File.read(file)
    end
  end
end
