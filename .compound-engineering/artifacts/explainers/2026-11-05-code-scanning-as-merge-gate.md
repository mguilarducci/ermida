---
title: Code scanning as the merge gate
date: 2026-11-05
input_shape: concept
subject: Letting security scanners report to GitHub code scanning and blocking merges on new alerts, instead of failing the scanner's job
---

# Code scanning as the merge gate

## What it is

GitHub code scanning stores findings that tools upload as SARIF, a JSON format for static-analysis results. Each
upload belongs to an analysis, identified by the workflow file, the job and a category. When a pull request
uploads, code scanning compares its alerts with the latest analysis of the base branch and marks the ones the
pull request introduces. A repository ruleset rule ("Require code scanning results") can then block the merge
when a tool reports a new alert at or above a severity.

So the scanner's job never fails on a finding. It only runs the tool and uploads. The gate is the ruleset, and it
counts only alerts the pull request adds.

## Why here instead of failing the job

A job that fails on any finding blocks every pull request as soon as a scanner learns a new rule or an advisory
is published, even when the pull request touched nothing related. Code scanning only blocks what the pull request
itself brings in. Existing alerts stay visible on the Security tab, where they can be fixed or dismissed with a
reason, and they don't hold up unrelated work.

## In ermida

- `.github/workflows/security.yml` runs CodeQL (Ruby, JavaScript, workflows), zizmor and grype, and uploads each
  under its own category. It runs on every pull request, on each push to `main`, and daily. The `main` runs are
  the baseline that pull requests are compared with; the daily run picks up advisories and queries published
  since the last push.
- `scorecard.yml` and Brakeman's step in `ci.yml` upload the same way. Brakeman is the exception that still fails
  its job, because it was a gate before code scanning existed here.
- The ruleset on `main` sets the thresholds per tool (CodeQL from `high`, zizmor on any alert, grype on
  `critical`).

Renaming a workflow file, a job or a category starts a new analysis: the old one's alerts stay open on `main`
until they are closed by hand.

## When not to use it

- On a private repository without GitHub Code Security there is no code scanning: the upload fails, and a failing
  job is the only gate available.
- For checks whose findings are always the pull request's fault, such as lint or tests, failing the job is
  simpler and faster to read. actionlint and dependency review stay as ordinary failing checks for that reason.
