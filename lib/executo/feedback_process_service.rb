# frozen_string_literal: true

module Executo
  class FeedbackProcessService
    include Executo::TaggedLogger

    attr_reader :id, :state, :exitstatus, :stdout, :stderr
    attr_writer :arguments

    def initialize(feedback, results)
      @id = feedback['id']
      @state = results['state']
      @exitstatus = results['exitstatus']
      @stdout = results['stdout'] || []
      @stderr = results['stderr'] || []
      @arguments = feedback['arguments'] || {}
    end

    def call
      logger_add_tag(self.class.name)
      logger_add_tag(id)
      perform
    end

    private

    def perform; end

    class << self
      def arguments(*names)
        names.each do |name|
          define_method(name) { instance_variable_get('@arguments')[name.to_s] }
        end
      end

      def process_feedback(feedback, results)
        new(feedback, results).call
      end
    end
  end
end
