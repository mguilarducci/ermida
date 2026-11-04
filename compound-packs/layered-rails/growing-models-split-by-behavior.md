---
title: A growing model is split by behavior into collaborator objects, value objects or behavioral concerns, never code-slicing concerns
applies_when:
  - adding many methods or a new responsibility to a large model
  - adding a concern
  - modeling an immutable concept such as money, a range or an address
tags: [layered-rails, models, concerns, collaborator-objects, value-objects, god-objects]
---

A concern groups one behavior, not one kind of artifact (all validations, all scopes). A slice of one model's
behavior becomes a collaborator object (`has_object`, from `active_record-associated_object` in the Gemfile).
Identity-less concepts become value objects.

How: `.claude/skills/layered-rails/references/patterns/collaborator-objects.md`, `.claude/skills/layered-rails/references/patterns/value-objects.md`,
`.claude/skills/layered-rails/references/patterns/concerns.md`, `.claude/skills/layered-rails/references/anti-patterns/concerns.md`,
`.claude/skills/layered-rails/examples/god-object-decomposition.md`; `/layered-rails-analyze-gods` finds god objects.
