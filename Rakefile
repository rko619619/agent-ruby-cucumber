# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# used for testing purposes
require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %w[rubocop test]
