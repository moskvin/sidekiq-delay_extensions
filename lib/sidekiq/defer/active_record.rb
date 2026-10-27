# frozen_string_literal: true

require 'sidekiq/defer/generic_proxy'

module Sidekiq
  module Defer
    ##
    # Adds +delay+, +delay_for+ and +delay_until+ methods to ActiveRecord to offload instance method
    # execution to Sidekiq.
    #
    # @example
    #   User.recent_signups.each { |user| user.delay.mark_as_awesome }
    #
    # Please note, this is not recommended as this will serialize the entire
    # object to Redis.  Your Sidekiq jobs should pass IDs, not entire instances.
    # This is here for backwards compatibility with Delayed::Job only.
    class DelayedModel
      include Sidekiq::Job

      def perform(yml)
        (target, method_name, args, kwargs) = YAML.safe_load(yml, permitted_classes: [Symbol])
        target.__send__(method_name, *args, **kwargs.to_h)
      end
    end

    module ActiveRecord
      def sidekiq_delay(**)
        Proxy.new(DelayedModel, self, **)
      end

      def sidekiq_delay_for(interval, **)
        Proxy.new(DelayedModel, self, **, at: Time.now.to_f + interval.to_f)
      end

      def sidekiq_delay_until(timestamp, **)
        Proxy.new(DelayedModel, self, **, at: timestamp.to_f)
      end

      alias delay sidekiq_delay
      alias delay_for sidekiq_delay_for
      alias delay_until sidekiq_delay_until
    end
  end
end
