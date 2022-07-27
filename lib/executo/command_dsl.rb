# frozen_string_literal: true

module Executo
  module CommandDsl
    extend ActiveSupport::Concern
    include ActiveAttr::Model

    delegate :target, :command, :parameters, :feedback_interval, to: :class

    attr_reader :id, :parameter_values

    def initialize(*args)
      @id = args.first&.delete(:id) || SecureRandom.uuid
      @errors = ActiveModel::Errors.new(self)
      @parameter_values = args.first&.delete(:parameter_values) || {}
      super(*args)
    end

    class_methods do
      def call(*args)
        new(*args).call
      end

      def target(value = nil)
        @target = value if value.present?
        @target
      end

      def command(value = nil)
        @command = value if value.present?
        @command
      end

      def parameters(value = nil)
        @parameters = value if value.present?
        @parameters || ''
      end

      def feedback_interval(value = nil)
        @feedback_interval = value if value.present?
        @feedback_interval || 10
      end
    end
  end
end
