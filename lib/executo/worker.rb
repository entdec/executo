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
      feedback(options['feedback'], 'started')

      begin
        stdout = []
        stderr = []

        # CLI's callbacks could be used for progress reporting
        status = CLI.run(
          [command] + params,
          stdout: ->(line) { stdout << line },
          stderr: ->(line) { stderr << line },
          stdin_content: options['stdin_content'] || [],
          stdin_newlines: options.key?('stdin_newlines') ? options['stdin_newlines'] : true,
          shell_escape: options.key?('shell_escape') ? options['shell_escape'] : true
        )

        feedback(
          options['feedback'],
          status.success? ? 'completed' : 'failed',
          status.exitstatus.to_i,
          stdout.join,
          stderr.join,
          'command' => command,
          'params' => params,
          'options' => options,
          'pid' => status.pid.to_i
        )
      rescue StandardError => e
        # This only happens if something really broke, not worth a callback?
        Executo.config.logger.error "Command failed with exception: #{e.class} - #{e.message}"
        raise e
      end

      Executo.config.logger.info "Command finished, using pid #{status.pid}"
      feedback(options['feedback'], 'finished')
    end

    private

    def feedback(feedback, state, exitstatus = nil, stdout = '', stderr = '', context = {})
      Sidekiq::Client.new(Executo.active_job_connection_pool).push(
        'class' => ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper,
        'queue' => 'default',
        'wrapped' => 'Executo::FeedbackProcessJob',
        'args' => [
          {
            'job_class' => 'Executo::FeedbackProcessJob',
            'arguments': [
              feedback,
              state,
              exitstatus,
              stdout,
              stderr,
              context
            ]
          }
        ]
      )
    end
  end
end
