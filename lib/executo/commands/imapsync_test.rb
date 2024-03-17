# frozen_string_literal: true

# Call with:
# ImapSyncTest.call(mailbox_id: 'abc', parameter_values: {host1: 1, user1: 1, password1: 1, host2: 2, user2: 2, password2: 2})

class Executo::Commands::ImapsyncTest < Executo::Command
  target "localhost"
  command "/usr/local/bin/imapsync"
  parameters "--dry --host1 %<host1>s --user1 %<user1>s --password1 %<password1>s --host2 %<host2>s --user2 %<user2>s --password2 %<password2>s --logfile %<logfile>s --delete2"
  attribute :mailbox_id
  feedback_interval 10

  # Callback for 'started' messages. results contain stdout/stderr, atribute mailbox_id will already be set.
  def started(_results)
    logger.info "Started #{mailbox_id}"
  end

  # Process intermediate output from the command. results contain stdout/stderr/runtime_seconds
  def output(results)
    find_current_status(results[:stdout])
  end

  # Process completed output from the command. results contain stdout/stderr/exitstatus/runtime_seconds
  def completed(results)
  end

  # Process failed output from the command. results contain stdout/stderr/exitstatus/runtime_seconds
  def failed(results)
  end

  # Process final output from the command. results contain runtime_seconds
  def finished(results)
  end

  private

  def find_current_status(lines)
    line = lines.reverse.find { |l| l =~ %r{\d+/\d+ msgs left} }
    return unless line

    match = line.match(%r{(?<current>\d+)/(?<total>\d+) msgs left})

    logger.info "Processing #{mailbox_id} - #{match[:current]}/#{match[:total]} (#{(match[:current].to_i.to_f / match[:total].to_i).to_i}%)"
  end

  def implicit_parameter_values
    {
      logfile: "/tmp/imapsync_#{executo_id}.log"
    }
  end
end
