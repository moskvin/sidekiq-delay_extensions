# frozen_string_literal: true

require_relative 'helper'
require 'sidekiq/api'
require 'active_job'
require 'action_mailer'

class ApiMailer < ActionMailer::Base
  def test_email(*); end
end

class ApiJob < ActiveJob::Base
  def perform(*); end
end

class ApiWorker
  include Sidekiq::Job
end

class WorkerWithTags
  include Sidekiq::Job
  sidekiq_options tags: ['foo']
end

describe 'API' do
  before { Sidekiq.redis(&:flushdb) }

  describe 'with an empty database' do
    before do
      ActiveJob::Base.queue_adapter = :sidekiq
      ActiveJob::Base.logger = nil
    end

    it 'shows queue as empty' do
      q = Sidekiq::Queue.new
      assert_equal 0, q.size
      assert_equal 0, q.latency
    end

    it 'unwraps delayed jobs' do
      Sidekiq::DelayExtensions.enable_delay!
      Sidekiq::Queue.delay.foo(1, 2, 3)
      q = Sidekiq::Queue.new
      x = q.first
      assert_equal 'Sidekiq::Queue.foo', x.display_class
      assert_equal [1, 2, 3], x.display_args
    end
  end
end
