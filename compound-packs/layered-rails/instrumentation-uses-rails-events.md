---
title: Logging and metrics hook into ActiveSupport instrumentation events instead of being written inline in domain code
applies_when:
  - adding logging, metrics or tracing to an operation
  - measuring how often or how long something happens
tags: [layered-rails, instrumentation, logging, metrics]
---

Code publishes events; subscribers (log subscribers, metrics) consume them. Metrics are exported with Yabeda in
this app.

How: `references/topics/instrumentation.md`.
