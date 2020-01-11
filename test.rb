require 'bundler/setup'
require 'executo'
require 'active_support/core_ext/hash'
require 'pry'

require 'sidekiq'
require 'active_job'

ActiveJob::Base.queue_adapter = :sidekiq

Executo.setup do |config|
  config.redis = { url: 'redis://localhost:6379/1' }
  config.active_job_redis = { url: 'redis://localhost:6379/0' }
end

Executo.publish('localhost', 'ls', ['-al'], feedback: { service: 'LsFeedbackProcessService', args: { now: Time.now }})

puts "Done"
