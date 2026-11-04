# Coding standards

Rules Ruby code in this repository follows. Each one is visible in a diff and not enforced by Standard or
Archspec. Architecture rules (which layer code belongs in, which pattern fits) live in the `layered-rails`
Compound Pack (`compound-packs/layered-rails/`), not here.

## Conditionals

- Prefer an expanded `if`/`else` over a guard clause. A guard clause is fine only when it is the first
  statement of the method and the rest of the method is non-trivial (several lines). A guard in the middle of a
  method, or one that leaves a one-line body behind, is written as `if`/`else`.

  ```ruby
  # Instead of
  def todos_for_new_group
    ids = params.require(:todolist)[:todo_ids]
    return [] unless ids
    @bucket.recordings.todos.find(ids.split(","))
  end

  # write
  def todos_for_new_group
    if ids = params.require(:todolist)[:todo_ids]
      @bucket.recordings.todos.find(ids.split(","))
    else
      []
    end
  end
  ```

## Method order

- In a class, after the declarations (in models, the order the `layered-rails` skill gives: DSL extensions,
  associations, enums, normalization, validations, scopes, callbacks, delegations), methods go: class methods,
  then public instance methods with `initialize` first, then private methods.
- Private methods are ordered by invocation: each method sits right after the method that first calls it, so
  the class reads top-down.

## Maintaining this file

A rule belongs here only when a reviewer can see it in a diff and no check (Standard, Archspec, CI) already
enforces it. State each rule as a condition that stays true without naming volatile numbers or symbols. When a
change establishes or retires a rule, update this file in the same change.

The rules above were adopted from 37signals' Fizzy style guide
(https://github.com/basecamp/fizzy/blob/main/STYLE.md), keeping only what does not conflict with Standard or
the `layered-rails` skill.
