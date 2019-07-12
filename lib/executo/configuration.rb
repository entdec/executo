module Executo
  class Configuration
    attr_accessor :redis
    attr_writer   :logger
    attr_writer   :callback

    def initialize
      @redis = {}
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::DEBUG
      @callback = ->(state, exitstatus, stdout, stderr, context) {}
    end

    # logger [Object].
    def logger
      @logger.is_a?(Proc) ? instance_exec(&@logger) : @logger
    end

    ##
    # callback to be called upon job start, progress, completion or failure
    #
    def callback(state, exitstatus = nil, stdout = nil, stderr = nil, context = nil)
      return unless @callback.is_a?(Proc)

      instance_exec(state, exitstatus, stdout, stderr, context, &@callback)
    end
  end
end
