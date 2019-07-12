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

      Executo.config.logger.debug 'Started'
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
          stdout.join("\r\n"),
          stderr.join("\r\n"),
          'command' => command,
          'params' => params,
          'options' => options,
          'pid' => status.pid
        )
      rescue StandardError => e
        # This only happens if something really broke, not worth a callback?
        Executo.config.logger.error "Failed: #{e.class} - #{e.message}"
        raise e
      end

      Executo.config.logger.info "Job ran as pid #{status.pid}"
    end
  end
end
