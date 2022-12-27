# frozen_string_literal: true

# Call with:
# LsTest.call(parameter_values: { folder: '/tmp' })

class LsTest < Executo::Command
  target 'localhost'
  command '/bin/ls'
  parameters '-lisart %<folder>s'
  sync true

  def completed(results)
    results[:stdout]
  end
end
