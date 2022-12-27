# frozen_string_literal: true

require 'active_support/message_encryptor'
require 'active_support/tagged_logging'
require 'sidekiq'
require 'active_job'
require 'securerandom'
require 'active_attr'
require 'pry'

require 'executo/cli'
require 'executo/tagged_logger'
require 'executo/configuration'
require 'executo/version'
require 'executo/encrypted_worker'
require 'executo/scheduler_worker'
require 'executo/worker'
require 'executo/feedback_process_job'
require 'executo/feedback_process_service'
require 'executo/command_dsl'
require 'executo/command'
require 'executo/pub_sub'

require 'executo/commands/imapsync_test'

module Executo
  class Error < StandardError; end
  class MissingTargetError < Error; end
  class MultipleTargetsError < Error; end
  class CommandError < Error; end

  class << self
    attr_reader :config

    delegate :logger, to: :config

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
    def publish(target:, command:, parameters: [], encrypt: false, options: {}, job_options: {}, feedback: {})
      options['feedback'] = feedback&.stringify_keys
      options['feedback']['id'] ||= SecureRandom.uuid

      args = [command, parameters, options.deep_stringify_keys]
      args = args.map { |a| encrypt(a) } if encrypt

      sidekiq_options = { 'retry' => 0 }.merge(job_options).merge(
        'queue' => target,
        'class' => encrypt ? 'Executo::EncryptedWorker' : 'Executo::Worker',
        'args' => args
      )

      if defined?(Rails) && Rails.env.test?
        $executo_jobs ||= {}
        $executo_jobs[options.dig('feedback', 'id')] = sidekiq_options
      else
        Sidekiq::Client.new(connection_pool).push(sidekiq_options)
      end

      logger.info("Published #{command} to #{target} with id #{options['feedback']['id']}")
      options.dig('feedback', 'id')
    end


    def schedule(target, list)
      options = {
        'retry' => 0,
        'queue' => target,
        'class' => 'Executo::SetScheduleWorker',
        'args' => list
      }
      Sidekiq::Client.new(connection_pool).push(options)
    end

    def connection_pool
      @connection_pool ||= ConnectionPool.new(size: 5, timeout: 5) { Redis.new(config.redis) }
    end

    def active_job_connection_pool
      @active_job_connection_pool ||= ConnectionPool.new(size: 5, timeout: 5) { Redis.new(config.active_job_redis) }
    end
  end
end
