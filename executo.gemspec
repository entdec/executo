# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'executo/version'

Gem::Specification.new do |spec|
  spec.name          = 'executo'
  spec.version       = Executo::VERSION
  spec.authors       = ['Tom de Grunt']
  spec.email         = ['tom@degrunt.nl']

  spec.summary       = 'Executes commands on remote servers'
  spec.description   = 'Executes commands on remote servers'
  spec.homepage      = 'https://github.com/entdec/excecuto'
  spec.license       = 'MIT'

  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/entdec/excecuto'
  spec.metadata['changelog_uri'] = 'https://github.com/entdec/excecuto'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'bin'
  spec.executables   = 'executo'
  spec.require_paths = ['lib']

  spec.add_dependency 'active_attr', '>= 0.15'
  spec.add_dependency 'activejob', '> 7.0.0'
  spec.add_dependency 'activemodel', '> 7.0.0'
  spec.add_dependency 'activesupport', '< 7.1.0'
  spec.add_dependency 'pry'
  spec.add_dependency 'sidekiq', '> 5.1', '< 7.0'
  spec.add_dependency 'redis', '< 5'

  spec.add_development_dependency 'auxilium', '~> 3'
  spec.add_development_dependency 'minitest', '> 5.0'
  spec.add_development_dependency 'rake', '> 10.0'
  spec.add_development_dependency 'rubocop'
end
