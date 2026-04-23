# Boxyn — Project History

## Session: 2026-04-22

### Overview

This session bootstrapped the entire Boxyn Rails 8.1 JSON API from a blank Rails scaffold. The implementation was driven by a spec file (`docs/2026-04-22-boxyn-implementation.md`) that laid out 14 sequential tasks. All 14 were completed in a single session.

---

### What Was Built

**Boxyn** is a smart storage management API. The core idea: users organize physical items into Boxes, Boxes live inside Spaces, and every Box gets a QR code so you can scan it to see its contents instantly.

#### Data Model

```
User
 └── SpaceMembership (role: owner | admin | member)
      └── Space
           ├── Box (qr_token, qr_code_image via Active Storage)
           │    └── Item (photos via Active Storage, full-text search via tsvector)
           │         └── Tagging
           │              └── Tag (scoped to Space)
           └── Tag
```

- A **Personal** space is auto-created for every new user on signup.
- Every **Box** gets a UUID `qr_token` on creation; a background job (`GenerateQrCodeJob`) asynchronously generates a PNG QR code and attaches it via Active Storage.
- **Items** support PostgreSQL full-text search via a `tsvector` column and a `BEFORE INSERT OR UPDATE` trigger.

---

### Tasks Completed

| # | Task | Notes |
|---|------|-------|
| 1 | Gemfile | Added `devise`, `devise-jwt`, `omniauth-google-oauth2`, `omniauth-apple`, `omniauth-rails_csrf_protection`, `blueprinter`, `rqrcode`, `rack-cors`, `dotenv-rails`, `rspec-rails`, `factory_bot_rails`, `faker`, `annotate`, `bcrypt`. Created `.env` with placeholder values. |
| 2 | Migrations | 9 migration files: `jwt_denylist`, `users` (Devise), `spaces`, `space_memberships`, `boxes`, `items`, `tags`, `taggings`, `add_full_text_search_to_items` (tsvector + GIN index + PL/pgSQL trigger). |
| 3 | Models | `JwtDenylist`, `User`, `Space`, `SpaceMembership`, `Box`, `Item`, `Tag`, `Tagging`. Model tests written for all four core models. |
| 4 | Devise + JWT + OAuth + CORS | `config/initializers/devise.rb` (JWT dispatch/revocation, Google + Apple OAuth), `config/initializers/cors.rb` (exposes `Authorization` header), `ApplicationController` updated with permitted parameters. |
| 5 | Auth Controllers | `Auth::SessionsController`, `Auth::RegistrationsController`, `Auth::OmniauthCallbacksController` — all render JSON via `UserBlueprint`. |
| 6 | Blueprinter Serializers | `UserBlueprint`, `TagBlueprint`, `ItemBlueprint` (views: default / `with_tags` / `with_box` / `full`), `BoxBlueprint` (views: default / `with_items`), `SpaceBlueprint` (views: default / `with_boxes`). |
| 7 | Routes | Full `config/routes.rb`: Devise auth at `/auth/*`, all resource routes under `/api/v1/`, including `GET /api/v1/boxes/scan/:qr_token`. |
| 8 | Base Controller + SpaceAuthorization | `Api::V1::BaseController` (authenticate + helpers), `SpaceAuthorization` concern (`require_membership!`, `require_admin!`, `require_owner!`). |
| 9 | Spaces + SpaceMemberships Controllers | Full CRUD for spaces with role enforcement. Membership invite/remove. Controller tests written. JWT test helper added to `test/test_helper.rb`. |
| 10 | Boxes Controller | CRUD + `scan` action (lookup by `qr_token`). Controller tests written. |
| 11 | Items + Tags Controllers | Items: create (with photo upload), update (with tag reassignment via `tag_ids`), destroy. Tags: index + create scoped to space. Controller tests written. |
| 12 | GenerateQrCodeJob | Async Solid Queue job — builds QR URL, renders PNG via `rqrcode`, attaches to `box.qr_code_image`. Job test written. |
| 13 | Search Controller | `GET /api/v1/search?q=...&space_id=...` — uses `Item.search` scope (`tsvector @@ plainto_tsquery`), ranked by `ts_rank`, scoped to space membership. Controller tests written. |
| 14 | Final Wiring | `config.active_job.queue_adapter = :solid_queue` confirmed in `application.rb`. |

---

### Files Created / Modified

```
Gemfile                                                  modified
.env                                                     created
config/application.rb                                    modified  (queue adapter)
config/routes.rb                                         modified
config/initializers/cors.rb                              modified
config/initializers/devise.rb                            created

db/migrate/20260422000001_create_jwt_denylist.rb
db/migrate/20260422000002_devise_create_users.rb
db/migrate/20260422000003_create_spaces.rb
db/migrate/20260422000004_create_space_memberships.rb
db/migrate/20260422000005_create_boxes.rb
db/migrate/20260422000006_create_items.rb
db/migrate/20260422000007_create_tags.rb
db/migrate/20260422000008_create_taggings.rb
db/migrate/20260422000009_add_full_text_search_to_items.rb

app/models/jwt_denylist.rb
app/models/user.rb
app/models/space.rb
app/models/space_membership.rb
app/models/box.rb
app/models/item.rb
app/models/tag.rb
app/models/tagging.rb

app/controllers/application_controller.rb               modified
app/controllers/auth/sessions_controller.rb
app/controllers/auth/registrations_controller.rb
app/controllers/auth/omniauth_callbacks_controller.rb
app/controllers/concerns/space_authorization.rb
app/controllers/api/v1/base_controller.rb
app/controllers/api/v1/spaces_controller.rb
app/controllers/api/v1/space_memberships_controller.rb
app/controllers/api/v1/boxes_controller.rb
app/controllers/api/v1/items_controller.rb
app/controllers/api/v1/tags_controller.rb
app/controllers/api/v1/search_controller.rb

app/blueprints/user_blueprint.rb
app/blueprints/space_blueprint.rb
app/blueprints/box_blueprint.rb
app/blueprints/item_blueprint.rb
app/blueprints/tag_blueprint.rb

app/jobs/generate_qr_code_job.rb

test/test_helper.rb                                      modified  (JWT helper)
test/models/user_test.rb
test/models/space_test.rb
test/models/box_test.rb
test/models/item_test.rb
test/controllers/api/v1/spaces_controller_test.rb
test/controllers/api/v1/boxes_controller_test.rb
test/controllers/api/v1/items_controller_test.rb
test/controllers/api/v1/search_controller_test.rb
test/jobs/generate_qr_code_job_test.rb

docs/api-scenarios.md                                    created
docs/history.md                                          created (this file)
```

---

### Pending — To Run Locally

The sandbox environment runs Ruby 3.0 and has no network access, so the following commands were not executed and need to be run on your local machine:

```bash
# 1. Install gems
bundle install

# 2. Generate a JWT secret and paste into .env
bin/rails secret   # → paste output as DEVISE_JWT_SECRET_KEY in .env

# 3. Create DB and run all migrations
bin/rails db:create db:migrate

# 4. Run the test suite
bin/rails test

# 5. Boot the server
bin/rails server
# → visit http://localhost:3000/up to confirm it's running

# 6. Security checks
bundle exec brakeman --no-pager
bundle exec bundler-audit check --update

# 7. Push to GitHub
git remote add origin git@github.com:Azzawie/boxyn.git
git add .
git commit -m "feat: initial Boxyn API implementation"
git push -u origin main
```

---

### Key Design Decisions

- **Space-centric model** — every box and tag is scoped to a space, making multi-user sharing straightforward via role-based membership.
- **JWT via devise-jwt** — stateless auth; token revocation handled through a `jwt_denylist` table. Token is dispatched on `POST /auth/sign_in` and revoked on `DELETE /auth/sign_out` via the `Authorization` response/request header.
- **Async QR generation** — QR code PNG rendering is intentionally offloaded to Solid Queue so box creation is fast and the image URL is populated once the job runs.
- **PostgreSQL FTS** — full-text search is done entirely in the database using `tsvector` + `plainto_tsquery` + a `ts_rank` sort, with no external search dependency.
- **Blueprinter views** — serializers use named views (`with_tags`, `with_items`, `with_box`, `full`) rather than always eager-loading everything, keeping response payloads lean.
