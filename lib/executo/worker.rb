module Executo
  class Worker
    include Sidekiq::Worker
    sidekiq_options retry: true, backtrace: true

    def perform(command, options)
      Executo.config.logger.debug "command: #{command}"
      Executo.config.logger.debug "options: #{options}"

      Executo.config.logger.debug 'running...'
      begin
        status = CLI.run(command, stdout: ->(line) { puts line }, stderr: ->(line) { puts "ERR: #{line}" })
        raise 'Job ran not successful' unless status.success?
      rescue StandardError => e
        Executo.config.logger.info e.message
        raise 'Job ran not successful: #{e.class} - #{e.message}'
      end

      Executo.config.logger.info "Job ran as pid #{status.pid}"
    end
  end
end
