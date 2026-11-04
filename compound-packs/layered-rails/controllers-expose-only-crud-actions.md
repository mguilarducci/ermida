---
title: Controllers expose only the standard CRUD actions; an action that fits no CRUD verb becomes a new resource
applies_when:
  - adding a controller action or a route
  - adding a button or endpoint that changes a record's state, such as close, reopen, archive, publish or pin
  - designing the routes for a new feature
tags: [layered-rails, controllers, routes, rest, crud]
---

Web endpoints are CRUD on resources. When an action does not map to `index`, `show`, `new`, `create`, `edit`,
`update` or `destroy`, introduce a resource for it instead of a custom action: closing a card is `create` on
`resource :closure` nested under `resources :cards`, and reopening it is `destroy` on the same resource, not
`post :close` and `post :reopen`. The new controller stays thin and calls an intention-revealing model method
(`Cards::GoldnessesController#create` calls `@card.gild`); the domain logic stays in the model.

Source: 37signals' Fizzy style guide, "CRUD controllers" (https://github.com/basecamp/fizzy/blob/main/STYLE.md).
Thin controllers and where the logic goes: `domain-logic-lives-in-models.md` in this pack.
