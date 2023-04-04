# frozen_string_literal: true

require 'sidekiq/delay_extensions/generic_proxy'

module Sidekiq
  module DelayExtensions
    ##
    # Adds +delay+, +delay_for+ and +delay_until+ methods to ActionMailer to offload arbitrary email
    # delivery to Sidekiq.
    #
    # @example
    #    UserMailer.delay.send_welcome_email(new_user)
    #    UserMailer.delay_for(5.days).send_welcome_email(new_user)
    #    UserMailer.delay_until(5.days.from_now).send_welcome_email(new_user)
    class DelayedMailer
      include Sidekiq::Job

      def perform(yml)
        (target, method_name, args) = YAML.safe_load(yml, permitted_classes: [Symbol])
        msg = target.public_send(method_name, *args)
        # The email method can return nil, which causes ActionMailer to return
        # an undeliverable empty message.
        raise "#{target.name}##{method_name} returned an undeliverable mail object" unless msg

        msg.deliver_now
      end
    end

    module ActionMailer
      def sidekiq_delay(options = {})
        Proxy.new(DelayedMailer, self, options)
      end

      def sidekiq_delay_for(interval, options = {})
        Proxy.new(DelayedMailer, self, options.merge('at' => Time.now.to_f + interval.to_f))
      end

      def sidekiq_delay_until(timestamp, options = {})
        Proxy.new(DelayedMailer, self, options.merge('at' => timestamp.to_f))
      end

      alias delay sidekiq_delay
      alias delay_for sidekiq_delay_for
      alias delay_until sidekiq_delay_until
    end
  end
end
