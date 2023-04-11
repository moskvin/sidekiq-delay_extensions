# frozen_string_literal: true

require 'sidekiq/testing'

module Sidekiq
  module TestingDelayExtensions
    def jobs_for(klass)
      jobs.select do |job|
        marshalled = job['args'][0]
        marshalled.index(klass.to_s) && YAML.safe_load(marshalled, permitted_classes: [Symbol])[0] == klass
      end
    end
  end

  Sidekiq::DelayExtensions::DelayedMailer.extend(TestingDelayExtensions) if defined?(Sidekiq::DelayExtensions::DelayedMailer)
  Sidekiq::DelayExtensions::DelayedModel.extend(TestingDelayExtensions) if defined?(Sidekiq::DelayExtensions::DelayedModel)
end
