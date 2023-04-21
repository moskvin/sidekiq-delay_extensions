require 'active_record'
require 'action_mailer'

class UserMailer < ActionMailer::Base
  def greetings(_foo, _bar)
    raise 'Should not be called!'
  end
end

class MyModel < ActiveRecord::Base
  def self.long_class_method
    raise 'Should not be called!'
  end
end

class SomeClass
  def self.doit(_arg); end
end

module SomeModule
  def self.doit(_arg); end
end

class InlineFooMailer < ActionMailer::Base
  def bar(_str)
    raise InlineError
  end
end

class InlineFooModel
  def self.bar(_str)
    raise InlineError
  end
end

class FooMailer < ActionMailer::Base
  def bar(_str)
    str
  end
end

class Something
  def self.foo(_bar); end
end

class BarMailer < ActionMailer::Base
  def foo(_str)
    str
  end
end
