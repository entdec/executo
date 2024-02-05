# frozen_string_literal: true

require 'thor'
require 'sidekiq/cli'
require 'executo/version'

class Executo::Cli < Thor
  package_name "Executo #{Executo::VERSION}"

  option :config, type: :string, aliases: '-c', desc: 'Path to the configuration file'

  desc 'daemon', 'Start the executo daemon'
  def daemon
    Executo.setup(options[:config])
    ARGV.clear
    ARGV.push '-c', Executo.config.concurrency.to_s, '-r', File.join(Executo.root, 'lib', 'executo', 'sidekiq_boot.rb'), '-g', 'executo'
    Executo.config.queues.each do |queue|
      ARGV.push '-q', queue
    end
    ENV['EXECUTO_CONFIG_FILE'] = options[:config]

    cli = Sidekiq::CLI.instance
    cli.parse
    integrate_with_systemd
    cli.run
  end

  private

  def integrate_with_systemd
    return unless ENV['NOTIFY_SOCKET']

    Sidekiq.configure_server do |config|
      require 'sidekiq/sd_notify'

      config.on(:startup) do
        Sidekiq::SdNotify.ready
      end

      config.on(:shutdown) do
        Sidekiq::SdNotify.stopping
      end

      Sidekiq.start_watchdog if Sidekiq::SdNotify.watchdog?
    end
  end

  class << self
    def exit_on_failure?
      true
    end
  end
end
