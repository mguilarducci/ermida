---
title: Configuration is read through Anyway Config classes, never from ENV or credentials directly
applies_when:
  - adding a setting, secret, API key, URL or feature toggle
  - writing code that needs a value from the environment or credentials
tags: [layered-rails, configuration, anyway-config]
---

Each setting belongs to a class under `config/configs/` inheriting `ApplicationConfig`, read as a class method.
`enforce_config_schema` is on, so unknown keys raise.

How: the `anyway-config` skill (`.agents/skills/anyway-config/`), `references/topics/configuration.md`,
`references/gems/anyway-config.md`.
