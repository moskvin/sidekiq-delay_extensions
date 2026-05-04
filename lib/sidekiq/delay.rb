# frozen_string_literal: true

require "sidekiq"

module Sidekiq
  module Delay
    class << self; attr_accessor :limit_payload_size; end

    def self.enable_delay!(limit_payload_size: false)
      self.limit_payload_size = limit_payload_size
      if defined?(::ActiveSupport)
        require "sidekiq/delay/active_record"
        require "sidekiq/delay/action_mailer"

        # Need to patch Psych so it can autoload classes whose names are serialized
        # in the delayed YAML.
        Psych::Visitors::ToRuby.prepend(Sidekiq::Delay::PsychAutoload)

        ActiveSupport.on_load(:active_record) do
          include Sidekiq::Delay::ActiveRecord
        end
        ActiveSupport.on_load(:action_mailer) do
          extend Sidekiq::Delay::ActionMailer
        end
      end

      require "sidekiq/delay/class_methods"
      Module.include Sidekiq::Delay::Klass

      require "sidekiq/delay/api"
      Sidekiq::JobRecord.prepend(Sidekiq::Delay::JobRecord)
    end

    module PsychAutoload
      def resolve_class(klass_name)
        return nil if !klass_name || klass_name.empty?

        # constantize
        names = klass_name.split("::")
        names.shift if names.empty? || names.first.empty?

        names.inject(Object) do |constant, name|
          constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
        end
      rescue NameError
        super
      end
    end
  end

  DelayExtensions = Delay
end
