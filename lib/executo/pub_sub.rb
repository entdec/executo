# frozen_string_literal: true

require "json"

module Executo
  class PubSub
    attr_reader :channel_name, :timeout

    def initialize(channel_name, timeout: 5)
      @channel_name = channel_name
      @timeout = timeout
    end

    def subscribe(&block)
      @client = Redis.new(Executo.config.redis)
      @client.subscribe_with_timeout(timeout, channel_name) do |on|
        on.message do |_channel, message|
          yield(JSON.parse(message))
        end
      end
    ensure
      unsubscribe
      @client.close
    end

    def unsubscribe
      @client&.unsubscribe(channel_name) if @client&.subscribed?
    end

    def publish(message)
      Executo.connection_pool.with(timeout: timeout) do |redis|
        redis.publish(channel_name, message.to_json)
      end
    end
  end
end
