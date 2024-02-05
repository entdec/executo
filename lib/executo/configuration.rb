# frozen_string_literal: true

module Executo
  class Configuration
    attr_accessor :redis, :active_job_redis, :secret_key, :concurrency, :queues
    attr_writer   :logger

    def initialize(config_file = nil)
      @redis = {}
      @active_job_redis = {}
      @logger = ActiveSupport::TaggedLogging.new(Logger.new($stdout))
      @logger.level = Logger::INFO
      @concurrency = 2
      @queues = ['default']

      read_config_file(config_file) if config_file
    end

    # logger [Object].
    def logger
      @logger.is_a?(Proc) ? instance_exec(&@logger) : @logger
    end

    def log_level=(level)
      @logger.level = Logger.const_get(level.to_s.upcase) if %w[debug info warn error].include?(level.to_s)
    end

    def redis_url=(url)
      @redis[:url] = url
    end

    def active_job_redis_url=(url)
      @active_job_redis[:url] = url
    end

    private

    def read_config_file(file_name)
      data = YAML.load_file(file_name)
      data.each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end
    end
  end
end
