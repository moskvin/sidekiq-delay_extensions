# frozen_string_literal: true

class PerformError < RuntimeError; end
class InlineError < RuntimeError; end
class ParameterIsNotString < RuntimeError; end

class DirectWorker
  include Sidekiq::Job
  def perform(foo, bar)
    foo + bar
  end
end

class EnqueuedWorker
  include Sidekiq::Job
  def perform(foo, bar)
    foo + bar
  end
end

class StoredWorker
  include Sidekiq::Job
  def perform(error)
    raise PerformError if error
  end
end

class SpecificJidWorker
  include Sidekiq::Job
  sidekiq_class_attribute :count
  self.count = 0
  def perform(worker_jid)
    return unless worker_jid == jid

    self.class.count += 1
  end
end

class FirstWorker
  include Sidekiq::Job
  sidekiq_class_attribute :count
  self.count = 0
  def perform
    self.class.count += 1
  end
end

class SecondWorker
  include Sidekiq::Job
  sidekiq_class_attribute :count
  self.count = 0
  def perform
    self.class.count += 1
  end
end

class ThirdWorker
  include Sidekiq::Job
  sidekiq_class_attribute :count
  def perform
    FirstWorker.perform_async
    SecondWorker.perform_async
  end
end

class InlineWorker
  include Sidekiq::Job
  def perform(pass)
    raise ArgumentError, 'no jid' unless jid
    raise InlineError unless pass
  end
end

class InlineWorkerWithTimeParam
  include Sidekiq::Job
  def perform(time)
    raise ParameterIsNotString unless time.is_a?(String) || time.is_a?(Numeric)
  end
end
