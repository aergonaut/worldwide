# frozen_string_literal: true

require "bundler/setup"
require "bundler/gem_tasks"
require "rake/testtask"

desc "Run a console session"
task :console do
  sh "bin/console"
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

require "rubocop/rake_task"

RuboCop::RakeTask.new

Dir.glob("rake/tasks/*.rake").each { |r| load r }

task default: [:test, :rubocop]
