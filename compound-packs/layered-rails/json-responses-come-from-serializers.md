---
title: JSON responses come from serializers, never from as_json overrides in models
applies_when:
  - adding or changing an endpoint that returns JSON
  - exposing the same record in different shapes for different screens or clients
tags: [layered-rails, serializers, api, json]
---

Serialization is presentation layer. Use one serializer per context (list, detail, admin) instead of options
threaded through the model.

How: `references/patterns/serializers.md`.
