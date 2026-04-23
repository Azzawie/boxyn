# Boxyn API — User Scenarios

All API endpoints return JSON. Authenticated requests require the `Authorization: Bearer <token>` header. The JWT token is returned in the `Authorization` response header after sign-in or sign-up.

Base URL: `http://localhost:3000`

---

## Authentication

### Sign Up

Creates a new account. A "Personal" space is automatically created for the user.

**Request**
```
POST /auth/sign_up
Content-Type: application/json

{
  "user": {
    "email": "mustafa@example.com",
    "password": "securepassword",
    "password_confirmation": "securepassword"
  }
}
```

**Response** `201 Created`
```json
{
  "id": 1,
  "email": "mustafa@example.com",
  "provider": null,
  "created_at": "2026-04-22T10:00:00.000Z"
}
```
> The JWT token is in the `Authorization` response header: `Bearer <token>`

---

### Sign In

**Request**
```
POST /auth/sign_in
Content-Type: application/json

{
  "user": {
    "email": "mustafa@example.com",
    "password": "securepassword"
  }
}
```

**Response** `200 OK`
```json
{
  "id": 1,
  "email": "mustafa@example.com",
  "provider": null,
  "created_at": "2026-04-22T10:00:00.000Z"
}
```
> The JWT token is in the `Authorization` response header. Save it for all subsequent requests.

---

### Sign Out

Invalidates the current JWT token (added to the denylist).

**Request**
```
DELETE /auth/sign_out
Authorization: Bearer <token>
```

**Response** `204 No Content`

---

### Sign In with Google

Initiates the OAuth flow. The user is redirected to Google.

```
GET /auth/users/auth/google_oauth2
```

After Google redirects back, the callback creates or finds the user and returns a JWT.

**Callback response** `200 OK`
```json
{
  "id": 2,
  "email": "mustafa@gmail.com",
  "provider": "google_oauth2",
  "created_at": "2026-04-22T10:05:00.000Z"
}
```

---

### Sign In with Apple

Same flow as Google, using Apple's OAuth provider.

```
GET /auth/users/auth/apple
```

---

## Spaces

### List My Spaces

Returns all spaces the authenticated user is a member of.

**Request**
```
GET /api/v1/spaces
Authorization: Bearer <token>
```

**Response** `200 OK`
```json
[
  { "id": 1, "name": "Personal", "description": null, "created_at": "..." },
  { "id": 2, "name": "Garage",   "description": "Winter storage", "created_at": "..." }
]
```

---

### Get a Space (with Boxes)

**Request**
```
GET /api/v1/spaces/1
Authorization: Bearer <token>
```

**Response** `200 OK`
```json
{
  "id": 1,
  "name": "Personal",
  "description": null,
  "created_at": "...",
  "boxes": [
    { "id": 10, "name": "Books", "qr_token": "uuid-here", "qr_code_url": null, ... }
  ]
}
```

---

### Create a Space

**Request**
```
POST /api/v1/spaces
Authorization: Bearer <token>
Content-Type: application/json

{
  "space": {
    "name": "Garage",
    "description": "Winter sports gear and tools"
  }
}
```

**Response** `201 Created`
```json
{
  "id": 2,
  "name": "Garage",
  "description": "Winter sports gear and tools",
  "created_at": "..."
}
```

---

### Update a Space

Requires admin or owner role.

**Request**
```
PATCH /api/v1/spaces/2
Authorization: Bearer <token>
Content-Type: application/json

{
  "space": { "description": "Updated description" }
}
```

**Response** `200 OK`

---

### Delete a Space

Requires owner role.

**Request**
```
DELETE /api/v1/spaces/2
Authorization: Bearer <token>
```

**Response** `204 No Content`

---

## Space Memberships

### Invite a User to a Space

Requires admin or owner role. Finds the user by email and adds them as a member.

**Request**
```
POST /api/v1/spaces/2/memberships
Authorization: Bearer <token>
Content-Type: application/json

{
  "email": "friend@example.com",
  "role": "member"
}
```

> `role` can be `"member"`, `"admin"`, or `"owner"`. Defaults to `"member"`.

**Response** `201 Created`
```json
{ "message": "Invitation sent" }
```

---

### Remove a Member from a Space

Requires admin or owner role. Cannot remove the space owner.

**Request**
```
DELETE /api/v1/spaces/2/memberships/5
Authorization: Bearer <token>
```

**Response** `204 No Content`

---

## Boxes

### List Boxes in a Space

**Request**
```
GET /api/v1/spaces/1/boxes
Authorization: Bearer <token>
```

**Response** `200 OK`
```json
[
  {
    "id": 10,
    "name": "Books",
    "description": "Fiction and non-fiction",
    "qr_token": "550e8400-e29b-41d4-a716-446655440000",
    "qr_code_url": "http://localhost:3000/rails/active_storage/blobs/.../box-uuid.png",
    "created_at": "...",
    "updated_at": "..."
  }
]
```

---

### Create a Box

A QR token is auto-generated. A background job asynchronously generates and attaches the QR code image.

**Request**
```
POST /api/v1/spaces/1/boxes
Authorization: Bearer <token>
Content-Type: application/json

{
  "box": {
    "name": "Winter Clothes",
    "description": "Jackets, scarves, gloves"
  }
}
```

**Response** `201 Created`
```json
{
  "id": 11,
  "name": "Winter Clothes",
  "description": "Jackets, scarves, gloves",
  "qr_token": "550e8400-e29b-41d4-a716-446655440001",
  "qr_code_url": null,
  "created_at": "...",
  "updated_at": "..."
}
```

---

### Get a Box (with Items)

**Request**
```
GET /api/v1/boxes/11
Authorization: Bearer <token>
```

**Response** `200 OK`
```json
{
  "id": 11,
  "name": "Winter Clothes",
  "items": [
    { "id": 100, "name": "Blue Jacket", "description": "Size M", "tags": [] }
  ]
}
```

---

### Scan a Box by QR Token

Used when a user scans a QR code — looks up the box by its token and returns contents.

**Request**
```
GET /api/v1/boxes/scan/550e8400-e29b-41d4-a716-446655440001
Authorization: Bearer <token>
```

**Response** `200 OK` — same shape as Get a Box.

---

### Update a Box

**Request**
```
PATCH /api/v1/boxes/11
Authorization: Bearer <token>
Content-Type: application/json

{
  "box": { "name": "Winter Clothes 2024" }
}
```

**Response** `200 OK`

---

### Delete a Box

Deletes the box and all its items.

**Request**
```
DELETE /api/v1/boxes/11
Authorization: Bearer <token>
```

**Response** `204 No Content`

---

## Items

### Create an Item in a Box

**Request**
```
POST /api/v1/boxes/11/items
Authorization: Bearer <token>
Content-Type: application/json

{
  "item": {
    "name": "Blue Jacket",
    "description": "Size M, North Face"
  }
}
```

**Response** `201 Created`
```json
{
  "id": 100,
  "name": "Blue Jacket",
  "description": "Size M, North Face",
  "tags": [],
  "created_at": "...",
  "updated_at": "..."
}
```

---

### Create an Item with Photos

Send as `multipart/form-data` to attach one or more photos.

**Request**
```
POST /api/v1/boxes/11/items
Authorization: Bearer <token>
Content-Type: multipart/form-data

item[name]=Blue Jacket
item[description]=Size M
item[photos][]=@jacket_front.jpg
item[photos][]=@jacket_back.jpg
```

---

### Update an Item (and reassign tags)

Pass `tag_ids` to replace the item's tags entirely. Omit to leave tags unchanged.

**Request**
```
PATCH /api/v1/items/100
Authorization: Bearer <token>
Content-Type: application/json

{
  "item": {
    "name": "Blue Jacket (updated)",
    "tag_ids": [3, 7]
  }
}
```

**Response** `200 OK`
```json
{
  "id": 100,
  "name": "Blue Jacket (updated)",
  "description": "Size M, North Face",
  "tags": [
    { "id": 3, "name": "clothing" },
    { "id": 7, "name": "winter" }
  ],
  "created_at": "...",
  "updated_at": "..."
}
```

---

### Delete an Item

**Request**
```
DELETE /api/v1/items/100
Authorization: Bearer <token>
```

**Response** `204 No Content`

---

## Tags

### List Tags in a Space

**Request**
```
GET /api/v1/spaces/1/tags
Authorization: Bearer <token>
```

**Response** `200 OK`
```json
[
  { "id": 3, "name": "clothing" },
  { "id": 7, "name": "winter" }
]
```

---

### Create a Tag

Tag names are unique per space (case-insensitive).

**Request**
```
POST /api/v1/spaces/1/tags
Authorization: Bearer <token>
Content-Type: application/json

{
  "tag": { "name": "fragile" }
}
```

**Response** `201 Created`
```json
{ "id": 9, "name": "fragile" }
```

---

## Search

Full-text search across all items within a space using PostgreSQL `tsvector`. Results are ranked by relevance.

**Request**
```
GET /api/v1/search?q=jacket&space_id=1
Authorization: Bearer <token>
```

**Response** `200 OK`
```json
[
  {
    "id": 100,
    "name": "Blue Jacket",
    "description": "Size M, North Face",
    "box_id": 11,
    "box_name": "Winter Clothes",
    "tags": [{ "id": 7, "name": "winter" }],
    "created_at": "...",
    "updated_at": "..."
  }
]
```

> Returns `[]` if no results. Returns `403 Forbidden` if `space_id` belongs to a space the user is not a member of.

---

## Error Responses

| Status | Meaning |
|--------|---------|
| `401 Unauthorized` | Missing or invalid JWT token |
| `403 Forbidden` | Authenticated but not a member / insufficient role |
| `404 Not Found` | Resource does not exist |
| `422 Unprocessable Entity` | Validation error — see `errors` array in response body |

**Example validation error**
```json
{
  "error": "Name can't be blank"
}
```

**Example auth error (sign-up)**
```json
{
  "errors": ["Email has already been taken", "Password is too short (minimum is 8 characters)"]
}
```

---

## Roles Reference

| Role | Can read | Can write | Can manage members | Can delete space |
|------|----------|-----------|--------------------|-----------------|
| `member` | ✅ | ✅ | ❌ | ❌ |
| `admin` | ✅ | ✅ | ✅ | ❌ |
| `owner` | ✅ | ✅ | ✅ | ✅ |
