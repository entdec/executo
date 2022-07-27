# frozen_string_literal: true

require 'bundler/setup'
require 'executo'
require 'active_job'
require 'pry'

class LsProcessService < Executo::FeedbackProcessService
  arguments :now

  def perform
    stdout&.each do |line|
      logger.info line
    end
  end
end

Executo.setup do |config|
  config.redis = { url: 'redis://localhost:6379/1' }
  config.active_job_redis = { url: 'redis://localhost:6379/0' }
end

ActiveJob::Base.logger = Executo.config.logger.tagged('ActiveJob')
ActiveJob::Base.logger.level = Logger::WARN

Sidekiq.configure_server do |config|
  config.logger = Executo.config.logger.tagged('Sidekiq')
  config.logger.level = Logger::WARN
  config.redis = { url: 'redis://localhost:6379/0' }
end
