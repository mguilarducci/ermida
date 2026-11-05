# Concepts

> Shared domain vocabulary for this project — entities, named processes, and status concepts with project-specific meaning. Seeded with core domain vocabulary, then accretes as ce-compound captures and refreshes learnings; direct edits are fine. Glossary only, not a spec or catch-all.

## Business

A named establishment that people list, view, create, edit and delete in the app, addressed in its URLs by its slug rather than by an internal identifier.
*Avoid:* company, store

A Business's name is required and need not be unique, and it must contain Latin letters or digits. Its slug is derived from the name once, when the Business is created, and never changes afterwards, so links keep working after a rename. Two Businesses never share a slug: a name whose slug is already taken, or would collide with a page of the app itself, gets the next numbered suffix. Deleting a Business is permanent and frees its slug for the next Business that would produce it.
