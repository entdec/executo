# frozen_string_literal: true

module Executo
  class FeedbackProcessService
    attr_reader :state, :exitstatus, :stdout, :stderr, :context
    attr_writer :arguments

    def initialize(state, exitstatus, stdout, stderr, context)
      @state = state
      @exitstatus = exitstatus
      @stdout = stdout
      @stderr = stderr
      @context = context
    end

    def call
      perform
    end

    def perform
    end

    def self.arguments(*names)
      names.each do |name|
        define_method(name) { instance_variable_get('@arguments')[name.to_s] }
      end
    end
  end
end
