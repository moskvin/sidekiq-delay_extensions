# frozen_string_literal: true

require 'yaml'

module Sidekiq
  module DelayExtensions
    DEFAULT_SIZE_LIMIT = 8_192

    class Proxy < BasicObject
      def initialize(performable, target, **options)
        @performable = performable
        @target = target
        @opts = options.transform_keys(&:to_s)
      end

      def respond_to_missing?
        true
      end

      def method_missing(name, *, **)
        # Sidekiq has a limitation in that its message must be JSON.
        # JSON can't round trip real Ruby objects so we use YAML to
        # serialize the objects to a String. The YAML will be converted
        # to JSON and then deserialized on the other side back into a
        # Ruby object.
        obj = [@target, name, [*], {**}]
        marshalled = ::YAML.dump(obj)
        print_warning(name, marshalled)

        @performable.client_push({ 'class' => @performable,
                                   'args' => [marshalled],
                                   'display_class' => "#{@target}.#{name}" }.merge(@opts))
      end

      def print_warning(name, dump)
        limited_payload_size = DelayExtensions.limit_payload_size
        return unless limited_payload_size

        size = limited_payload_size != true ? limited_payload_size : DEFAULT_SIZE_LIMIT
        return if dump.size <= size

        ::Sidekiq.logger.warn do
          "#{@target}.#{name} job argument is #{dump.bytesize} bytes, you should refactor it to reduce the size"
        end
      end
    end
  end
end
