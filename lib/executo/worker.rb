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
      @started_at = Time.now
      @flushed_at = Time.now

      logger_add_tag("Worker")
      logger_add_tag(options.dig("feedback", "id"))
      logger_add_tag(command.split("/").last)

      send_feedback(state: "started")
      logger.debug "started with #{params}"
      logger.debug "  options: #{options}"

      status = execute(command, params, options)
      send_feedback(
        state: status.success? ? "completed" : "failed",
        exitstatus: status.exitstatus.to_i,
        stdout: output[:stdout],
        stderr: output[:stderr],
        pid: status.pid
      )
    rescue => e
      logger.error "exception: #{e.class} - #{e.message}"
      logger.error e.backtrace.join("\n")
      send_feedback(state: "failed")
    ensure
      logger.info "finished after #{(Time.now - @started_at).to_i} seconds"
      send_feedback(state: "finished")
    end

    private

    def execute(command, params = [], options = {})
      argument_list = [command] + params
      stdin_content = options["stdin_content"] || []
      stdin_newlines = options.key?("stdin_newlines") ? options["stdin_newlines"] : true
      shell_escape = options.key?("shell_escape") ? options["shell_escape"] : true

      dir = command.start_with?("/") ? File.dirname(command).gsub!(%r{/bin$}, "") : "/tmp"
      dir = options["working_folder"] if options["working_folder"].present?
      dir = dir.presence || Dir.pwd
      Executor.run(argument_list, stdout: ->(line) { register_output(:stdout, line) }, stderr: ->(line) { register_output(:stderr, line) }, stdin_content: stdin_content, stdin_newlines: stdin_newlines, shell_escape: shell_escape, working_folder: dir)
    end

    def register_output(channel, value)
      return unless value

      value = value.split("\n").map { |line| line.chomp.force_encoding("utf-8") }
      output[channel] += value
      flushable_output[channel] += value
      logger.debug "Output: #{channel}: #{value}"
      flush_if_needed
    end

    def flush_if_needed
      return if time_since_flushed < (options.dig("feedback", "flush_interval") || 10)
      return if flushable_output[:stdout].blank? && flushable_output[:stderr].blank?

      flush_stdout = flushable_output[:stdout].dup
      flushable_output[:stdout].clear
      flush_stderr = flushable_output[:stderr].dup
      flushable_output[:stderr].clear

      send_feedback(state: "output", stdout: flush_stdout, stderr: flush_stderr)
      @flushed_at = Time.now
    end

    def time_since_flushed
      (Time.now - @flushed_at).to_i
    end

    def send_feedback(results)
      results[runtime_seconds: (Time.now - @started_at).to_i]

      if options.dig("feedback", "sync")
        send_sync(results)
      else
        send_async(results)
      end
    end

    def send_sync(results)
      Executo::PubSub.new("sync_#{options.dig("feedback", "id")}").publish(results.deep_stringify_keys)
    end

    def send_async(results)
      sidekiq_client.push(
        "class" => "ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper",
        "queue" => "default",
        "wrapped" => "Executo::FeedbackProcessJob",
        "args" => [
          {
            "job_class" => "Executo::FeedbackProcessJob",
            "arguments" => [
              options["feedback"],
              results.deep_stringify_keys
            ]
          }
        ]
      )
    end

    def sidekiq_client
      @sidekiq_client ||= Sidekiq::Client.new(config: Sidekiq::Config.new(Executo.config.active_job_redis))
    end
  end
end
