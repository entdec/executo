require 'executo'

Executo.setup do |config|
  config.redis = { url: "redis://10.10.2.36:6379/0" }
end
