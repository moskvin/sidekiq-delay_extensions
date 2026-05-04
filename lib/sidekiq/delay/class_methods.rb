# frozen_string_literal: true

require "sidekiq/delay/generic_proxy"

module Sidekiq
  module Delay
    ##
    # Adds `delay`, `delay_for` and `delay_until` methods to all Classes to offload class method
    # execution to Sidekiq.
    #
    # @example
    #   User.delay.delete_inactive
    #   Wikipedia.delay.download_changes_for(Date.today)
    #
    class DelayedClass
      include Sidekiq::Job

      def perform(yml)
        (target, method_name, args, kwargs) = YAML.safe_load(yml, permitted_classes: [Symbol])
        target.__send__(method_name, *args, **kwargs)
      end
    end

    module Klass
      def sidekiq_delay(**options)
        Proxy.new(_sidekiq_delayed_job_class, self, **options)
      end

      def sidekiq_delay_for(interval, **options)
        Proxy.new(_sidekiq_delayed_job_class, self, **options.merge(at: Time.now.to_f + interval.to_f))
      end

      def sidekiq_delay_until(timestamp, **options)
        Proxy.new(_sidekiq_delayed_job_class, self, **options.merge(at: timestamp.to_f))
      end

      alias_method :delay, :sidekiq_delay
      alias_method :delay_for, :sidekiq_delay_for
      alias_method :delay_until, :sidekiq_delay_until

      private

      def _sidekiq_delayed_job_class
        const_set(:DelayedJob, Class.new(DelayedClass)) unless const_defined?(:DelayedJob, false)
        const_get(:DelayedJob, false)
      end
    end
  end
end

Module.include Sidekiq::Delay::Klass unless defined?(::Rails)
