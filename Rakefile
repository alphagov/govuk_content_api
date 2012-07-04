lib = File.expand_path("../lib", __FILE__)
$:.unshift lib unless $:.include?(lib)

require "rake"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.libs << File.dirname(__FILE__)
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
end

task :default => :test

require "ci/reporter/rake/test_unit" if ENV["RACK_ENV"] == "test"