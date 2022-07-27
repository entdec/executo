# frozen_string_literal: true

module Executo
  module TaggedLogger
    extend ActiveSupport::Concern

    included do
      def logger_add_tag(tag)
        return unless tag.present?

        @logger = logger.tagged(tag)
      end

      def logger
        @logger ||= Executo.logger
      end
    end
  end
end
