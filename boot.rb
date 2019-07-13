# frozen_string_literal: true

require 'executo'
require 'net/http'
require 'uri'

Executo.setup do |config|
  config.redis = { url: 'redis://localhost:6379/1' }
  config.callback = lambda do |state, exitstatus, stdout, stderr, context|
    callback_url = context&.[]('options')&.delete('callback_url')
    break unless callback_url

    data = {
      state: state,
      command: context['command'],
      params: context['params'],
      options: context['options']
    }

    data[:exitstatus] = exitstatus.to_i if exitstatus
    data[:stdout] = stdout if stdout
    data[:stderr] = stderr if stderr
    data[:pid] = context['pid'].to_i if context['pid']

    uri = URI.parse(callback_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.start do
      http.request_post(
        uri.path,
        data.to_json,
        'Content-Type': 'application/json'
      )
    end
  end
end

Sidekiq.configure_server do |config|
  config.redis = Executo.config.redis
end
