module Executo
  class Worker
    include Sidekiq::Worker
    sidekiq_options retry: true, backtrace: true

    def perform(command, options)
      puts "command: #{command}"
      puts "options: #{options}"

      puts 'running...'
      begin
        status = CLI.run(command, stdout: ->(line) { puts line }, stderr: ->(line) { puts "ERR: #{line}" })
        raise 'Job ran not successful' unless status.success?
      rescue StandardError => e
        puts e.message
        raise 'Job ran not successful: #{e.class} - #{e.message}'
      end

      puts "Job ran as pid #{status.pid}"
      puts 'done'
    end
  end
end
