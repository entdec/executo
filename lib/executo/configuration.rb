module Executo
  class Configuration
    attr_accessor :redis
    attr_writer   :logger
    attr_writer   :callback

    def initialize
      @redis = {}
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::DEBUG
      @callback = ->(command, options, status, pid, stdout, stderr) {}
    end

    # logger [Object].
    def logger
      @logger.is_a?(Proc) ? instance_exec(&@logger) : @logger
    end

    # callback
    def callback(command, options, exitstatus, pid, stdout, stderr)
      return unless @callback.is_a?(Proc)

      instance_exec(command, options, exitstatus, pid, stdout, stderr, &@callback)
    end
  end
end
