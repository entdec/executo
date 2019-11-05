# frozen_string_literal: true

module Executo
  class SchedulerWorker
    include Sidekiq::Worker
    sidekiq_options queue: 'critical'

    def perform
      execution_time = Time.now.utc
      execution_time -= execution_time.sec

      self.class.perform_at(execution_time + 60) unless scheduled?

      # SCHEDULE.each do |(worker_class, schedule_lambda)|
      #   worker_class.perform_async if !scheduled?(worker_class) && schedule_lambda.call(execution_time)
      # end
    end

    def scheduled?(worker_class = self.class)
      scheduled_workers[worker_class.name]
    end

    private

    def scheduled_workers
      @scheduled_workers ||= Sidekiq::ScheduledSet.new.entries.each_with_object({}) do |item, hash|
        hash[item['class']] = true
      end
    end
  end
end
