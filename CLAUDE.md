# Boxyn — Claude Instructions

## Required Reading

Before reviewing, modifying, or reasoning about any part of this codebase, always read the project history file first:

```
docs/history.md
```

This file contains:
- What Boxyn is and its purpose
- The full data model and architecture
- Every file that was created or modified and why
- Key design decisions (JWT strategy, QR generation, FTS approach, Blueprinter views)
- Pending setup steps still needed locally

Do not make assumptions about the app's structure or intent without reading it first.

## Project Summary

Boxyn is a Rails 8.1 JSON API for smart physical storage management. Users organize items into Boxes, Boxes live inside Spaces, and every Box gets a scannable QR code. Spaces support role-based membership (owner / admin / member). Items are full-text searchable via PostgreSQL tsvector.

## Key Conventions

- All API endpoints live under `/api/v1/`
- Auth is handled by Devise + devise-jwt; tokens travel in the `Authorization` header
- Serialization uses Blueprinter with named views — check `app/blueprints/` before adding fields to a response
- Background jobs use Solid Queue — see `app/jobs/`
- Authorization logic lives in `app/controllers/concerns/space_authorization.rb`
- Every controller under `api/v1/` inherits from `Api::V1::BaseController`
