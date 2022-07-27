# frozen_string_literal: true

module Executo
  class FeedbackProcessJob < ActiveJob::Base
    def perform(feedback, results)
      feedback_service_class = feedback['service']&.safe_constantize
      unless feedback_service_class
        Executo.logger.error("Feedback service #{feedback['service']} not found")
        return
      end

      feedback_service_class.process_feedback(feedback, results)
    end
  end
end
