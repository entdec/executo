# frozen_string_literal: true

require "bundler/setup"
require "executo"
require "rake/testtask"
require "rubocop/rake_task"
require "standard/rake"
Bundler.setup

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

desc "Run rubocop"
task :rubocop do
  RuboCop::RakeTask.new
end

task default: %i[test standard rubocop]

# Adds the Auxilium semver task
spec = Gem::Specification.find_by_name "auxilium"
load "#{spec.gem_dir}/lib/tasks/semver.rake"

desc "Build and push the gem to GitHub"
task :build do
  sh "gem build executo.gemspec"
  load "lib/executo/version.rb"
  sh "gem push --key github --host https://rubygems.pkg.github.com/entdec executo-#{Executo::VERSION}.gem"
  sh "rm executo-#{Executo::VERSION}.gem"
end

task release: %i[default executo:semver build]
