---
title: LLM and agent calls live in the application or infrastructure layer and handle failures; models never call AI
applies_when:
  - adding a feature that calls an LLM, agent, embeddings or vector search
  - integrating an MCP server or AI tool calls
tags: [layered-rails, ai, llm, agents]
---

Agents go in `app/agents/` (application layer); a wrapped LLM client is infrastructure. Every AI call has a
failure path.

How: `references/topics/ai-integration.md`.
