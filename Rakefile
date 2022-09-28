# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"


Rake::TestTask.new(:test) do |t|
  desc "Run tests"
  ENV["TESTOPTS"] = "-v" unless ENV["TESTOPTS"]
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: :test
