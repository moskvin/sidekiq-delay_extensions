# frozen_string_literal: true

require 'sidekiq'

module Sidekiq
  module Defer
    class << self; attr_accessor :limit_payload_size; end

    def self.enable_delay!(limit_payload_size: false)
      self.limit_payload_size = limit_payload_size
      if defined?(::ActiveSupport)
        require 'sidekiq/defer/active_record'
        require 'sidekiq/defer/action_mailer'

        # Need to patch Psych so it can autoload classes whose names are serialized
        # in the delayed YAML.
        Psych::Visitors::ToRuby.prepend(Sidekiq::Defer::PsychAutoload)

        ActiveSupport.on_load(:active_record) do
          include Sidekiq::Defer::ActiveRecord
        end
        ActiveSupport.on_load(:action_mailer) do
          extend Sidekiq::Defer::ActionMailer
        end
      end

      require 'sidekiq/defer/class_methods'
      Module.include Sidekiq::Defer::Klass

      require 'sidekiq/defer/api'
      Sidekiq::JobRecord.prepend(Sidekiq::Defer::JobRecord)
    end

    module PsychAutoload
      def resolve_class(klass_name)
        return nil if !klass_name || klass_name.empty?

        # constantize
        names = klass_name.split('::')
        names.shift if names.empty? || names.first.empty?

        names.inject(Object) do |constant, name|
          constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
        end
      rescue NameError
        super
      end
    end
  end

  DelayExtensions = Defer
end
