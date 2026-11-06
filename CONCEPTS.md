# Concepts

> Shared domain vocabulary for this project — entities, named processes, and status concepts with project-specific meaning. Seeded with core domain vocabulary, then accretes as ce-compound captures and refreshes learnings; direct edits are fine. Glossary only, not a spec or catch-all.

## Business

A named establishment that people list, view, create, edit and delete in the app, addressed in its URLs by its slug rather than by an internal identifier.
*Avoid:* company, store

A Business's name is required and need not be unique, and it must contain Latin letters or digits. Its slug is derived from the name once, when the Business is created, and never changes afterwards, so links keep working after a rename. Two Businesses never share a slug: a name whose slug is already taken, or would collide with a page of the app itself, gets the next numbered suffix. Deleting a Business is permanent and frees its slug for the next Business that would produce it.

## Account

A condominium: the space where residents, service providers and the people who run it act together. Each Account has a name and a slug derived from the name once, at creation, following the same rules as a Business slug. The Account's pages live under `/accounts/` followed by its slug, and only the Account's active Users get in.
*Avoid:* tenant, building

## Identity

A person, known by one email address across the whole app, whatever condominiums they belong to. The person's name lives here, and so do their sessions: signing in is something an Identity does, not a User.
*Avoid:* login, profile

## User

An Identity's place in one Account, carrying the role the person has there and whether that place is still active. A person has at most one User per Account. A User may have no Identity: the system user of an Account is not a person, and a User whose person leaves the Account loses its Identity, so a person who comes back gets a new User.
*Avoid:* member (that is one role), account user

## Role

What a User is in its Account: a resident (`member`), a service provider (`provider`), someone who administers the condominium (`admin`), its owner (`owner`), or the condominium's own automated actor (`system`).
*Avoid:* permission, type

## Sign-up

How an Account comes into Ermida: a person, usually the condominium's síndico, proves their email with a sign-in code, then names the Account and becomes its `owner`. Anyone with a verified email can sign up, and one person may sign up several Accounts. Residents and service providers do not sign up; they join an existing Account.
*Avoid:* registration, cadastro de condomínio

## Join link

How residents and service providers join an existing Account: one link per Account, carrying a secret code, that its owner and admins share. Whoever opens it proves their email with a sign-in code, gives their name if Ermida does not have it, confirms, and becomes a `member` of the Account. Opening the link alone creates nothing.
*Avoid:* invitation, invite link, join code

## Sign-in code

The 6-character code emailed to a person to prove the email is theirs, used to sign in, to sign up and to join an Account. It works once, for 15 minutes, and only in the browser that asked for it. The email carries only the code, never a link to click.
*Avoid:* magic link, OTP, password
