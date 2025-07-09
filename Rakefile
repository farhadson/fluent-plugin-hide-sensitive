require "rake/testtask"
require "bundler/gem_tasks"

Rake::TestTask.new do |t|
  t.pattern = "test/**/test_*.rb"
  t.warning = true
end

task default: :test
