# frozen_string_literal: true

module Executo
  class Command
    include CommandDsl
    include TaggedLogger

    attr_reader :id, :status, :stdout, :stderr, :exitstatus

    def call
      raise 'missing target' unless target

      perform
    end

    def process_results(results)
      state = results[:state]
      logger.debug("Processing #{state} results")
      public_send(state.to_sym, results) if respond_to?(state.to_sym)
    end

    def setup_logger(id)
      logger_add_tag(self.class.name)
      logger_add_tag(id)
    end

    private

    def perform
      Executo.publish(target: target, command: command, parameters: safe_parameters, feedback: { service: self.class.name, id: id, args: attributes.to_h })
    end

    def safe_parameters
      local_parameter_values = {}
      local_parameter_values = implicit_parameter_values if respond_to?(:implicit_parameter_values)
      local_parameter_values = local_parameter_values.merge(parameter_values)

      parameters.split.map { |parameter| parameter % local_parameter_values }
    end

    class << self
      def process_feedback(feedback, results)
        cmd = new(feedback['args'].merge(id: feedback['id']))
        cmd.setup_logger(feedback['id'])
        cmd.process_results(results.symbolize_keys)
      end
    end
  end
end
