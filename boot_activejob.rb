# frozen_string_literal: true

require 'bundler/setup'
require 'executo'
require 'active_job'
require 'pry'

class LsProcessService < Executo::FeedbackProcessService
  arguments :now
  def perform
    puts 'HALLO ' * 80
    puts "now: #{now}"
    puts stdout
  end
end

Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://localhost:6379/0' }
end

# Executo.setup do |config|
#   config.redis = { url: 'redis://localhost:6379/1' }
# end
