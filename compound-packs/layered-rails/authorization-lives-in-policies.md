---
title: Authorization rules live in Action Policy policies, never inline in controllers, views or models
applies_when:
  - deciding who may see or do something
  - adding a permission check, role or admin-only action
  - scoping a listing to what the current user may access
tags: [layered-rails, authorization, action-policy, policies]
---

Each rule is a policy under `app/policies/` inheriting `ApplicationPolicy`; controllers and views ask the policy.
Models do not check permissions.

How: `.claude/skills/layered-rails/references/patterns/policy-objects.md`, `.claude/skills/layered-rails/references/topics/authorization.md`,
`.claude/skills/layered-rails/references/gems/action-policy.md`, `.claude/skills/layered-rails/examples/authorization-to-policy.md`.
