require 'executo'

Executo.setup do |config|
  config.redis = { url: "redis://10.10.2.36:6379/1" }
end

Sidekiq.configure_server do |config|
  config.redis = Executo.config.redis
end
