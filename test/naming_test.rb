# frozen_string_literal: true

require_relative 'helper'
require_relative 'models'
require 'json'
require 'open3'
require 'rbconfig'
require 'sidekiq/api'
require 'sidekiq/job_retry'
require 'sidekiq/metrics/tracking'

Sidekiq::Defer.enable_delay!

class KwargsMailer < ActionMailer::Base
  def hello(name:)
    mail(to: 'a@example.com', from: 'b@example.com', subject: "Hi #{name}", body: name)
  end
end

describe 'job naming' do
  # Push to real Redis even when another test file has loaded Sidekiq::Testing.
  def without_testing(&)
    defined?(Sidekiq::Testing) ? Sidekiq::Testing.disable!(&) : yield
  end

  def enqueue
    without_testing do
      yield
      Sidekiq::Queue.new.first.item
    end
  end

  before { Sidekiq.redis(&:flushdb) }

  after do
    Sidekiq::Defer.wrap_target = true
    Sidekiq::Defer.legacy_class_names = false
  end

  it 'wraps class targets with the class name' do
    job = enqueue { SomeClass.delay.doit(1) }

    assert_equal 'Sidekiq::Defer::DelayedClass', job['class']
    assert_equal 'SomeClass', job['wrapped']
    assert_equal 'SomeClass.doit', job['display_class']
  end

  it 'wraps module and mailer targets' do
    assert_equal 'SomeModule', enqueue { SomeModule.delay.doit(1) }['wrapped']
    Sidekiq.redis(&:flushdb)
    job = enqueue { UserMailer.delay.greetings(1, 2) }

    assert_equal 'Sidekiq::Defer::DelayedMailer', job['class']
    assert_equal 'UserMailer', job['wrapped']
  end

  it 'wraps instances with their class name' do
    assert_equal 'SomeClass', Sidekiq::Defer.wrapped_name(SomeClass.new)
  end

  it 'does not wrap anonymous classes' do
    assert_nil Sidekiq::Defer.wrapped_name(Class.new)
  end

  it 'can turn wrapping off' do
    Sidekiq::Defer.wrap_target = false

    refute enqueue { SomeClass.delay.doit(1) }.key?('wrapped')
  end

  it 'pushes legacy class names when asked' do
    Sidekiq::Defer.legacy_class_names = true
    job = enqueue { SomeClass.delay.doit(1) }

    assert_equal 'Sidekiq::DelayExtensions::DelayedClass', job['class']
    assert_equal 'SomeClass', job['wrapped']
  end

  it 'names the job after the target in metrics' do
    tracked = []
    tracker = Object.new
    tracker.define_singleton_method(:track) do |queue, klass, &blk|
      tracked << [queue, klass]
      blk.call
    end
    job = enqueue { SomeClass.delay.doit(1) }

    Sidekiq::Metrics::Middleware.new(tracker).call(nil, job, 'default') { nil }

    assert_equal [%w[default SomeClass]], tracked
  end

  it 'keeps the default retry for a wrapped class that is not a Sidekiq job' do
    job = enqueue { SomeClass.delay.doit(1) }
    retrier = Sidekiq::JobRetry.new(Sidekiq.default_configuration)

    output = capture_logging(Logger::WARN) do
      strategy, = retrier.send(:delay_for, Sidekiq::Defer::DelayedClass.new, 1, StandardError.new, job)

      assert_equal :default, strategy
    end

    refute_match(/Failure scheduling retry/, output)
  end

  it 'passes keyword arguments to mailers' do
    ActionMailer::Base.delivery_method = :test
    job = enqueue { KwargsMailer.delay.hello(name: 'Ann') }

    Sidekiq::Defer::DelayedMailer.new.perform(*job['args'])

    assert_equal 'Hi Ann', ActionMailer::Base.deliveries.last.subject
  end

  # Regression: 9.0.0 pushed Foo::DeferredJob, a constant that only existed in the
  # process that called Foo.delay, so Sidekiq servers could not resolve it.
  it 'runs in a process that never called delay' do
    job = enqueue { SomeClass.delay.doit(1) }
    script = <<~RUBY
      require 'json'
      require 'active_support' # the YAML class autoloading is only installed for ActiveSupport apps
      require 'sidekiq/defer'
      Sidekiq::Defer.enable_delay!
      class SomeClass
        def self.doit(arg) = print("ran with \#{arg}")
      end
      job = JSON.parse($stdin.read)
      Object.const_get(job['class']).new.perform(*job['args'])
    RUBY
    lib = File.expand_path('../lib', __dir__)

    out, status = Open3.capture2e(RbConfig.ruby, '-I', lib, '-e', script, stdin_data: JSON.dump(job))

    assert_predicate status, :success?, out
    assert_match(/ran with 1\z/, out)
  end
end
