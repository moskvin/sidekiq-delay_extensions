# frozen_string_literal: true

require 'bundler/setup'
Bundler.require(:default, :test)

require 'minitest/pride'
require 'minitest/autorun'

$TESTING = true
# disable minitest/parallel threads
ENV['MT_CPU'] = '0'
ENV['N'] = '0'
# Disable any stupid backtrace cleansers
ENV['BACKTRACE'] = '1'

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    enable_coverage :branch
    add_filter '/test/'
    add_filter '/myapp/'
  end
  if ENV['CI']
    require 'codecov'
    SimpleCov.formatter = SimpleCov::Formatter::Codecov
  end
end

ENV['REDIS_URL'] ||= 'redis://localhost/15'

logger = ::Logger.new($stdout)
logger.level = Logger::ERROR

Sidekiq.configure_server { |c| c.logger = logger }
Sidekiq.configure_client { |c| c.logger = logger }

def capture_logging(level = Logger::INFO)
  old = Sidekiq.logger
  begin
    out = StringIO.new
    logger = ::Logger.new(out)
    logger.level = level
    Sidekiq.configure_client { |c| c.logger = logger }
    yield
    out.string
  ensure
    Sidekiq.configure_client { |c| c.logger = old }
  end
end
