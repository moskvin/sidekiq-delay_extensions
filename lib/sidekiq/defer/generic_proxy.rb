# frozen_string_literal: true

require 'yaml'

module Sidekiq
  module Defer
    DEFAULT_SIZE_LIMIT = 8_192

    class Proxy < BasicObject
      def initialize(performable, target, **options)
        @performable = performable
        @target = target
        @opts = options.transform_keys(&:to_s)
      end

      def respond_to_missing?(_name, _include_private = false)
        true
      end

      def method_missing(name, *args, **kwargs)
        # Sidekiq has a limitation in that its message must be JSON.
        # JSON can't round trip real Ruby objects so we use YAML to
        # serialize the objects to a String. The YAML will be converted
        # to JSON and then deserialized on the other side back into a
        # Ruby object.
        obj = [@target, name, args, kwargs]
        marshalled = ::YAML.dump(obj)
        print_warning(name, marshalled)

        @performable.client_push(build_item(name, marshalled))
      end

      # The job hash pushed to Sidekiq. Override (e.g. with prepend) to add keys.
      def build_item(name, marshalled)
        item = { 'class' => ::Sidekiq::Defer.job_class_name(@performable),
                 'args' => [marshalled],
                 'display_class' => "#{@target}.#{name}" }
        wrapped = ::Sidekiq::Defer.wrapped_name(@target)
        item['wrapped'] = wrapped if wrapped
        item.merge(@opts)
      end

      def print_warning(name, dump)
        limited_payload_size = Defer.limit_payload_size
        return unless limited_payload_size

        size = limited_payload_size == true ? DEFAULT_SIZE_LIMIT : limited_payload_size
        return if dump.bytesize <= size

        ::Sidekiq.logger.warn do
          "#{@target}.#{name} job argument is #{dump.bytesize} bytes, you should refactor it to reduce the size"
        end
      end
    end
  end
end
