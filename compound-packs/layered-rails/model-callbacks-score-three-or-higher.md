---
title: Model callbacks score 3/5 or higher; callbacks that enqueue work or run side effects are extracted
applies_when:
  - adding or changing an Active Record callback
  - doing something when a record is created, updated or destroyed, such as sending email, enqueueing a job or calling an API
tags: [layered-rails, callbacks, models]
---

Score each callback: transformer (pure data transformation, `before_validation :normalize_email`) 5/5;
maintainer (internal consistency, `before_save :update_cached_count`) 4/5; timestamp (time-based attributes,
`before_create :set_published_at`) 3/5; background trigger (enqueues async work, `after_commit :enqueue_indexing`)
2/5; operation (synchronous side effects, `after_create :send_welcome_email`) 1/5. Callbacks below 3/5 are
extracted to an explicit service object or event handler. No control flags to skip callbacks. Work that must run
after the transaction commits, outside a model, uses `after_commit_everywhere` (in the Gemfile).

How: `references/topics/callbacks.md`, `references/anti-patterns/callbacks.md`,
`examples/callbacks-to-service.md`; `workflows/analyze-callbacks.md` scores existing callbacks.
