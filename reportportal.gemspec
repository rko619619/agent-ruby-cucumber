# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name                   = 'reportportal-ruby-cucumber'
  s.version                = File.read(File.expand_path('VERSION', __dir__)).strip
  s.summary                = 'ReportPortal Ruby Cucumber Client'
  s.description            = 'Cucumber client for EPAM ReportPortal system'
  s.authors                = ['Yan Ramanovich', 'Dmytro Berzhanin', 'Vsevolod Voloshyn']
  s.email                  = 'yan_ramanovich@epam.com'
  s.homepage               = 'https://github.com/rko619619/agent-cucumber-ruby'
  s.files                  = ['README.md', 'LICENSE'] + Dir['lib/**/*']
  s.required_ruby_version  = '>= 3.2.0'
  s.license                = 'Apache-2.0'
  s.platform = Gem::Platform::RUBY
  s.required_rubygems_version = '>= 3.2.8'

  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/rko619619/agent-ruby/issues',
  }

  s.add_dependency 'builder', '~> 3.2'
  s.add_dependency 'cucumber', '~> 9.0'
  s.add_dependency 'cucumber-ci-environment', '> 9', '< 11'
  s.add_dependency 'cucumber-core', '> 13', '< 14'
  s.add_dependency 'cucumber-cucumber-expressions', '~> 17.0'
  s.add_dependency 'cucumber-gherkin', '> 24', '< 28'
  s.add_dependency 'cucumber-html-formatter', '> 20.3', '< 22'
  s.add_dependency 'cucumber-messages', '> 19', '< 26'
  s.add_dependency 'http', '~> 5.2'
  s.add_dependency 'logging', '~> 2.4.0'
  s.add_dependency 'mime-types', '~> 3.5'
  s.add_dependency 'rubytree', '~> 2.1'

  s.add_development_dependency 'bundler-audit'
  s.add_development_dependency 'lefthook'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rspec', '~> 3.12'
  s.add_development_dependency 'rubocop', '~> 1.61.0'
  s.add_development_dependency 'rubocop-capybara', '~> 2.19.0'
  s.add_development_dependency 'rubocop-packaging', '~> 0.5.2'
  s.add_development_dependency 'rubocop-rake', '~> 0.6.0'
  s.add_development_dependency 'rubocop-rspec', '~> 2.25.0'
  s.add_development_dependency 'simplecov', '~> 0.22.0'
  s.add_development_dependency 'webrick', '~> 1.8'
  s.rdoc_options     = ['--charset=UTF-8']
  s.require_path     = 'lib'
end
