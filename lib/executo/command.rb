# frozen_string_literal: true

module Executo
  class Command
    include CommandDsl
    include TaggedLogger

    attr_reader :executo_id, :parameter_values, :status, :stdout, :stderr, :exitstatus, :target

    def initialize(*args)
      @executo_id = args.first&.delete(:id) || SecureRandom.uuid
      @target = args.first&.delete(:target) || self.class.target
      @errors = ActiveModel::Errors.new(self)
      @parameter_values = args.first&.delete(:parameter_values) || {}
      super(*args)
    end

    def call
      raise MissingTargetError unless target_name.present?

      Executo.publish(target: target_name, command: command, parameters: safe_parameters, feedback: { service: self.class.name, id: executo_id, arguments: attributes.to_h, sync: sync })
      return perform_sync if sync

      { target: target_name, id: executo_id }
    end

    def process_results(results)
      state = results[:state]
      logger.debug("Processing #{state} results")
      public_send(state.to_sym, results) if respond_to?(state.to_sym)
    end

    def setup_logger
      logger_add_tag(self.class.name)
      logger_add_tag(executo_id)
    end

    private

    def perform_sync
      return_value = nil
      results = {}

      client = PubSub.new("sync_#{executo_id}")
      client.subscribe do |message|
        results = message.symbolize_keys
        value = process_results(results)
        case results[:state]
        when 'completed'
          return_value = value
        when 'failed'
          raise CommandError, value
        when 'finished'
          client.unsubscribe
        end
      end

      results.merge(target: target_name, id: executo_id, return_value: return_value)
    end

    def target_name
      @target_name ||= target.is_a?(Proc) ? instance_exec(&target) : target
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
        cmd.setup_logger
        cmd.process_results(results.symbolize_keys)
      end
    end
  end
end
