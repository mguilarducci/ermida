---
title: New or moved Rails code goes in the layer whose primary responsibility it matches, decided with the specification test
applies_when:
  - deciding where new Rails code should live
  - adding a new class, folder or kind of object under app/
  - moving or extracting code between controllers, models, services or other app/ folders
tags: [layered-rails, layers, specification-test, placement]
---

The layers are presentation, application, domain and infrastructure; `Archspec.rb` lists the folders of each.
Lower layers never depend on higher ones. Before placing code, apply the specification test: list what the
object does, check each responsibility against its layer's primary concern, and extract the misplaced ones
downward. Do not place code by habit (`app/services` by default).

How, with the `layered-rails` skill: `references/core/specification-test.md`,
`references/core/architecture-layers.md`, and the "Pattern Selection Guide" in `SKILL.md`.
`workflows/spec-test.md` runs the test on existing files.
