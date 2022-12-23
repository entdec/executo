# frozen_string_literal: true

module Executo
  class Worker
    include Sidekiq::Worker
    include Executo::TaggedLogger

    attr_reader :options, :output, :flushable_output

    # @param [String] command
    # @param [Array] params
    # @param [Hash] options
    def perform(command, params = [], options = {})
      @options = options
      @output ||= Hash.new([])
      @flushable_output ||= Hash.new([])
      @started_at = Time.current
      @flushed_at = Time.current

      logger_add_tag('Worker')
      logger_add_tag(options.dig('feedback', 'id'))
      logger_add_tag(command)

      logger.debug "params: #{params}"
      logger.debug "options: #{options}"

      send_feedback(state: 'started')

      status = execute(command, params, options)
      send_feedback(
        state: status.success? ? 'completed' : 'failed',
        exitstatus: status.exitstatus.to_i,
        stdout: output[:stdout],
        stderr: output[:stderr],
        pid: status.pid
      )
    rescue StandardError => e
      logger.error "Exception: #{e.class} - #{e.message}"
      logger.error e.backtrace.join("\n")
      send_feedback(state: 'failed')
    ensure
      send_feedback(state: 'finished')
    end

    private

    def execute(command, params = [], options = {})
      argument_list = [command] + params
      stdin_content = options['stdin_content'] || []
      stdin_newlines = options.key?('stdin_newlines') ? options['stdin_newlines'] : true
      shell_escape = options.key?('shell_escape') ? options['shell_escape'] : true

      Bundler.with_clean_env do
        dir = command.start_with?('/') ? File.dirname(command).gsub!(/bin$/, '') : Dir.pwd
        dir = options['working_folder'] if options['working_folder'].present?
        dir = dir.presence || Dir.pwd
        Dir.chdir(dir) do
          CLI.run(argument_list, stdout: ->(line) { register_output(:stdout, line) }, stderr: ->(line) { register_output(:stderr, line) }, stdin_content: stdin_content, stdin_newlines: stdin_newlines, shell_escape: shell_escape)
        end
      end
    end

    def register_output(channel, value)
      return unless value

      value = value.split("\n").map { |line| line.chomp.force_encoding('utf-8') }
      output[channel] += value
      flushable_output[channel] += value
      logger.debug "Output: #{channel}: #{value}"
      flush_if_needed
    end

    def flush_if_needed
      return if time_since_flushed < (options.dig('feedback', 'flush_interval') || 10)
      return if flushable_output[:stdout].blank? && flushable_output[:stderr].blank?

      flush_stdout = flushable_output[:stdout].dup
      flushable_output[:stdout].clear
      flush_stderr = flushable_output[:stderr].dup
      flushable_output[:stderr].clear

      send_feedback(state: 'output', stdout: flush_stdout, stderr: flush_stderr)
      @flushed_at = Time.current
    end

    def time_since_flushed
      (Time.current - @flushed_at).to_i
    end

    def send_feedback(results)
      results.merge!(runtime_seconds: (Time.current - @started_at).to_i)
      logger.info "Command #{results[:state]} after #{results[:runtime_seconds]} seconds"
      Sidekiq::Client.new(Executo.active_job_connection_pool).push(
        'class' => ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper,
        'queue' => 'default',
        'wrapped' => 'Executo::FeedbackProcessJob',
        'args' => [
          {
            'job_class' => 'Executo::FeedbackProcessJob',
            'arguments' => [
              options['feedback'],
              results.deep_stringify_keys
            ]
          }
        ]
      )
    end
  end
end
