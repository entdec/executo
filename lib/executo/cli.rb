require 'open3'
require 'shellwords'

module Executo
  class CLI
    def self.run(cmd, in_directory: nil, stdin_content: [], stdin_newlines: true, stdout:, stderr:)
      raise 'cmd must be a String or array of Strings.' \
        unless cmd.is_a?(String) || (cmd.is_a?(Array) && cmd.all? { |c| c.is_a?(String) })
      raise 'stdout must be a Proc.' unless stdout.is_a?(Proc)
      raise 'stderr must be a Proc.' unless stderr.is_a?(Proc)

      stdin_content = [stdin_content].flatten
      raise 'stdin_content must be an Array of Strings.' \
        unless stdin_content.is_a?(Array) && stdin_content.all? { |c| c.is_a?(String) }

      Executo.config.logger.debug "passed cmd: #{cmd}"

      computed_cmd = if cmd.is?(Array)
                       cmd.shelljoin
                     else
                       cmd.shellsplit.shelljoin
                     end

      Executo.config.logger.debug "computed cmd: #{computed_cmd}"
      Dir.chdir(in_directory || Dir.pwd) do
        Open3.popen3(computed_cmd) do |stdin_stream, stdout_stream, stderr_stream, thread|
          puts "thread: #{thread}"
          stdin_content.each do |input_line|
            stdin_stream.write(input_line)

            stdin_stream.write("\n") unless input_line[-1] == "\n" || !stdin_newlines
          end

          stdin_stream.close

          { stdout_stream => stdout, stderr_stream => stderr }.each_pair do |stream, callback|
            Thread.new do
              until (line = stream.gets).nil?
                callback.call(line)
              end
            end
          end

          thread.join
          thread.value
        end
      end
    end
  end
end
