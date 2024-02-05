# frozen_string_literal: true

class Executo::SidekiqBoot
  def self.setup
    Sidekiq.configure_server do |config|
      config.redis = Executo.config.redis
    end

    Sidekiq.configure_server do |config|
      config.redis = Executo.config.redis
    end
  end
end

Executo::SidekiqBoot.setup
