# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'executo/version'

Gem::Specification.new do |spec|
  spec.name          = 'executo'
  spec.version       = Executo::VERSION
  spec.authors       = ['Tom de Grunt', 'Andre Meij']
  spec.email         = ['tom@degrunt.nl', 'andre@itsmeij.com']

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
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r[\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)])
    end
  end

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r[\Aexe/]) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'active_attr', '>= 0.15'
  spec.add_dependency 'activejob', '> 7.0.0', '< 7.1.0'
  spec.add_dependency 'activesupport', '> 7.0.0', '< 7.2.0'

  spec.add_dependency 'thor'
  spec.add_dependency 'zeitwerk'

  spec.add_dependency 'pry'
  spec.add_dependency 'redis', '< 5'
  spec.add_dependency 'sidekiq', '> 5.1', '< 7.0'
end
