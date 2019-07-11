module Executo
  class Configuration
    attr_accessor :redis
    attr_writer   :logger

    def initialize
      @redis = {}
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::DEBUG
    end

    # logger [Object].
    def logger
      @logger.is_a?(Proc) ? instance_exec(&@logger) : @logger
    end
  end
end
