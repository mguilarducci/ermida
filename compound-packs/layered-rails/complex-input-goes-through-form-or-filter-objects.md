---
title: Complex user input goes through form objects and request filtering through filter objects, not fat controllers or models
applies_when:
  - building a form that writes several models or has validations specific to one screen
  - filtering, searching or sorting a listing from request parameters
tags: [layered-rails, forms, filters, controllers]
---

Form objects and filter objects are presentation layer: they turn request input into what the domain needs.
Context-specific validations stay out of the model.

How: `.claude/skills/layered-rails/references/patterns/form-objects.md`, `.claude/skills/layered-rails/references/patterns/filter-objects.md`,
`.claude/skills/layered-rails/examples/complex-input-to-form-object.md`.
