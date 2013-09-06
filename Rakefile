require 'rake/testtask'
require 'bundler/gem_tasks'

desc "Run tests"
Rake::TestTask.new do |test|
  test.libs << 'test'
  test.test_files = Dir['test/*_test.rb']
  test.verbose = true
end