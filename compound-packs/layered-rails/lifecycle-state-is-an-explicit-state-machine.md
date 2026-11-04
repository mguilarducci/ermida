---
title: A record's lifecycle state is an explicit state machine driven by events, never inferred from timestamps or flags
applies_when:
  - adding a status, lifecycle or workflow to a model
  - tracking progress with timestamps or boolean columns
tags: [layered-rails, state-machines, models]
---

Transitions happen through events that validate the move, not by assigning the state attribute directly.

How: `.claude/skills/layered-rails/references/patterns/state-machines.md`, `.claude/skills/layered-rails/examples/implicit-to-explicit-state-machine.md`.
