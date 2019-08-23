# frozen_string_literal: true

module Executo
  class Worker
    include Sidekiq::Worker

    # @param [String] command
    # @param [Array] params
    # @param [Hash] options
    def perform(command, params = [], options = {})
      Executo.config.logger.debug "command: #{command}"
      Executo.config.logger.debug "params: #{params}"
      Executo.config.logger.debug "options: #{options}"

      Executo.config.logger.info 'Command started'
      Executo.config.callback(:started)

      begin
        stdout = []
        stderr = []

        # CLI's callbacks could be used for progress reporting
        status = CLI.run(
          [command] + params,
          stdout: ->(line) { stdout << line },
          stderr: ->(line) { stderr << line }
        )

        Executo.config.callback(
          status.success? ? :completed : :failed,
          status.exitstatus,
          stdout.join,
          stderr.join,
          'command' => command,
          'params' => params,
          'options' => options,
          'pid' => status.pid
        )
      rescue StandardError => e
        # This only happens if something really broke, not worth a callback?
        Executo.config.logger.error "Command failed with exception: #{e.class} - #{e.message}"
        raise e
      end

      Executo.config.logger.info "Command finished, using pid #{status.pid}"
    end
  end
end
