---
title: A job that only calls one model method is declared with active_job-performs, not written as a job class
applies_when:
  - adding a background job
  - running a model method asynchronously
tags: [layered-rails, jobs, active-job-performs]
---

Jobs are inbound entry points (presentation layer), like controllers without authentication. A `perform` that is
a single call on its argument is an anemic job: use `performs` on the model instead. Keep a separate job class
only when it does real orchestration.

How: `.claude/skills/layered-rails/references/anti-patterns/jobs.md`, `.claude/skills/layered-rails/references/gems/active-job-performs.md`.
