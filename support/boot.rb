# frozen_string_literal: true

require 'executo'
require 'net/http'
require 'uri'

Executo.setup do |config|
  config.redis = { url: ENV.fetch('EXECUTO_REDIS_URL', 'redis://localhost:6379/1') }
  config.active_job_redis = { url: ENV.fetch('EXECUTO_ACTIVEJOB_URL', 'redis://localhost:6379/0') }
end

Sidekiq.configure_server do |config|
  config.redis = Executo.config.redis
end

Sidekiq.configure_server do |config|
  config.redis = Executo.config.redis
end
