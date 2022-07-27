# frozen_string_literal: true

module Executo
  class Configuration
    attr_accessor :redis
    attr_accessor :active_job_redis
    attr_writer   :logger

    def initialize
      @redis = {}
      @active_job_redis = {}
      @logger = ActiveSupport::TaggedLogging.new(Logger.new($stdout))
      @logger.level = Logger::INFO
    end

    # logger [Object].
    def logger
      @logger.is_a?(Proc) ? instance_exec(&@logger) : @logger
    end
  end
end
