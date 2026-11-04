---
title: Domain logic lives in models; controllers stay HTTP-only and services only orchestrate
applies_when:
  - adding business rules or calculations
  - adding a service object or anything under app/services
  - writing a controller action that does more than read the request and respond
tags: [layered-rails, services, controllers, models]
---

Controllers handle HTTP only. Rules about a domain concept go on its model (or a collaborator or value
object). A service orchestrates several domain operations and receives explicit values, never the request,
`params`, `session` or `Current`. Services are a waiting room until a proper abstraction emerges; `app/services`
must not become a bag of random objects.

How: `.claude/skills/layered-rails/references/patterns/service-objects.md`, `.claude/skills/layered-rails/references/anti-patterns/service-objects.md`,
`.claude/skills/layered-rails/references/topics/current-attributes.md`; `/layered-rails-analyze-services` audits the service layer.
