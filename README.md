sidekiq-defer
==============

[![Gem Version](https://badge.fury.io/rb/sidekiq-defer.svg)](https://rubygems.org/gems/sidekiq-defer)

The Sidekiq delay extensions were removed in Sidekiq 7.x. This gem restores them for apps still relying on the `delay`/`delay_for`/`delay_until` pattern.

Requirements
-----------------

- Redis: 6.2+
- Ruby: MRI 3.2+
- Sidekiq 7.0+ (< 9)

Installation
-----------------

    gem 'sidekiq-defer', '~> 1.0'

In your initializer:

```ruby
Sidekiq::Defer.enable_delay!
```

Then any class, ActiveRecord model or mailer can run a method in the background:

```ruby
Report.delay.export(account_id)
Report.delay_for(10.minutes, queue: :low).export(account_id)
UserMailer.delay_until(1.day.from_now).welcome(user_id)
```

Options:

| Option | Default | |
|---|---|---|
| `limit_payload_size:` | `false` | `true` (8 KB) or a byte count: log a warning when the YAML payload is larger. |
| `wrap_target:` | `true` | Name the job after its target in metrics, logs and error reports (see below). |
| `legacy_class_names:` | `false` | Push jobs as `Sidekiq::DelayExtensions::Delayed*` (see upgrading). |

Metrics and naming
-----------------

Every delayed call runs through one of three job classes: `Sidekiq::Defer::DelayedClass`,
`DelayedModel` and `DelayedMailer`. The gem also stores the target's class name in the job's
`wrapped` key, as ActiveJob does. Sidekiq reads `wrapped` first, so `Report.delay.export` is listed
as `Report` on the Metrics page, in the job logger's `class` field, and in Sentry transaction names.
The Web UI shows `Report.export` and the original arguments.

`wrapped` is a class name, never `Report.export`: Sidekiq's retry handler resolves it with
`const_get`. If the target is itself a Sidekiq job class, its `sidekiq_retry_in` and
`sidekiq_retries_exhausted` blocks apply to the delayed call. To extend the job hash, prepend a
module that overrides `Sidekiq::Defer::Proxy#build_item`, or use Sidekiq client middleware.

Upgrading from `sidekiq-delay_extensions`
-----------------

`Sidekiq::DelayExtensions` and `Sidekiq::TestingDelayExtensions` are aliases of the new names,
so existing code and jobs already in Redis keep working.

New jobs are pushed as `Sidekiq::Defer::Delayed*`, which processes still running
`sidekiq-delay_extensions` can't resolve. For a rolling deploy:

1. Deploy with `Sidekiq::Defer.enable_delay!(legacy_class_names: true)`. Jobs keep the old class
   name but already get the `wrapped` name.
2. Once every process runs `sidekiq-defer`, remove `legacy_class_names: true`.

Under `Sidekiq::Testing`, the current class names are always used, so `Sidekiq::Defer::DelayedClass.jobs` works.

Upgrading from Sidekiq's built-in extensions
-----------------

Jobs already in Redis were serialized with the old class names. Add these aliases so they can still be processed:

```ruby
Sidekiq::Extensions::DelayedClass  = Sidekiq::Defer::DelayedClass
Sidekiq::Extensions::DelayedModel  = Sidekiq::Defer::DelayedModel
Sidekiq::Extensions::DelayedMailer = Sidekiq::Defer::DelayedMailer
```

Testing
-----------------

```ruby
require 'sidekiq/defer/testing'

Report.delay.export(1)
Sidekiq::Defer::DelayedClass.jobs.size          # => 1
Sidekiq::Defer::DelayedClass.jobs_for(Report)   # jobs whose target is Report
```

Releasing
-----------------

    rake "release:bump[minor]"   # bump version.rb, add a Changes.md section
    rake release:dry_run         # checks, lint, tests, package inspection; pushes nothing
    rake release                 # the same checks, then tag vX.Y.Z and push to rubygems.org

Contributing
-----------------

Please open issues or pull requests at https://github.com/moskvin/sidekiq-delay_extensions.


License
-----------------

Please see [LICENSE](https://github.com/moskvin/sidekiq-delay_extensions/blob/sidekiq8/LICENSE) for licensing details.


Original Author
-----------------

Mike Perham, [@getajobmike](https://twitter.com/getajobmike) / [@sidekiq](https://twitter.com/sidekiq), [https://www.mikeperham.com](https://www.mikeperham.com) / [https://www.contribsys.com](https://www.contribsys.com)
