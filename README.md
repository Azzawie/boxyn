# Boxyn

Boxyn is a JSON API for smart physical storage management. Users organize real-world items into **Boxes**, Boxes live inside **Spaces**, and every Box gets a scannable **QR code**. Scan a box to instantly see what's inside. Spaces support role-based membership so households, teams, or warehouses can share storage together.

---

## Features

- **Spaces** — top-level containers for organizing storage; every user gets a Personal space on signup
- **Role-based membership** — invite others as `member`, `admin`, or `owner`
- **Boxes** — physical boxes inside a space, each with a unique QR code
- **QR codes** — auto-generated PNG QR codes attached to each box via Active Storage
- **Items** — individual items stored inside a box, with optional photo attachments
- **Tags** — label items with space-scoped tags for easy categorization
- **Full-text search** — search items by name or description using PostgreSQL `tsvector`
- **JWT authentication** — stateless auth with token revocation via a denylist table
- **OAuth** — sign in with Google or Apple

---

## Tech Stack

| Layer | Technology | Version |
|---|---|---|
| Language | Ruby | 3.3.8 |
| Framework | Ruby on Rails (API mode) | 8.1.x |
| Database | PostgreSQL | 14+ |
| Authentication | Devise + devise-jwt | latest |
| OAuth | omniauth-google-oauth2, omniauth-apple | latest |
| Serialization | Blueprinter | latest |
| QR Code Generation | rqrcode | latest |
| File Uploads | Active Storage (built-in) | — |
| Background Jobs | Solid Queue (production) / Async (development) | — |
| Caching | Solid Cache (built-in) | — |
| Web Server | Puma | 5+ |
| CORS | rack-cors | latest |
| Deployment | Kamal + Docker | latest |

---

## Project Structure

```
app/
├── blueprints/        # Blueprinter serializers (named views per resource)
├── controllers/
│   ├── auth/          # Devise sessions, registrations, OAuth callbacks
│   ├── api/v1/        # All resource controllers
│   └── concerns/      # SpaceAuthorization role-check concern
├── jobs/              # GenerateQrCodeJob (async QR PNG generation)
├── models/            # All ActiveRecord models
config/
├── environments/
│   ├── development.rb # Uses :async queue adapter (no DB tables needed)
│   └── test.rb        # Uses :test queue adapter (jobs enqueued but not run)
├── initializers/
│   ├── devise.rb      # JWT config, OAuth providers
│   └── cors.rb        # CORS with Authorization header exposure
├── routes.rb          # All routes under /auth/* and /api/v1/*
db/
├── migrate/           # App migrations covering all models + FTS trigger
└── queue_schema.rb    # Solid Queue schema (used in production queue database)
docs/
├── history.md              # Full session history and architecture decisions
├── api-scenarios.md        # All API endpoints with example requests/responses
└── boxyn-postman-collection.json  # Ready-to-import Postman collection
```

---

## Getting Started

### Prerequisites

- Ruby 3.3.8 (install via RVM: `rvm install 3.3.8 && rvm use 3.3.8 --default`)
- PostgreSQL 14+
- Bundler

> **Note:** Ruby 3.3.0 has a known incompatibility with Rails 8.1.3. Use 3.3.8 or later.

### Setup

```bash
# 1. Install dependencies
bundle install

# 2. Copy and fill in environment variables
cp .env.example .env
# Then edit .env — see the Environment Variables section below

# 3. Generate a JWT secret and paste it into .env as DEVISE_JWT_SECRET_KEY
bin/rails secret

# 4. Create the database
#    If this fails with "database postgres does not exist", create manually:
#      createdb boxyn_development && createdb boxyn_test
bin/rails db:create

# 5. Install Active Storage migrations
#    Required for QR code image and photo attachments on boxes/items
bin/rails active_storage:install

# 6. Install Solid Queue migrations
#    Required for production background job processing.
#    Note: in development, the :async adapter is used instead (no DB tables needed).
bin/rails solid_queue:install

# 7. Run all migrations
bin/rails db:migrate

# 8. Start the server
bin/rails server
```

Visit `http://localhost:3000/up` — a `200 OK` means the app is running.

---

## Environment Variables

Create a `.env` file in the project root (this file is gitignored — never commit it):

```
DATABASE_URL=postgresql://localhost/boxyn_development
APP_BASE_URL=http://localhost:3000
DEVISE_JWT_SECRET_KEY=        # generate with: bin/rails secret
ALLOWED_ORIGINS=*             # comma-separated list for production

# Google OAuth
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

# Apple OAuth
APPLE_TEAM_ID=
APPLE_CLIENT_ID=
APPLE_KEY_ID=
APPLE_PRIVATE_KEY=            # full PEM string with \n escaped
```

---

## API Overview

All endpoints are under `/api/v1/`. Authentication uses a JWT token passed in the `Authorization: Bearer <token>` header. The token is returned in the `Authorization` response header after sign-in or sign-up.

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/auth/sign_up` | Register a new user |
| `POST` | `/auth/sign_in` | Sign in, receive JWT |
| `DELETE` | `/auth/sign_out` | Sign out, revoke JWT |
| `GET` | `/api/v1/spaces` | List user's spaces |
| `POST` | `/api/v1/spaces` | Create a space |
| `GET` | `/api/v1/spaces/:id` | Get space with boxes |
| `POST` | `/api/v1/spaces/:id/memberships` | Invite a user |
| `GET` | `/api/v1/spaces/:id/boxes` | List boxes in a space |
| `POST` | `/api/v1/spaces/:id/boxes` | Create a box |
| `GET` | `/api/v1/boxes/:id` | Get box with items |
| `GET` | `/api/v1/boxes/scan/:qr_token` | Look up box by QR code |
| `POST` | `/api/v1/boxes/:id/items` | Add an item to a box |
| `PATCH` | `/api/v1/items/:id` | Update an item |
| `GET` | `/api/v1/search?q=...&space_id=...` | Full-text search items |

See [`docs/api-scenarios.md`](docs/api-scenarios.md) for full request/response examples.
A ready-to-import Postman collection is available at [`docs/boxyn-postman-collection.json`](docs/boxyn-postman-collection.json).

---

## Running Tests

```bash
# Make sure the test database is up to date
bin/rails db:test:prepare

# Run the full RSpec suite
bundle exec rspec

# Run a single spec file
bundle exec rspec spec/requests/spaces_spec.rb
```

Tests cover all API controllers (auth, spaces, memberships, boxes, items, tags, search) and the QR code job.

---

## Security

```bash
# Static analysis
bundle exec brakeman --no-pager

# Dependency vulnerabilities
bundle exec bundler-audit check --update
```

---

## Background Jobs

QR code generation runs asynchronously via `GenerateQrCodeJob`. When a box is created, the job is enqueued automatically. It renders a 300×300 PNG using `rqrcode` and attaches it to the box via Active Storage.

| Environment | Queue adapter | Behaviour |
|---|---|---|
| `development` | `:async` | Jobs run in a background thread — no database tables needed |
| `test` | `:test` | Jobs are enqueued but not executed; assert with `have_enqueued_job` |
| `production` | `:solid_queue` | Persistent database-backed queue; requires dedicated queue database |

To process jobs in production (or if you switch to Solid Queue locally):

```bash
bin/jobs   # starts the Solid Queue worker
```

---

## Deployment

Boxyn uses [Kamal](https://kamal-deploy.org) for Docker-based deployment. See `.kamal/` for configuration.

```bash
kamal deploy
```
