---
title: View logic lives in presenters and view components; helpers never build HTML
applies_when:
  - formatting model data for display
  - adding logic to a template or a helper
  - building a reusable piece of UI
tags: [layered-rails, views, presenters, view-component, helpers]
---

View-specific formatting goes in a presenter. Reusable UI is a component inheriting `ApplicationViewComponent`,
with a preview for Lookbook. A helper with more than two or three `tag.*` calls, or nested HTML, becomes a
component.

How: `references/patterns/presenters.md`, `references/topics/view-components.md`,
`references/gems/view-component.md`, `references/anti-patterns/helpers.md`,
`examples/view-logic-to-presenter.md`.
