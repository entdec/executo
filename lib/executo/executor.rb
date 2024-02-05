# frozen_string_literal: true

require 'open3'
require 'shellwords'

module Executo
  class Executor
    class << self
      def run(cmd, stdout:, stderr:, stdin_content: [], stdin_newlines: true, shell_escape: true, working_folder: Dir.pwd)
        raise 'cmd must be an array of Strings.' unless array_of_strings?(cmd)
        raise 'stdout must be a Proc.' unless stdout.is_a?(Proc)
        raise 'stderr must be a Proc.' unless stderr.is_a?(Proc)
        raise 'stdin_content must be an Array of Strings.' unless array_of_strings?(stdin_content)

        computed_cmd = escaped_command(cmd, shell_escape: shell_escape)

        Executo.logger.debug "Working folder: #{working_folder}"
        Executo.logger.debug "Computed cmd: #{computed_cmd}"

        Bundler.with_unbundled_env do
          Open3.popen3(computed_cmd, chdir: working_folder) do |stdin_stream, stdout_stream, stderr_stream, thread|
            threads = []
            threads << write_stream(stdin_stream, stdin_content, newlines: stdin_newlines)
            threads << read_stream(stdout_stream, stdout)
            threads << read_stream(stderr_stream, stderr)
            threads << thread

            threads.each(&:join)
            thread.value
          end
        end
      end

      def escaped_command(command, shell_escape: true)
        return command.join unless shell_escape

        command.map { |string| string.gsub('{SPATIE}', ' ') }.shelljoin
      end

      def write_stream(stream, content, newlines: true)
        Thread.new do
          content.each do |input_line|
            stream.write(input_line)
            stream.write("\n") if input_line[-1] != "\n" && newlines
          end
        rescue Errno::EPIPE
          nil
        ensure
          stream.close
        end
      end

      def read_stream(stream, callback)
        Thread.new do
          until (line = stream.gets).nil?
            callback.call(line)
          end
        rescue IOError
          # ignore
        end
      end

      def array_of_strings?(array)
        array.is_a?(Array) && array.all? { |c| c.is_a?(String) }
      end
    end
  end
end
