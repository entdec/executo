# frozen_string_literal: true

module Executo
  module CommandDsl
    extend ActiveSupport::Concern
    include ActiveAttr::Model

    delegate :command, :parameters, :feedback_interval, :sync, :sync_timeout, to: :class

    class_methods do
      def call(**args)
        new(**args).call
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

      def sync(value = nil, timeout: nil)
        @sync = value unless value.nil?
        @sync_timeout = timeout if timeout
        @sync || false
      end

      def sync_timeout
        @sync_timeout || 5
      end
    end
  end
end
