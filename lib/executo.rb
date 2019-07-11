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
      #   queue - the named queue to use, default 'default'
      #   class - the worker class to call, required
      #   args - an array of simple arguments to the perform method, must be JSON-serializable
      #   at - timestamp to schedule the job (optional), must be Numeric (e.g. Time.now.to_f)
      #   retry - whether to retry this job if it fails, default true or an integer number of retries
      #   backtrace - whether to save any error backtrace, default false
      options = { 'retry' => false }.merge(options).merge(
        'queue' => server_or_role,
        'class' => 'Executo::Worker',
        'args' => [command, options]
      )
      Sidekiq::Client.new(ConnectionPool.new { Redis.new(config.redis) }).push(options)
    end
  end
end
