# frozen_string_literal: true

require_relative 'lib/sidekiq/defer/version'

Gem::Specification.new do |spec|
  spec.name = 'sidekiq-defer'
  spec.version = Sidekiq::Defer::VERSION
  spec.authors = ['Mike Perham', 'Benjamin Fleischer']
  spec.email = %w[mperham@gmail.com github@benjaminfleischer.com]

  spec.summary = 'Sidekiq Defer Extensions'
  spec.description = 'Delay extensions for Sidekiq 7+'
  spec.homepage = 'https://github.com/moskvin/sidekiq-delay_extensions'
  spec.license = 'LGPL-3.0-or-later'

  spec.files = Dir.glob('{bin,lib,config}/**/*') + %w[
    Changes.md
    Gemfile
    LICENSE
    README.md
    sidekiq-defer.gemspec
  ]

  spec.bindir = 'exe'
  spec.executables = []
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata = {
    'homepage_uri' => 'https://github.com/moskvin/sidekiq-delay_extensions',
    'bug_tracker_uri' => 'https://github.com/moskvin/sidekiq-delay_extensions/issues',
    'changelog_uri' => 'https://github.com/moskvin/sidekiq-delay_extensions/blob/sidekiq8/Changes.md',
    'source_code_uri' => 'https://github.com/moskvin/sidekiq-delay_extensions'
  }

  spec.add_dependency 'sidekiq', '< 9'
end
