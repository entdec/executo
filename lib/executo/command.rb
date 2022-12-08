# frozen_string_literal: true

module Executo
  class Command
    include CommandDsl
    include TaggedLogger

    attr_reader :executo_id, :parameter_values, :status, :stdout, :stderr, :exitstatus

    def initialize(*args)
      @executo_id = args.first&.delete(:id) || SecureRandom.uuid
      @errors = ActiveModel::Errors.new(self)
      @parameter_values = args.first&.delete(:parameter_values) || {}
      super(*args)
    end

    def call
      raise 'missing target' unless targets.present?

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
      results = executo_targets.map { |target| execute_on_target(target)}
      results.size == 1 ? results.first : results
    end

    def execute_on_target(target)
      Executo.publish(target: target, command: command, parameters: safe_parameters, feedback: { service: self.class.name, id: executo_id, arguments: attributes.to_h })
    end

    def executo_targets
      return @executo_targets if @executo_targets.present?

      @executo_targets = targets.is_a?(Proc) ? instance_exec(&targets) : targets
      @executo_targets = @executo_targets.map { |target| instance_exec(&target) if target.is_a?(Proc) }.compact
      @executo_targets
    end

    def safe_parameters
      local_parameter_values = {}
      local_parameter_values = implicit_parameter_values if respond_to?(:implicit_parameter_values)
      local_parameter_values = local_parameter_values.merge(parameter_values)

      parameters.split.map { |parameter| parameter % local_parameter_values }
    end

    class << self
      def process_feedback(feedback, results)
        cmd = new(feedback['arguments'].merge(id: feedback['id']))
        cmd.setup_logger(feedback['id'])
        cmd.process_results(results.symbolize_keys)
      end
    end
  end
end
