Sidekiq Delay Extensions
==============

[![Gem Version](https://badge.fury.io/rb/sidekiq-delay_extensions.svg)](https://rubygems.org/gems/sidekiq-delay_extensions)

The Sidekiq delay extensions were removed in Sidekiq 7.x. This gem restores them for apps still relying on the `delay`/`delay_for`/`delay_until` pattern.

Each target class gets its own namespaced worker (e.g. `MyModel::DelayedJob`, `UserMailer::DelayedJob`), so jobs appear clearly in Sidekiq metrics instead of the generic wrapper class name.

Requirements
-----------------

- Redis: 6.2+
- Ruby: MRI 3.2+
- Sidekiq 7.0+

Installation
-----------------

    gem 'sidekiq-delay_extensions'

In your initializer:

```ruby
Sidekiq::DelayExtensions.enable_delay!
```

Pass `limit_payload_size: true` (or a byte count) to log warnings on large YAML payloads:

```ruby
Sidekiq::DelayExtensions.enable_delay!(limit_payload_size: 8_192)
```

Upgrading from Sidekiq's built-in extensions (IMPORTANT)
-----------------

Jobs already in Redis were serialized with the old class names. Add these aliases so they can still be processed:

```ruby
Sidekiq::Extensions::DelayedClass  = Sidekiq::DelayExtensions::DelayedClass
Sidekiq::Extensions::DelayedModel  = Sidekiq::DelayExtensions::DelayedModel
Sidekiq::Extensions::DelayedMailer = Sidekiq::DelayExtensions::DelayedMailer
```

Testing
-----------------

```ruby
require 'sidekiq/delay_extensions/testing'
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
