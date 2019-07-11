module Executo
  class Worker
    include Sidekiq::Worker
    def perform(command, options)
      Executo.config.logger.debug "command: #{command}"
      Executo.config.logger.debug "options: #{options}"
      Executo.config.logger.debug 'running...'
      begin
        stdout = []
        stderr = []
        status = CLI.run(command, stdout: ->(line) { stdout << line }, stderr: ->(line) { stderr << line })

        Executo.config.callback(command, options, status.exitstatus, status.pid, stdout, stderr)
      rescue StandardError => e
        Executo.config.logger.error "Job ran not successful: #{e.class} - #{e.message}"
        raise e
      end

      Executo.config.logger.info "Job ran as pid #{status.pid}"
    end
  end
end
