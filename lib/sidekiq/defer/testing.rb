# frozen_string_literal: true

require "sidekiq/testing"

module Sidekiq
  module TestingDefer
    def jobs_for(klass)
      jobs.select do |job|
        marshalled = job["args"][0]
        marshalled.index(klass.to_s) && YAML.safe_load(marshalled, permitted_classes: [Symbol])[0] == klass
      end
    end

    def self.enable_delay_testing!
      if defined?(Sidekiq::Defer::DelayedMailer)
        Sidekiq::Defer::DelayedMailer.extend(TestingDefer)
      end
      if defined?(Sidekiq::Defer::DelayedModel)
        Sidekiq::Defer::DelayedModel.extend(TestingDefer)
      end
    end
  end

  TestingDefer.enable_delay_testing!

  TestingDelay = TestingDefer
  TestingDelayExtensions = TestingDefer
end
