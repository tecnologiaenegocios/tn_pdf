require 'rake'
require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

desc "Run all examples with RCov"
RSpec::Core::RakeTask.new('examples_with_rcov') do |t|
  t.rcov = true
  # t.rcov_opts = ['--exclude', 'spec,.bundle']
end
