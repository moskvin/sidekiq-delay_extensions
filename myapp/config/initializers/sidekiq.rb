# frozen_string_literal: true

Sidekiq.configure_client do |config|
  config.redis = { size: 2 }
end

Sidekiq.configure_server do |config|
  config.on(:startup) {}
  config.on(:quiet) {}
  config.on(:shutdown) do
    # result = RubyProf.stop

    ## Write the results to a file
    ## Requires railsexpress patched MRI build
    # brew install qcachegrind
    # File.open("callgrind.profile", "w") do |f|
    # RubyProf::CallTreePrinter.new(result).print(f, :min_percent => 1)
    # end
  end
end

class EmptyWorker
  include Sidekiq::Job

  def perform; end
end

class TimedWorker
  include Sidekiq::Job

  def perform(start)
    now = Time.now.to_f
    puts "Latency: #{now - start} sec"
  end
end

Sidekiq::DelayExtensions.enable_delay!

module Myapp
  class Current < ActiveSupport::CurrentAttributes
    attribute :tenant_id
  end
end

require 'sidekiq/middleware/current_attributes'
Sidekiq::CurrentAttributes.persist(Myapp::Current) # Your AS::CurrentAttributes singleton
