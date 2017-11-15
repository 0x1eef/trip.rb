require 'bundler/setup'
require 'rake/testtask'
require 'rubygems/tasks'
Gem::Tasks.new
Rake::TestTask.new(:spec) do |t|
  t.test_files = FileList['spec/*_spec.rb']
  t.verbose = false
end
task :default => :spec
