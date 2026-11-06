---
title: Separate Authentication from Authorization, and test pages outside any account under a slug - Plan
type: refactor
date: 2026-11-05
topic: separate-authentication-authorization
source: layered-rails workflows/plan.md
origin: PR #11 code review, residual risk R2 and testing gap T2
execution: code
---

# Gradual Layerification Plan: Separate Authentication from Authorization (R2) and test pages that belong to no account under a slug (T2)

## Current State

- **Style:** partly layered. Forms (`app/forms/`), policies (`AccountPolicy`, `BusinessPolicy`), deliveries and components each have a base class. There is no `app/services/`. Action Policy is `~> 0.7.8`, and `Archspec.rb` enforces the four layers (archspec 1.2.0).
- **Existing abstractions:** `ApplicationPolicy` with `authorize :user, allow_nil: true`, plus the three controller concerns `AccountScoping`, `Authentication` and `Authorization`.
- **Relevant findings:**
  - The rule for who may enter an account already lives in a policy (`AccountPolicy#show?`), and `Authorization#ensure_account_access` only asks it. The step-4 grep found no inline permission checks in models or controllers. `role` only shows up in `User`'s enum and in `Account`'s creation of the first users.
  - **R2:** `Authentication.allow_unauthenticated_access` (`authentication.rb:10-13`) calls `allow_unauthorized_access`, which only `Authorization` defines. Opting out of sign-in therefore also opts out of the member check, and a controller that includes `Authentication` alone raises `NoMethodError`.
  - **T2:** `accounts/new` (`accounts_controller_test.rb:38`) and `session/menu` (`landings_controller_test.rb:66`) are tested under a slug. Sign-in, sign-up, the code page and businesses are not, so deleting `disallow_account_scope` from any of them breaks no test.
  - Call chains: only `ApplicationController` includes the three concerns, and Mission Control uses `ActionController::Base`. Three controllers call `allow_unauthenticated_access`: `SignupsController` directly, and `SessionsController` and `Sessions::MagicLinksController` through `require_unauthenticated_access`. All three also declare `disallow_account_scope`.

## Approach

The reference scenario, Extract Authorization to Policy, is already applied: the member rule is in `AccountPolicy`, and the controller only enforces it. What remains is the opt-out wiring. The skill says a policy is "Separate from authentication — authentication identifies, authorization permits" (`references/patterns/policy-objects.md`). So each concern gets its own opt-out, and a page names each check it skips.

Phase 1 makes that separation and locks it in with Archspec. Phase 2 adds the HTTP tests that pin each page that belongs to no account. Phase 2 needs Phase 1 for only one of its tests, so the rest of Phase 2 can land first, as the safety net for Phase 1.

## Phase 1: Each opt-out skips one check

**Scope:** Small
**Goal:** `Authentication` no longer refers to `Authorization`. A page that lets signed-out people in still runs the member check for signed-in people, unless it also declares `allow_unauthorized_access`.

### Change 1: `allow_unauthenticated_access` skips only the session check

**File:** `app/controllers/concerns/authentication.rb`

**Current:**
```ruby
def allow_unauthenticated_access(**options)
  skip_before_action :require_authentication, **options
  allow_unauthorized_access(**options)
end
```

**After:**
```ruby
def allow_unauthenticated_access(**options)
  skip_before_action :require_authentication, **options
end
```

**Pattern:** Policy Objects, "Separate from authentication" (see references/patterns/policy-objects.md)
**Scenario:** Extract Authorization to Policy (see examples/authorization-to-policy.md). Its end state already holds, and this change keeps enforcement in one concern.

### Change 2: Authorization states its dependency and its opt-out

**File:** `app/controllers/concerns/authorization.rb`

**Current:**
```ruby
# Inside an account, only its active users get in (AccountPolicy#show?). Anyone else goes back to the menu.
module Authorization
```

**After:**
```ruby
# Inside an account, only its active users get in (AccountPolicy#show?). Anyone else goes back to the menu.
# Runs after Authentication and reads its `authenticated?`; Authentication never refers back to this concern.
# A page that lets signed-in people who are not users of the account in (a join link) declares
# `allow_unauthorized_access` and authorizes the visitor itself.
module Authorization
```

**Pattern:** Policy Objects (see references/patterns/policy-objects.md)
**Scenario:** Extract Authorization to Policy (see examples/authorization-to-policy.md)

### Change 3: Lock the boundary in with Archspec

**File:** `Archspec.rb`

**Current:**
```ruby
# A top-level app/<x>/ folder names a layer or a concept, never a vendor
component(:vendor_folders, in: "app/{sidekiq,temporal,redis,stripe,kafka}/**/*.rb")
  .must_be_empty(because: "vendor code goes one level deeper, e.g. app/clients/stripe/")
```

**After:**
```ruby
# A top-level app/<x>/ folder names a layer or a concept, never a vendor
component(:vendor_folders, in: "app/{sidekiq,temporal,redis,stripe,kafka}/**/*.rb")
  .must_be_empty(because: "vendor code goes one level deeper, e.g. app/clients/stripe/")

# Authentication identifies the person; skipping the member check is Authorization's opt-out, declared by the page
authentication = component :authentication, in: %w[
  app/controllers/concerns/authentication.rb
  app/controllers/concerns/authentication/**/*.rb
]
authentication.cannot_call :allow_unauthorized_access, :ensure_account_access, receiver: :none,
  because: "skipping the member check is Authorization's opt-out, declared by the page"
```

A copy of this config, run with `dip archspec check --config` against the code before Change 1, reports one violation, and it is the R2 line:

```
[error] authentication must not call #allow_unauthorized_access [methods.forbid]
app/controllers/concerns/authentication.rb:12:7
1 architecture violation found.
```

A second run without a `presentation.can_only_use :authentication` top-up reported the same single violation. Version 1.2.0 needs no allowlist change for the overlapping component, so the line is left out. After Change 1, `dip archspec check` passes, and the pre-commit hook and CI keep it that way.

**Pattern:** Archspec lock-in (see references/gems/archspec.md, "Escape Hatches" and the `cannot_call` blocks)
**Scenario:** none for this step. plan.md step 2 requires the lock-in.

### Change 4: Pin the opt-out contract with a behavior test

**File:** `test/controllers/concerns/authorization_test.rb` (new)

**Current:** no test covers a page that allows signed-out access inside an account.

**After:** three integration tests against two probe controllers drawn with `with_routing`:
- a page with only `allow_unauthenticated_access` lets a signed-out visitor in under `/accounts/edificio-aurora/`;
- the same page sends a signed-in non-member to `/session/menu`;
- a page that also declares `allow_unauthorized_access` lets the signed-in non-member in.

`with_routing` replaces the whole route set, so it also draws the routes the concerns redirect to. Before Change 1, the second test fails, because the member check is skipped; after it, the test passes. If `with_routing` routes do not reach the controller, the fallback is a test-only route drawn in `config/routes.rb` under `if Rails.env.test?`.

**Pattern:** Tests target the layer that owns the behavior (pack: layered-rails, tests-target-the-layer-that-owns-the-behavior.md)
**Scenario:** none

### Change 5: Document the opt-outs

**File:** `AGENTS.md:79`

**Current:**
```
controllers opt out with `allow_unauthenticated_access`, or `require_unauthenticated_access` for pages only a
signed-out person needs.
```

**After:**
```
controllers opt out with `allow_unauthenticated_access`, or `require_unauthenticated_access` for pages only a
signed-out person needs. Neither skips the member check inside an account: a page that also lets in signed-in
people who are not users of the account declares `allow_unauthorized_access` (Authorization) and authorizes
the visitor itself.
```

**Pattern:** none (documentation)
**Scenario:** none

**Behavior change:** under a slug, a signed-in non-member who opens the sign-in, sign-up or code page now goes to `/session/menu` instead of `/`, because `ensure_account_access` runs before `redirect_tenanted_request`. Both destinations are outside the account, and `/` sends a signed-in person to the menu anyway. Signed-out visitors and members still go to `/`.

**Stop here if:** the join link is not coming soon. Phase 1 closes R2 by itself.

---

## Phase 2: Pages that belong to no account, opened under a slug

**Scope:** Small
**Depends on:** Phase 1, only for the non-member test in Change 1

Use literal paths in assertions: after a request inside an account, the test's url helpers keep the slug (`landings_controller_test.rb:49`). Each of these controllers declares `disallow_account_scope` before its `rate_limit` and its own `before_action`s, so the redirect happens before any rate-limit count, pending-email check or form runs.

### Change 1: Sign-in page

**File:** `test/controllers/sessions_controller_test.rb`

**Current:** no test opens `session/new` or posts to `session` under a slug.

**After:** under `/accounts/edificio-aurora/`, a signed-out `GET session/new` goes to `/`; a `POST session` with a known email goes to `/`, queues no email and creates no `MagicLink`; a signed-in non-member on `session/new` goes to `/session/menu` (Phase 1).

**Pattern:** Tests target the layer that owns the behavior (pack: layered-rails, tests-target-the-layer-that-owns-the-behavior.md)
**Scenario:** none

### Change 2: Sign-up page

**File:** `test/controllers/signups_controller_test.rb`

**Current:** no test opens `signup/new` or posts to `signup` under a slug.

**After:** `GET signup/new` goes to `/`; `POST signup` with a new email goes to `/`, with no `Identity`, no `MagicLink` and no email.

**Pattern:** Tests target the layer that owns the behavior (pack: layered-rails, tests-target-the-layer-that-owns-the-behavior.md)
**Scenario:** none

### Change 3: Code page

**File:** `test/controllers/sessions/magic_links_controller_test.rb`

**Current:** no test opens `session/magic_link` under a slug.

**After:** with a pending email, `GET session/magic_link` goes to `/`; `POST session/magic_link` with a valid code goes to `/`, starts no `Session` and leaves the code unused.

**Pattern:** Tests target the layer that owns the behavior (pack: layered-rails, tests-target-the-layer-that-owns-the-behavior.md)
**Scenario:** none

### Change 4: Businesses

**File:** `test/controllers/businesses_controller_test.rb`

**Current:** no test opens `businesses` under a slug.

**After:** a member of the account who opens `/accounts/<slug>/businesses` goes to `/`. The file's `setup` signs in someone who is a user of no account, who would be sent to the menu, so this test signs in a member.

**Pattern:** Tests target the layer that owns the behavior (pack: layered-rails, tests-target-the-layer-that-owns-the-behavior.md)
**Scenario:** none

**Stop here if:** always. This is the last phase.

---

## Not Recommended for This Codebase

- **Authorization overriding `allow_unauthenticated_access` with `super` plus `skip_before_action :ensure_account_access`** (the fix the PR #11 review suggested): it removes the `NoMethodError`, but opting out of sign-in would still opt out of the member check without the page saying so. That goes against the policy-objects rule "Separate from authentication — authentication identifies, authorization permits", and it is the trap the join link page would fall into.
- **A runtime test that `Authentication` works without `Authorization`:** Change 3's Archspec rule already rejects the call statically, in pre-commit and in CI.

---

## Next Steps

1. Write Phase 2's Changes 2 to 4, the first two tests of Phase 2 Change 1, and Phase 1 Change 4 first. Check that the non-member tests fail, then apply Phase 1 Changes 1 to 3.
2. Run the review workflow (`workflows/review.md`) after each phase, then `dip ci`.
3. No new gem. archspec 1.2.0 is already in the bundle and accepts the rule in Change 3.
