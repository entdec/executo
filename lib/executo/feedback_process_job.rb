# frozen_string_literal: true

module Executo
  class FeedbackProcessJob < ActiveJob::Base
    def perform(feedback, state, exitstatus=nil, stdout='', stderr='', context={})
      feedback_service = feedback['service'].safe_constantize

      return unless feedback_service

      service = feedback_service.new(state, exitstatus, stdout, stderr, context)
      service.arguments = feedback['args']
      service.call
    end
  end
end
