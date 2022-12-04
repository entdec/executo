# frozen_string_literal: true

module Executo
  module CommandDsl
    extend ActiveSupport::Concern
    include ActiveAttr::Model

    delegate :target, :command, :parameters, :feedback_interval, to: :class

    class_methods do
      def call(*args)
        new(*args).call
      end

      def target(value = nil)
        targets << value if value.present?
        targets
      end

      def targets(value = nil)
        @targets = value if value.present?
        @targets ||= []
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
