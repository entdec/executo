# frozen_string_literal: true

require 'active_support/message_encryptor'
require 'sidekiq'

require 'executo/cli'
require 'executo/configuration'
require 'executo/version'
require 'executo/encrypted_worker'
require 'executo/scheduler_worker'
require 'executo/worker'

module Executo
  class Error < StandardError; end

  class << self
    attr_reader :config

    def setup
      @config = Configuration.new
      yield config
    end

    def cryptor
      @cryptor ||= ActiveSupport::MessageEncryptor.new(ENV['EXECUTO_KEY'])
    end

    def encrypt(obj)
      cryptor.encrypt_and_sign(obj)
    end

    def decrypt(string)
      cryptor.decrypt_and_verify(string)
    end

    ##
    # Publishes a command to be executed on a target
    #
    # @param [String] target a server or a role
    # @param [String] command command to be executed
    # @param [Array] params params for the command
    # @param [Boolean] encrypt whether to encrypt all parameters
    # @param [Hash] options options for the worker
    # @param [Hash] job_options, options for sidekiq, valid options are:
    #        queue - the named queue to use, default 'default'
    #        class - the worker class to call, required
    #        args - an array of simple arguments to the perform method, must be JSON-serializable
    #        at - timestamp to schedule the job (optional), must be Numeric (e.g. Time.now.to_f)
    #        retry - whether to retry this job if it fails, default true or an integer number of retries
    #        backtrace - whether to save any error backtrace, default false
    def publish(target, command, params = [], encrypt: false, options: {}, job_options: {})
      args = [command, params, options.deep_stringify_keys]
      args = args.map { |a| encrypt(a) } if encrypt

      options = { 'retry' => 0 }.merge(job_options).merge(
        'queue' => target,
        'class' => encrypt ? 'Executo::EncryptedWorker' : 'Executo::Worker',
        'args' => args
      )
      Sidekiq::Client.new(ConnectionPool.new { Redis.new(config.redis) }).push(options)
    end
  end
end
