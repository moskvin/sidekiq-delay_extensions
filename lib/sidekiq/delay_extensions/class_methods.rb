# frozen_string_literal: true

require 'sidekiq/delay_extensions/generic_proxy'

module Sidekiq
  module DelayExtensions
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
        Proxy.new(DelayedClass, self, **options)
      end

      def sidekiq_delay_for(interval, **options)
        Proxy.new(DelayedClass, self, **options.merge(at: Time.now.to_f + interval.to_f))
      end

      def sidekiq_delay_until(timestamp, **options)
        Proxy.new(DelayedClass, self, **options.merge(at: timestamp.to_f))
      end

      alias delay sidekiq_delay
      alias delay_for sidekiq_delay_for
      alias delay_until sidekiq_delay_until
    end
  end
end

Module.include Sidekiq::DelayExtensions::Klass unless defined?(::Rails)
