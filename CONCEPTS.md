# Concepts

> Shared domain vocabulary for this project — entities, named processes, and status concepts with project-specific meaning. Seeded with core domain vocabulary, then accretes as ce-compound captures and refreshes learnings; direct edits are fine. Glossary only, not a spec or catch-all.

## Business

A named establishment that people list, view, create, edit and delete in the app, addressed in its URLs by its slug rather than by an internal identifier.
*Avoid:* company, store

A Business's name is required and need not be unique, and it must contain Latin letters or digits. Its slug is derived from the name once, when the Business is created, and never changes afterwards, so links keep working after a rename. Two Businesses never share a slug: a name whose slug is already taken, or would collide with a page of the app itself, gets the next numbered suffix. Deleting a Business is permanent and frees its slug for the next Business that would produce it.

## Account

A condominium: the space where residents, service providers and the people who run it act together. Each Account has a name and a slug derived from the name once, at creation, following the same rules as a Business slug.
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
