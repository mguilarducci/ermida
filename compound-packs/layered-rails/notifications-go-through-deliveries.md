---
title: Notifications go through an Active Delivery delivery, never a mailer called from a model
applies_when:
  - sending an email or any other notification
  - notifying users or admins when something happens in the app
tags: [layered-rails, notifications, active-delivery, mailers]
---

Notifications belong to the application layer. A delivery under `app/deliveries/` inheriting `ApplicationDelivery`
fans one notification out to every channel (`PostsDelivery.published(post)` calls `PostsMailer.published`).
Models and model callbacks never send notifications.

How: `.claude/skills/layered-rails/references/topics/notifications.md`, `.claude/skills/layered-rails/references/gems/active-delivery.md`.
