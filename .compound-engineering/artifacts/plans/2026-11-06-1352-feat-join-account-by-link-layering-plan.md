---
title: Join an Account by Link, Layer Placement - Plan
type: feat
date: 2026-11-06
topic: join-account-by-link-layering
source: layered-rails workflows/plan.md
origin: .compound-engineering/artifacts/plans/2026-11-06-1313-feat-join-account-by-link-plan.md
execution: code
---

# Gradual Layerification Plan: Join an Account by link (#17)

The code below was corrected by planning research and two document reviews. References such as `KTD10` point to the Key Technical Decisions in the unified plan (`.compound-engineering/artifacts/plans/2026-11-06-1313-feat-join-account-by-link-plan.md`), whose units U1–U8 carry these same changes.

## Current State

- **Style:** partial layered. Controllers stay thin, multi-model input goes through form objects, authorization through Action Policy, email through Active Delivery, and `Archspec.rb` checks the layers. Domain rules sit on models (`Account.create_with_owner`, `Identity#create_magic_link`, `User#deactivate`).
- **Existing abstractions:**
  - Forms (`app/forms/`): `ApplicationForm`, with `SignInForm`, `SignupForm` and `AccountForm`.
  - Policies (`app/policies/`): `ApplicationPolicy` (`authorize :user, allow_nil: true`), `AccountPolicy` (`index?`, `create?`, `show?`) and `BusinessPolicy` (everything allowed).
  - Deliveries: `MagicLinkDelivery`, which fans out to `MagicLinkMailer#sign_in_instructions`.
  - Value objects: `MagicLink::Code` (`Data.define`, with `generate` and `parse`).
  - Controller concerns: `AccountScoping`, `Authentication` with `Authentication::ViaMagicLink`, and `Authorization`, whose `allow_unauthorized_access` was written for this page and has no caller yet.
  - `Archspec.rb`: the four-layer preset, the controller-API and `Current` rules, and the Authentication/Authorization boundary.
- **Relevant findings:**
  - No policy reads a role yet. The step 4 grep finds `role` only in the `User` enum and where `Account.create_with_owner` writes it, so the share page (R3) is the first role-based rule.
  - Nothing rescues `ActionPolicy::Unauthorized`, so a refused `authorize!` inside an Account ends in a 500. The brainstorm left that refusal open (AE7).
  - `Authentication::ViaMagicLink#redirect_to_session_magic_link` builds `session_magic_link_path` without `script_name: nil`. Called from a page under `/accounts/<slug>/`, the path keeps the slug, and the code page (`disallow_account_scope`) sends the person to `/` instead of showing the code form.
  - The only code generator is `MagicLink::Code`: 6 characters that live 15 minutes, too weak for a link that never changes (R1).
  - `SignupForm` already does the email step the join page needs (find or create the Identity, create a code, deliver it after commit). It uses purpose `sign_up`, which `Sessions::MagicLinksController#after_sign_in_url` sends to the new-Account form, so the join page cannot reuse it as is.
  - `config.filter_parameters` has no `code`, so a join code in the path, like the sign-in code posted today, reaches the logs in clear. Fizzy draws such routes inside `filter_path_parameters`, which only takes effect with its private structured-logging gem; Ermida's production log is Lograge's one line per request.
  - The only model callback is `MagicLink`'s `before_validation :generate_code, :set_expiration`, both transformers (5/5).
  - `app/helpers/application_helper.rb` is 2 lines with no `tag.*`, and the shared form markup already lives in `FormField::Component`.
  - A page that declares both `allow_unauthenticated_access` and `allow_unauthorized_access` runs nothing that loads the session, so `Current.identity` stays nil there, and Action Policy memoizes its authorization context on first use.
  - `ActiveRecord::Base.filter_attributes` is empty in development and test: the initializer's filter list never reaches Active Record, so `Identity#inspect` prints the email today.
  - Lograge is in the `:production` Gemfile group only, so tests cannot load it, and it logs each redirect's `location`.
  - The production image starts the app through Thruster (`Dockerfile`: `./bin/thrust`), which logs every request by default.
  - `app/javascript/controllers/` holds only `hello_controller.js`.

## Approach

The brainstorm fixed the behavior (R1–R14); this plan decides where each piece lives. Each phase adds a kind of object the codebase already has, so no new pattern enters the app.

1. Phase 1 puts the join code and the act of joining in the domain, because both later phases read them and model tests can cover them without HTTP. (pack: layered-rails, domain-logic-lives-in-models.md)
2. Phase 2 adds the first role-based rule, the share page, to `AccountPolicy`, then locks "role checks live in policies" in Archspec. It also decides what a refused page inside an Account does. (pack: layered-rails, authorization-lives-in-policies.md)
3. Phase 3 builds the join flow from two form objects and CRUD-only controllers. It reuses the code page and `MagicLinkDelivery` and adds no mailer. (pack: layered-rails, complex-input-goes-through-form-or-filter-objects.md; notifications-go-through-deliveries.md; controllers-expose-only-crud-actions.md)

The join page lives under the Account's prefix, at `/accounts/<slug>/join/<code>`, as Fizzy's does. That answers the brainstorm's first deferred question. `AccountScoping` resolves the Account from the slug, `allow_unauthenticated_access` and `allow_unauthorized_access` let signed-out visitors and non-users in, and every action checks the code against that Account (R11). The new route word comes after the slug, not after `/accounts/`, so `Account::RESERVED_SLUGS` stays as it is.

Phases 2 and 3 ship together: the share page shows a link that only Phase 3 makes work.

## Phase 1: Join code and joining in the domain

**Scope:** Small
**Goal:** Every Account carries a strong join code from its creation, and `Account#join` makes an Identity a member.

### Change 1: A value object for the join code

**File:** `app/models/account/join_code.rb` (new)

**Current:**
```ruby
# app/models/magic_link/code.rb, the only code generator today
class MagicLink::Code < Data.define(:value)
  LENGTH = 6
  # ...
  def self.generate = new(SecureRandom.alphanumeric(LENGTH, chars: ALPHABET))
end
```

**After** (corrected by research and review; the unified plan's KTDs record why):
```ruby
# A join link's secret: 12 base58 characters in groups of four, as in Fizzy (about 10^21 values), so a link that
# never changes cannot be guessed (R1).
class Account::JoinCode < Data.define(:value)
  LENGTH = 12

  def self.generate = new(SecureRandom.base58(LENGTH).scan(/.{4}/).join("-"))

  # Constant time, so response timing does not tell a guesser how much of a code is right.
  def matches?(input) = ActiveSupport::SecurityUtils.secure_compare(value, input.to_s)

  def to_s = value
end
```

**Pattern:** Value Objects (see references/patterns/value-objects.md), for "attributes with behavior (formatting, validation, comparison)", following `MagicLink::Code`
**Scenario:** none

### Change 2: An Account gets its join code when it is created

**Files:** `app/models/account.rb`, four migrations

**Current:**
```ruby
class Account < ApplicationRecord
  # ...
  validates_db_uniqueness_of :slug
```

**After** (corrected by research and review; the unified plan's KTDs record why):
```ruby
class Account < ApplicationRecord
  # ...
  validates_db_uniqueness_of :slug
  validates_db_uniqueness_of :join_code

  # Model inspection does not print the code (KTD10).
  self.filter_attributes += %i[join_code]

  before_validation :generate_join_code, on: :create

  def join_code?(input) = Account::JoinCode.new(join_code).matches?(input)

  private

  def generate_join_code
    self.join_code ||= Account::JoinCode.generate.to_s
  end
end
```

The callback is a transformer (5/5), like `MagicLink#generate_code`, so it stays on the model. The migrations follow strong_migrations' safe sequence (KTD11): a nullable column with an unvalidated `IS NOT NULL` check constraint; a backfill through a migration-local model that generates codes inline (`SecureRandom.base58(12)` in groups of four), so the migration depends on no app code; validating the constraint, `change_column_null false` and dropping the constraint in one transaction; and the unique index built concurrently in a migration of its own.

**Pattern:** Callbacks, transformer kept (see references/topics/callbacks.md)
**Scenario:** none

### Change 3: Joining is a rule of the Account

**File:** `app/models/account.rb`

**Current:**
```ruby
def self.create_with_owner(name:, owner:)
  transaction do
    create!(name:).tap do |account|
      account.users.create!(role: :system)
      account.users.create!(role: :owner, identity: owner, verified_at: Time.current)
    end
  end
end
```

**After** (corrected by research and review; the unified plan's KTDs record why):
```ruby
# A person joins as a member, verified by the code they typed (R11). One who is already an active user stays as they
# are (R6). One whose user was deactivated gets a new user, since leaving is one-way (R12).
def join(identity)
  raise ArgumentError, "joining needs a person" if identity.nil?

  users.active.find_by(identity:) || users.create!(identity:, role: :member, verified_at: Time.current)
rescue ActiveRecord::RecordInvalid => error
  raise unless error.record.errors.of_kind?(:identity_id, :taken)

  users.active.find_by!(identity:)
end
```

**Pattern:** Domain logic lives in models (pack: layered-rails, domain-logic-lives-in-models.md)
**Scenario:** none

**Stop here if:** never. Phases 2 and 3 both read the join code and `Account#join`.

---

## Phase 2: The share page behind AccountPolicy

**Scope:** Small
**Depends on:** Phase 1
**Goal:** Only owners and admins see the join link (R3), a refused page inside an Account has an answer, and Archspec keeps role checks inside policies.

### Change 1: What running the condominium means, on the User

**File:** `app/models/user.rb`

**Current:**
```ruby
enum :role, %w[member provider admin owner system].index_by(&:itself), default: :member, validate: true
```

**After** (corrected by research and review; the unified plan's KTDs record why):
```ruby
enum :role, %w[member provider admin owner system].index_by(&:itself), default: :member, validate: true

# Owners and admins run the condominium.
def administrator? = owner? || admin?
```

**Pattern:** Domain logic lives in models (pack: layered-rails, domain-logic-lives-in-models.md)
**Scenario:** none

### Change 2: The share and join rules in AccountPolicy

**File:** `app/policies/account_policy.rb`

**Current:**
```ruby
class AccountPolicy < ApplicationPolicy
  def index? = true

  def create? = true

  # Only the account's active users get in.
  def show? = user.present? && user.active? && user.account_id == record.id
end
```

**After** (corrected by research and review; the unified plan's KTDs record why):
```ruby
class AccountPolicy < ApplicationPolicy
  def index? = true

  def create? = true

  # Only the account's active users get in.
  def show? = user.present? && user.active? && user.account_id == record.id

  # Only owners and admins see the join link (R3).
  def share? = show? && user.administrator?

  # Joining is for people who are not yet active users of the account; those go straight in (R6).
  def join? = !show?
end
```

**Pattern:** Policy Objects (see references/patterns/policy-objects.md)
**Scenario:** Extract Authorization to Policy (see examples/authorization-to-policy.md)

### Change 3: The share page

**Files:** `app/controllers/shares_controller.rb` (new), `app/views/shares/show.html.erb` (new), `app/javascript/controllers/clipboard_controller.js` (new), `config/routes.rb`, `app/views/landings/show.html.erb`

**Current:** (none; the landing page links only to the account menu and sign-out)

**After** (corrected by research and review; the unified plan's KTDs record why):
```ruby
# config/routes.rb
resource :share, only: :show

# app/controllers/shares_controller.rb
# The share page: the account's join link, for its owners and admins (R3).
class SharesController < ApplicationController
  verify_authorized

  def show
    @account = Current.account
    authorize! @account, to: :share?
  end
end
```

The view shows `join_url(code: @account.join_code)` as selectable text, with a copy button wired to a new `clipboard` Stimulus controller that shows a short "Copied" confirmation. The join routes of Phase 3 Change 2 are drawn with this change, because `join_url` needs the named route; they lead nowhere until Phase 3 adds their controllers. The landing page links to the share page only when `allowed_to?(:share?, @account)`.

**Pattern:** Policy Objects (see references/patterns/policy-objects.md)
**Scenario:** Extract Authorization to Policy (see examples/authorization-to-policy.md)

### Change 4: A refused page inside an Account goes back to the Account's page

**File:** `app/controllers/concerns/authorization.rb`

**Current:**
```ruby
included do
  before_action :ensure_account_access, if: :account_access?
end
```

**After** (corrected by research and review; the unified plan's KTDs record why):
```ruby
included do
  before_action :ensure_account_access, if: :account_access?
  rescue_from ActionPolicy::Unauthorized, with: :deny_access
end

# ...

# A user refused one page of their account (a member on the share page, AE7) goes back to the account's page.
def deny_access
  redirect_to root_path, alert: t("authorization.denied"), status: :see_other
end
```

Outside an Account, `root_path` is `/`, which leads to the account menu.

**Pattern:** Policy Objects (see references/patterns/policy-objects.md)
**Scenario:** Extract Authorization to Policy (see examples/authorization-to-policy.md)

### Change 5: Lock role checks inside policies

**File:** `Archspec.rb`

**Current:** (no rule on roles)

**After** (corrected by research and review; the unified plan's KTDs record why):
```ruby
# Who may do what is a policy's decision: controllers, forms and components never read a role
presentation.cannot_call :administrator?, :owner?, :admin?,
  because: "role checks live in app/policies/"
```

The list leaves out `member?` and `provider?`, which `Set#member?` and `Hash#member?` share, since the rule cannot tell receivers apart. Run `dip archspec check`, then confirm the rule bites: put a throwaway `Current.user.owner?` call in a controller and check that `dip archspec check` fails on it. ERB views are not analyzed, so templates ask through `allowed_to?`.

**Pattern:** Policy Objects (see references/patterns/policy-objects.md); ArchSpec setup (see workflows/archspec.md)
**Scenario:** none

**Stop here if:** Phase 3 ships in a later pull request. In that case, hide the landing page's share link until it lands, since the link it shows leads nowhere yet.

---

## Phase 3: The join flow through form objects

**Scope:** Medium
**Depends on:** Phase 1, Phase 2 (`AccountPolicy#join?`, the refusal handler)
**Goal:** Opening the link, the email step, the code and the confirmation follow R5–R14, with HTTP in controllers, input in forms and the rules in the domain.

### Change 1: The code page works from inside an Account, and the join page can say where to return

**Files:** `app/controllers/concerns/authentication/via_magic_link.rb`, `app/controllers/concerns/authentication.rb`

**Current:**
```ruby
# via_magic_link.rb
def redirect_to_session_magic_link(email_address, magic_link)
  remember_pending_authentication(email_address)
  flash[:magic_link_code] = magic_link.code if magic_link && AuthenticationConfig.show_code_on_page?
  redirect_to session_magic_link_path, status: :see_other
end

# authentication.rb, the only writer of the return path
def request_authentication
  if request.get? && request.fullpath.bytesize <= 1.kilobyte
    session[:return_to_after_authenticating] = request.fullpath
  end
  redirect_to new_session_path(script_name: nil)
end
```

**After** (corrected by research and review; the unified plan's KTDs record why):
```ruby
# via_magic_link.rb: the code page belongs to no account, so the slug never goes with it
redirect_to session_magic_link_path(script_name: nil), status: :see_other

# authentication.rb
# Where signing in returns to, for a page that sends the person through the code page itself.
def return_after_authenticating_to(path)
  session[:return_to_after_authenticating] = path
end
```

**Pattern:** Specification test, HTTP and session concerns stay in controllers (see references/core/specification-test.md)
**Scenario:** none

### Change 2: The join routes and the code check

**Files:** `config/routes.rb`, `app/controllers/concerns/join_link_access.rb` (new)

**Current:** (none)

**After** (corrected by research and review; the unified plan's KTDs record why):
```ruby
# config/routes.rb
# A join link: /accounts/<slug>/join/<code>. The code is the secret (R1); no word is added under /accounts/.
get "join/:code", to: "joins#show", as: :join
post "join/:code", to: "joins#create"
scope "join/:code", module: :joins, as: :join do
  resource :membership, only: %i[new create]
end

# app/controllers/concerns/join_link_access.rb
# Pages behind a join link. They let in people who are not users of the account, so each checks that the code in
# the URL is the account's on every request, the confirmation included (R4, R11).
module JoinLinkAccess
  extend ActiveSupport::Concern

  included do
    allow_unauthorized_access
    before_action :resume_session
    before_action :require_join_code
    before_action :enter_account_as_user
  end

  private

  def require_join_code
    raise ActiveRecord::RecordNotFound unless Current.account.join_code?(params[:code])
  end

  # An active user of the account goes straight in (R6).
  def enter_account_as_user
    redirect_to root_path if allowed_to?(:show?, Current.account)
  end

  # The email typed on this device for this link; the confirmation opens only for it (KTD6).
  def remember_pending_join(email_address)
    session[:pending_join] = {"code" => params[:code], "email_address" => email_address}
  end

  def pending_join_for?(identity)
    pending = session[:pending_join] || {}
    pending["code"] == params[:code] && pending["email_address"] == identity&.email_address
  end

  def forget_pending_join
    session.delete(:pending_join)
  end
end
```

**Pattern:** Policy Objects, with authentication separate from authorization (see references/patterns/policy-objects.md)
**Scenario:** none

### Change 3: The email step through a form object

**Files:** `app/forms/join_request_form.rb` (new), `app/controllers/joins_controller.rb` (new), `app/views/joins/show.html.erb` (new)

**Current:**
```ruby
# app/forms/signup_form.rb: the same steps, with purpose sign_up
def submit!
  @identity = Identity.find_or_create_by_email_address(email_address)

  if identity.persisted?
    @magic_link = identity.create_magic_link(purpose: :sign_up)
  else
    raise ActiveRecord::RecordInvalid, identity
  end
end
```

**After** (corrected by research and review; the unified plan's KTDs record why):
```ruby
# app/forms/join_request_form.rb
# The join page's email step (R7): sends a sign-in code to the email, creating the person when the email is new,
# so the page answers the same for a known and an unknown email (R8). Purpose sign_in, so the code page returns to
# the confirmation instead of the new-account form, and the email is the fixed code email (R9).
class JoinRequestForm < ApplicationForm
  attribute :email_address, :string

  attr_reader :identity, :magic_link

  after_commit :deliver_code

  def email_address = Identity.normalize_value_for(:email_address, super)

  def from?(identity) = identity.present? && identity.email_address == email_address

  def save
    super
  rescue ActiveRecord::RecordInvalid => error
    errors.merge!(error.record.errors)
    false
  end

  private

  def submit!
    @identity = Identity.find_or_create_by_email_address(email_address)

    if identity.persisted?
      @magic_link = identity.create_magic_link(purpose: :sign_in)
    else
      raise ActiveRecord::RecordInvalid, identity
    end
  end

  def deliver_code
    if magic_link
      MagicLinkDelivery.sign_in_instructions(magic_link).deliver_later
    end
  end
end

# app/controllers/joins_controller.rb
# A join link's page (R5): names the account and always asks for an email (R7). Opening it creates nothing.
class JoinsController < ApplicationController
  include Authentication::ViaMagicLink
  include JoinLinkAccess

  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: :rate_limit_exceeded
  verify_authorized

  def show
    authorize! Current.account, to: :join?
    @join_request = JoinRequestForm.new
  end

  def create
    authorize! Current.account, to: :join?
    @join_request = JoinRequestForm.new(join_request_params)

    if @join_request.from?(Current.identity)
      remember_pending_join(@join_request.email_address)
      redirect_to new_join_membership_path(params[:code]), status: :see_other
    elsif @join_request.save
      send_code
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  def join_request_params = params.expect(join_request: [:email_address])

  # Another person's email ends the session on this device before the code goes out (R14).
  def send_code
    terminate_session if authenticated?
    remember_pending_join(@join_request.email_address)
    return_after_authenticating_to new_join_membership_path(params[:code])
    redirect_to_session_magic_link(@join_request.email_address, @join_request.magic_link)
  end

  def rate_limit_exceeded
    redirect_to join_path(params[:code]), alert: t("sessions.rate_limited"), status: :see_other
  end
end
```

`JoinRequestForm` repeats `SignupForm`'s steps with another purpose; Not Recommended below says why they stay two classes.

**Pattern:** Form Objects (see references/patterns/form-objects.md); notifications through deliveries (pack: layered-rails, notifications-go-through-deliveries.md)
**Scenario:** Form Object for Complex Input (see examples/complex-input-to-form-object.md)

### Change 4: The confirmation through a form object

**Files:** `app/forms/join_form.rb` (new), `app/controllers/joins/memberships_controller.rb` (new), `app/views/joins/memberships/new.html.erb` (new)

**Current:**
```ruby
# app/forms/account_form.rb: the pattern this follows (asks for the name only when missing)
validates :person_name, presence: true, if: :person_name_needed?

def person_name_needed? = identity.name.blank?

def submit!
  identity.update!(name: person_name) if person_name_needed?
  @account = Account.create_with_owner(name:, owner: identity)
end
```

**After** (corrected by research and review; the unified plan's KTDs record why):
```ruby
# app/forms/join_form.rb
# Confirming a join: saves the person's name when Ermida has none (R10) and makes them a member (R11).
class JoinForm < ApplicationForm
  attribute :person_name, :string

  attr_accessor :account, :identity
  attr_reader :user

  validates :person_name, presence: true, if: :person_name_needed?

  def person_name_needed? = identity.name.blank?

  def save
    super
  rescue ActiveRecord::RecordInvalid => error
    identity.restore_attributes
    copy_errors_from(error.record)
    false
  end

  private

  def submit!
    identity.update!(name: person_name) if person_name_needed?
    @user = account.join(identity)
  end

  def copy_errors_from(record)
    attribute = record.is_a?(Identity) ? :person_name : :base
    record.errors.each { |error| errors.add(attribute, error.type, **error.options) }
  end
end

# app/controllers/joins/memberships_controller.rb
# The confirmation (R11). It needs a session, which the code page started (R7) or the person already had (R14),
# and a pending join for this link and this person (KTD6).
class Joins::MembershipsController < ApplicationController
  include JoinLinkAccess

  before_action :require_pending_join
  verify_authorized

  def new
    authorize! Current.account, to: :join?
    @join = JoinForm.new(account: Current.account, identity: Current.identity)
  end

  def create
    authorize! Current.account, to: :join?
    @join = JoinForm.new(join_params.merge(account: Current.account, identity: Current.identity))

    if @join.save
      forget_pending_join
      redirect_to root_path, status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def join_params = params.fetch(:join, {}).permit(:person_name)

  def require_pending_join
    redirect_to join_path(params[:code]) unless pending_join_for?(Current.identity)
  end
end
```

**Pattern:** Form Objects (see references/patterns/form-objects.md)
**Scenario:** Form Object for Complex Input (see examples/complex-input-to-form-object.md)

### Change 5: Keep codes out of the logs

**Files:** `config/initializers/filter_parameter_logging.rb`, `config/application.rb`, `config/environments/production.rb`, `lib/join_link_log_filter.rb` (new), `Dockerfile`

**Current:**
```ruby
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc
]
```

**After** (corrected by research and review; the unified plan's KTDs record why):
```ruby
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc, /\Acode\z/, :join_code
]

# config/application.rb
# A redirect to a join page carries its code
config.filter_redirect << %r{/join/}

# lib/join_link_log_filter.rb
# A request path that carries a join code logs it as [FILTERED].
module JoinLinkLogFilter
  PATTERN = %r{(/join/)[^/?]+}

  def self.call(path) = path.to_s.gsub(PATTERN, '\1[FILTERED]')
end

# config/environments/production.rb
# One line per request instead of Rails' multi-line request logs. A path that carries a join code logs it as
# [FILTERED], as Fizzy's filter_path_parameters routes do.
config.lograge.enabled = true
config.lograge.custom_options = ->(event) { {path: JoinLinkLogFilter.call(event.payload[:path])} }

# Dockerfile, final stage: Lograge already logs each request with the join code scrubbed
ENV THRUSTER_LOG_REQUESTS=false
```

`/\Acode\z/` is an exact match, so `postcode` stays visible; it also filters the sign-in code posted to the code page. `Account` declares `join_code` in `filter_attributes` (Phase 1 Change 2), since the parameter list never reaches model inspection here. The scrubber lives in `lib/` so a unit test can cover it without Lograge. kamal-proxy's access log, outside the app container, still records the raw path until #26 adds regeneration.

**Pattern:** none (configuration hygiene)
**Scenario:** none

**Stop here if:** always. This is the last phase.

---

## Not Recommended for This Codebase

- **A service object for joining (`JoinAccount`):** `Account#join` holds the rule and `JoinForm` holds the input, so a service would only pass calls through. The skill keeps services as "a 'waiting room' for code until proper abstractions emerge" and warns "Don't let `app/services` become a bag of random objects"; here the abstractions already exist.
- **A shared base for `SignupForm` and `JoinRequestForm`:** two forms with the same steps and different purposes are not yet a pattern. The skill's guideline is "Patterns before abstractions - Let code age before extracting; premature abstraction is worse than duplication."
- **A query object for the code lookup:** the check compares one column on the Account the slug already loaded. A query object is for "Complex database query used in multiple places".
- **Presenters or ViewComponents for the join pages:** the step 4 helper check found a 2-line helper and no `tag.*` markup, and the form markup already lives in `FormField::Component`. The new views only print the Account's name, an email and a link.
- **Fizzy's separate join-code table (`Account::JoinCode` as a model with `usage_count` and `reset`):** R2 keeps the code permanent, with no usage limit, in this work. A table earns its place when #26 adds limits and regeneration; until then a column and the value object carry R1.

---

## Next Steps

1. Run the review workflow (`workflows/review.md`) after each phase, then `dip ci`.
2. Write each phase's tests first, in the layer that owns the behavior (pack: layered-rails, tests-target-the-layer-that-owns-the-behavior.md):
   - model tests: `Account::JoinCode`, the join code on creation, and `Account#join` (R6, R12, AE4)
   - policy tests: `AccountPolicy#share?` and `#join?` (R3, AE7)
   - form tests: `JoinRequestForm` (R8, AE8) and `JoinForm` (R10, AE2)
   - controller tests: AE3, AE5, AE6, AE9, AE10 and the rate limit
   - a system test: F1 end to end
3. No new gem. archspec 1.2.0 is already in the bundle for Phase 2 Change 5.
4. Hand this plan and the brainstorm to `ce-plan`, which turns them into implementation units.
