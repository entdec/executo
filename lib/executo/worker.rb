module Executo
  class Worker
    include Sidekiq::Worker
    sidekiq_options retry: true, backtrace: true

    def perform(command, options)
      Executo.logger.debug "command: #{command}"
      Executo.logger.debug "options: #{options}"

      Executo.logger.debug 'running...'
      begin
        status = CLI.run(command, stdout: ->(line) { puts line }, stderr: ->(line) { puts "ERR: #{line}" })
        raise 'Job ran not successful' unless status.success?
      rescue StandardError => e
        Executo.logger.info e.message
        raise 'Job ran not successful: #{e.class} - #{e.message}'
      end

      Executo.logger.info "Job ran as pid #{status.pid}"
    end
  end
end
