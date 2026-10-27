# sidekiq-defer Changes

1.0.0
---------

First release under its own version line; use this instead of 9.0.0.

- Jobs are named after their target in Sidekiq metrics, job logs and Sentry: the target's class
  name is stored in the job's `wrapped` key (`wrap_target: false` turns it off).
- Fix: 9.0.0 pushed `Foo::DeferredJob`, which was only defined in the process that called
  `Foo.delay`, so Sidekiq servers failed with `NameError`. Jobs run through the shared
  `Sidekiq::Defer::DelayedClass` / `DelayedModel` / `DelayedMailer` again.
- Fix: the Web UI showed raw YAML arguments for `Sidekiq::Defer::Delayed*` jobs.
- Fix: delayed mailer methods receive keyword arguments.
- `legacy_class_names: true` pushes `Sidekiq::DelayExtensions::Delayed*` for rolling deploys from
  `sidekiq-delay_extensions`.
- `Proxy#build_item` hook for adding keys to the job hash.
- `Sidekiq::Defer::DelayedClass` gets `jobs_for` under `Sidekiq::Testing`.
- Requires Sidekiq >= 7.0, < 9. Packages only files committed to git. Release tasks in `rakelib/release.rake`.
- Lint with RuboCop (single quotes) instead of StandardRB.
- Renamed gem to `sidekiq-defer`
- Module renamed from `Sidekiq::DelayExtensions` to `Sidekiq::Delay`
- `Sidekiq::DelayExtensions` kept as a backward-compatible alias

8.0.0
---------

- Support sidekiq v8.0+

7.0.0
---------

- Support sidekiq v6.5+

6.4.1
---------

- Extracted from https://github.com/mperham/sidekiq/tree/v6.4.1

6.4.0
---------

- Extracted from https://github.com/mperham/sidekiq/tree/v6.4.0
