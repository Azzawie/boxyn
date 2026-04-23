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
| Language | Ruby | 3.3.0 |
| Framework | Ruby on Rails (API mode) | 8.1.x |
| Database | PostgreSQL | 14+ |
| Authentication | Devise + devise-jwt | latest |
| OAuth | omniauth-google-oauth2, omniauth-apple | latest |
| Serialization | Blueprinter | latest |
| QR Code Generation | rqrcode | latest |
| File Uploads | Active Storage (built-in) | — |
| Background Jobs | Solid Queue (built-in) | — |
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
├── initializers/
│   ├── devise.rb      # JWT config, OAuth providers
│   └── cors.rb        # CORS with Authorization header exposure
├── routes.rb          # All routes under /auth/* and /api/v1/*
db/
└── migrate/           # 9 migrations covering all models + FTS trigger
docs/
├── history.md         # Full session history and architecture decisions
└── api-scenarios.md   # All API endpoints with example requests/responses
```

---

## Getting Started

### Prerequisites

- Ruby 3.3.0
- PostgreSQL 14+
- Bundler

### Setup

```bash
# 1. Install dependencies
bundle install

# 2. Set up environment variables
cp .env.example .env   # then fill in the values (see Environment Variables below)

# 3. Create and migrate the database
bin/rails db:create db:migrate

# 4. Start the server
bin/rails server
```

Visit `http://localhost:3000/up` — a `200 OK` means the app is running.

---

## Environment Variables

Create a `.env` file in the project root (never commit this file):

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

---

## Running Tests

```bash
bin/rails test
```

Tests cover models, all API controllers, and the QR code job.

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

QR code generation runs asynchronously via **Solid Queue**. When a box is created, `GenerateQrCodeJob` is enqueued automatically. It renders a 300×300 PNG using `rqrcode` and attaches it to the box via Active Storage.

To process jobs in development:

```bash
bin/jobs   # starts the Solid Queue worker
```

---

## Deployment

Boxyn uses [Kamal](https://kamal-deploy.org) for Docker-based deployment. See `.kamal/` for configuration.

```bash
kamal deploy
```
