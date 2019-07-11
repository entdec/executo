require 'sidekiq'

require "executo/cli"
require "executo/configuration"
require "executo/version"
require "executo/worker"

module Executo
  class Error < StandardError; end

  class << self
    attr_reader :config

    def setup
      @config = Configuration.new
      yield config
    end

    def publish(server_or_role, command, options = {})
      Sidekiq::Client.new(ConnectionPool.new { Redis.new(config.redis) }).push(
        'queue' => server_or_role,
        'class' => 'Executo::Worker',
        'args' => [command, options]
      )
    end
  end
end
