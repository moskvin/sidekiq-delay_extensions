# frozen_string_literal: true

require_relative 'helper'
require_relative 'jobs'

describe 'Sidekiq::Testing.inline' do
  before do
    require 'sidekiq/delay_extensions/testing'
    require 'sidekiq/testing/inline'
    Sidekiq::Testing.inline!
  end

  after { Sidekiq::Testing.disable! }

  it 'stubs the async call when in testing mode' do
    assert InlineWorker.perform_async(true)

    assert_raises InlineError do
      InlineWorker.perform_async(false)
    end
  end

  describe 'delay' do
    require_relative 'models'

    before { Sidekiq::DelayExtensions.enable_delay! }

    it 'stubs the delay call on mailers' do
      assert_raises InlineError do
        InlineFooMailer.delay.bar('three')
      end
    end

    it 'stubs the delay call on models' do
      assert_raises InlineError do
        InlineFooModel.delay.bar('three', foo: 'bar')
      end
    end
  end

  it 'stubs the enqueue call when in testing mode' do
    assert Sidekiq::Client.enqueue(InlineWorker, true)

    assert_raises InlineError do
      Sidekiq::Client.enqueue(InlineWorker, false)
    end
  end

  it 'stubs the push_bulk call when in testing mode' do
    assert Sidekiq::Client.push_bulk({'class' => InlineWorker, 'args' => [[true], [true]]})

    assert_raises InlineError do
      Sidekiq::Client.push_bulk({'class' => InlineWorker, 'args' => [[true], [false]]})
    end
  end

  it 'should relay parameters through json' do
    assert Sidekiq::Client.enqueue(InlineWorkerWithTimeParam, Time.now.to_f)
  end
end
