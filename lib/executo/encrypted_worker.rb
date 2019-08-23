# frozen_string_literal: true

require "executo/worker"

module Executo
  class EncryptedWorker < Worker
    include Sidekiq::Worker

    # @param [String] encrypted_command
    # @param [Array] encrypted_params
    # @param [Hash] encrypted_options
    def perform(encrypted_command, encrypted_params = [], encrypted_options = {})
      Executo.config.logger.debug "encrypted_command: #{encrypted_command}"
      Executo.config.logger.debug "encrypted_params: #{encrypted_params}"
      Executo.config.logger.debug "encrypted_options: #{encrypted_options}"

      command = Executo.decrypt(encrypted_command)
      params = Executo.decrypt(encrypted_params)
      options = Executo.decrypt(encrypted_options)

      super(command, params, options)
    end
  end
end
