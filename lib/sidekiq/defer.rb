# frozen_string_literal: true

require "sidekiq"

module Sidekiq
  module Defer
    # Namespace the job classes lived in before the rename. Jobs already in Redis
    # reference it, and it resolves through the DelayExtensions alias below.
    LEGACY_NAMESPACE = "Sidekiq::DelayExtensions"

    class << self
      attr_accessor :limit_payload_size, :wrap_target, :legacy_class_names
    end
    self.wrap_target = true
    self.legacy_class_names = false

    # wrap_target: store the target's class name in the job's "wrapped" key, which
    #   Sidekiq uses to name the job in metrics, logs and error reports.
    # legacy_class_names: push jobs as Sidekiq::DelayExtensions::Delayed*, so processes
    #   still running sidekiq-delay_extensions can run them during a rolling deploy.
    def self.enable_delay!(limit_payload_size: false, wrap_target: true, legacy_class_names: false)
      self.limit_payload_size = limit_payload_size
      self.wrap_target = wrap_target
      self.legacy_class_names = legacy_class_names
      if defined?(::ActiveSupport)
        require "sidekiq/defer/active_record"
        require "sidekiq/defer/action_mailer"

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

      require "sidekiq/defer/class_methods"
      Module.include Sidekiq::Defer::Klass

      require "sidekiq/defer/api"
      Sidekiq::JobRecord.prepend(Sidekiq::Defer::JobRecord)
    end

    # The "class" pushed for a delayed job. Legacy names are skipped under
    # Sidekiq::Testing, which files jobs by class name.
    def self.job_class_name(performable)
      return performable.name unless legacy_class_names
      return performable.name if defined?(::Sidekiq::Testing) && ::Sidekiq::Testing.enabled?

      "#{LEGACY_NAMESPACE}::#{performable.name.split("::").last}"
    end

    # The "wrapped" value for a delayed job: the target's class name. It must be a
    # constant name, because Sidekiq's retry handler resolves it with const_get.
    def self.wrapped_name(target)
      return unless wrap_target

      (target.is_a?(::Module) ? target : target.class).name
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

  DelayExtensions = Defer
end
