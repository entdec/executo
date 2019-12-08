# frozen_string_literal: true

require 'open3'
require 'shellwords'

module Executo
  class CLI
    def self.run(cmd, stdin_content: [], stdin_newlines: true, stdout:, stderr:, shell_escape: true)
      raise 'cmd must be a String or array of Strings.' \
        unless cmd.is_a?(String) || (cmd.is_a?(Array) && cmd.all? { |c| c.is_a?(String) })
      raise 'stdout must be a Proc.' unless stdout.is_a?(Proc)
      raise 'stderr must be a Proc.' unless stderr.is_a?(Proc)

      stdin_content = [stdin_content].flatten
      raise 'stdin_content must be an Array of Strings.' \
        unless stdin_content.is_a?(Array) && stdin_content.all? { |c| c.is_a?(String) }

      Executo.config.logger.debug "passed cmd: #{cmd}"

      computed_cmd = if cmd.is_a?(Array)
                       (shell_escape ? cmd.shelljoin : cmd.join)
                     else
                       (shell_escape ? cmd.shellsplit.shelljoin : cmd.shellsplit.join)
                     end

      Executo.config.logger.debug "computed cmd: #{computed_cmd}"
      Open3.popen3(computed_cmd) do |stdin_stream, stdout_stream, stderr_stream, thread|
        Executo.config.logger.debug "thread: #{thread}"
        stdin_content.each do |input_line|
          stdin_stream.write(input_line)

          unless input_line[-1] == "\n" || !stdin_newlines
            stdin_stream.write("\n")
          end
        end

        stdin_stream.close

        { stdout_stream => stdout, stderr_stream => stderr }.each_pair do |stream, callback|
          Thread.new do
            until (line = stream.gets).nil?
              callback.call(line)
            end
          rescue IOError => e
            # ignore
          end
        end

        thread.join
        thread.value
      end
    end
  end
end
