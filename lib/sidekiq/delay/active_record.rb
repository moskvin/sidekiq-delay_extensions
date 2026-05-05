# frozen_string_literal: true

require "sidekiq/delay/generic_proxy"

module Sidekiq
  module Delay
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
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def _sidekiq_delayed_job_class
          const_set(:DeferredJob, Class.new(DelayedModel)) unless const_defined?(:DeferredJob, false)
          const_get(:DeferredJob, false)
        end
      end

      def sidekiq_delay(**options)
        Proxy.new(self.class._sidekiq_delayed_job_class, self, **options)
      end

      def sidekiq_delay_for(interval, **options)
        Proxy.new(self.class._sidekiq_delayed_job_class, self, **options.merge(at: Time.now.to_f + interval.to_f))
      end

      def sidekiq_delay_until(timestamp, **options)
        Proxy.new(self.class._sidekiq_delayed_job_class, self, **options.merge(at: timestamp.to_f))
      end

      alias_method :delay, :sidekiq_delay
      alias_method :delay_for, :sidekiq_delay_for
      alias_method :delay_until, :sidekiq_delay_until
    end
  end
end
