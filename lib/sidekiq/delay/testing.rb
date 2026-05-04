# frozen_string_literal: true

require "sidekiq/testing"

module Sidekiq
  module TestingDelay
    def jobs_for(klass)
      jobs.select do |job|
        marshalled = job["args"][0]
        marshalled.index(klass.to_s) && YAML.safe_load(marshalled, permitted_classes: [Symbol])[0] == klass
      end
    end

    def self.enable_delay_testing!
      if defined?(Sidekiq::Delay::DelayedMailer)
        Sidekiq::Delay::DelayedMailer.extend(TestingDelay)
      end
      if defined?(Sidekiq::Delay::DelayedModel)
        Sidekiq::Delay::DelayedModel.extend(TestingDelay)
      end
    end
  end

  TestingDelay.enable_delay_testing!

  TestingDelayExtensions = TestingDelay
end
