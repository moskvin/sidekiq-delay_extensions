sidekiq-defer
==============

[![Gem Version](https://badge.fury.io/rb/sidekiq-defer.svg)](https://rubygems.org/gems/sidekiq-defer)

The Sidekiq delay extensions were removed in Sidekiq 7.x. This gem restores them for apps still relying on the `delay`/`delay_for`/`delay_until` pattern.

Each target class gets its own namespaced worker (e.g. `MyModel::DeferredJob`, `UserMailer::DeferredJob`), so jobs appear clearly in Sidekiq metrics instead of a generic wrapper class name.

Requirements
-----------------

- Redis: 6.2+
- Ruby: MRI 3.2+
- Sidekiq 7.0+

Installation
-----------------

    gem 'sidekiq-defer'

In your initializer:

```ruby
Sidekiq::Delay.enable_delay!
```

Pass `limit_payload_size: true` (or a byte count) to log warnings on large YAML payloads:

```ruby
Sidekiq::Delay.enable_delay!(limit_payload_size: 8_192)
```

Upgrading from Sidekiq's built-in extensions (IMPORTANT)
-----------------

Jobs already in Redis were serialized with the old class names. Add these aliases so they can still be processed:

```ruby
Sidekiq::Extensions::DelayedClass  = Sidekiq::Defer::DelayedClass
Sidekiq::Extensions::DelayedModel  = Sidekiq::Defer::DelayedModel
Sidekiq::Extensions::DelayedMailer = Sidekiq::Defer::DelayedMailer
```

Upgrading from `sidekiq-delay_extensions`
-----------------

`Sidekiq::DelayExtensions` and `Sidekiq::Delay` are aliased to `Sidekiq::Defer` — existing code continues to work without changes.

Testing
-----------------

```ruby
require 'sidekiq/defer/testing'
```

This hooks `DelayedMailer` and `DelayedModel` into Sidekiq's fake/inline testing modes.

Contributing
-----------------

Please open issues or pull requests at https://github.com/moskvin/sidekiq-delay_extensions.


License
-----------------

Please see [LICENSE](https://github.com/moskvin/sidekiq-delay_extensions/blob/sidekiq8/LICENSE) for licensing details.


Original Author
-----------------

Mike Perham, [@getajobmike](https://twitter.com/getajobmike) / [@sidekiq](https://twitter.com/sidekiq), [https://www.mikeperham.com](https://www.mikeperham.com) / [https://www.contribsys.com](https://www.contribsys.com)
