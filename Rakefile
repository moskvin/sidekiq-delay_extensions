# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'

Rake::TestTask.new(:test) do |test|
  test.warning = true
  test.pattern = 'test/**/*_test.rb'
end

RuboCop::RakeTask.new

task default: %i[rubocop test]
