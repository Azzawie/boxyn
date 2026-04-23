# Boxyn Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Rails 8.1 JSON API for Boxyn — a smart storage management app with spaces, boxes, items, photo uploads, QR codes, and full-text search.

**Architecture:** Space-centric model where every box lives inside a Space. Users auto-get a "Personal" Space on signup. Shared spaces use role-based membership (owner/admin/member). JWT auth via Devise + devise-jwt. PostgreSQL full-text search via `tsvector`. QR code images generated async via Solid Queue.

**Tech Stack:** Rails 8.1 API, PostgreSQL, Devise + devise-jwt, omniauth-google-oauth2, omniauth-apple, Blueprinter, rqrcode, Active Storage, Solid Queue, rack-cors, dotenv-rails

---

## File Map

```
Gemfile                                           — update gems
config/initializers/cors.rb                       — enable CORS
config/initializers/devise.rb                     — Devise + JWT + OAuth config
config/routes.rb                                  — all routes
config/application.rb                             — queue adapter (already set via solid_queue)

db/migrate/TIMESTAMP_create_jwt_denylist.rb
db/migrate/TIMESTAMP_devise_create_users.rb
db/migrate/TIMESTAMP_create_spaces.rb
db/migrate/TIMESTAMP_create_space_memberships.rb
db/migrate/TIMESTAMP_create_boxes.rb
db/migrate/TIMESTAMP_create_items.rb
db/migrate/TIMESTAMP_create_tags.rb
db/migrate/TIMESTAMP_create_taggings.rb
db/migrate/TIMESTAMP_add_fts_to_items.rb

app/models/jwt_denylist.rb
app/models/user.rb
app/models/space.rb
app/models/space_membership.rb
app/models/box.rb
app/models/item.rb
app/models/tag.rb
app/models/tagging.rb
app/models/concerns/space_authorization.rb        — role check concern

app/controllers/application_controller.rb
app/controllers/auth/sessions_controller.rb
app/controllers/auth/registrations_controller.rb
app/controllers/auth/omniauth_callbacks_controller.rb
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

test/test_helper.rb                               — add factory_bot helpers
test/factories/users.rb
test/factories/spaces.rb
test/factories/space_memberships.rb
test/factories/boxes.rb
test/factories/items.rb
test/factories/tags.rb
test/models/user_test.rb
test/models/space_test.rb
test/models/box_test.rb
test/models/item_test.rb
test/controllers/api/v1/spaces_controller_test.rb
test/controllers/api/v1/boxes_controller_test.rb
test/controllers/api/v1/items_controller_test.rb
test/controllers/api/v1/search_controller_test.rb
test/jobs/generate_qr_code_job_test.rb
```

---

## Task 1: Gemfile — Update Dependencies

**Files:**
- Modify: `Gemfile`

- [ ] **Step 1: Apply all gem changes**

Replace the relevant sections of `Gemfile` so it reads:

```ruby
source "https://rubygems.org"

gem "rails", "~> 8.1.0"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false
gem "image_processing", "~> 1.2"
gem "rack-cors"
gem "rqrcode"
gem "blueprinter"
gem "bcrypt", "~> 3.1.7"

# Auth
gem "devise"
gem "devise-jwt"
gem "omniauth-google-oauth2"
gem "omniauth-apple"
gem "omniauth-rails_csrf_protection"

# Environment variables
gem "dotenv-rails", groups: [:development, :test]

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
end

group :development do
  gem "annotate"
end
```

- [ ] **Step 2: Install gems**

```bash
bundle install
```

Expected: all gems install without errors.

- [ ] **Step 3: Create `.env` file**

Create `.env` in the project root (this file is gitignored):

```
DATABASE_URL=postgresql://localhost/boxyn_development
APP_BASE_URL=http://localhost:3000
DEVISE_JWT_SECRET_KEY=run_rails_secret_and_paste_here
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
APPLE_TEAM_ID=your_apple_team_id
APPLE_CLIENT_ID=your_apple_client_id
APPLE_KEY_ID=your_apple_key_id
APPLE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

Run `bin/rails secret` to generate a value for `DEVISE_JWT_SECRET_KEY`.

- [ ] **Step 4: Add `.env` to `.gitignore`**

```bash
echo ".env" >> .gitignore
```

- [ ] **Step 5: Commit**

```bash
git add Gemfile Gemfile.lock .gitignore
git commit -m "feat: update Gemfile with auth, oauth, and test gems"
```

---

## Task 2: Database Migrations — All Models

**Files:**
- Create: 9 migration files (commands below generate them)

- [ ] **Step 1: Generate JwtDenylist migration**

```bash
bin/rails generate migration CreateJwtDenylist jti:string:uniq exp:datetime
```

- [ ] **Step 2: Generate Devise User migration**

```bash
bin/rails generate devise User provider:string uid:string
```

Open the generated migration and ensure it includes the standard Devise columns plus `provider` and `uid`. It should look like:

```ruby
class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.string :provider
      t.string :uid
      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, [:provider, :uid],     unique: true
  end
end
```

- [ ] **Step 3: Generate Spaces migration**

```bash
bin/rails generate migration CreateSpaces name:string description:text
```

Edit the generated file to add `null: false` on `name`:

```ruby
class CreateSpaces < ActiveRecord::Migration[8.1]
  def change
    create_table :spaces do |t|
      t.string :name, null: false
      t.text :description
      t.timestamps
    end
  end
end
```

- [ ] **Step 4: Generate SpaceMemberships migration**

```bash
bin/rails generate migration CreateSpaceMemberships user:references space:references role:integer
```

Edit to add index and default role:

```ruby
class CreateSpaceMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :space_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :space, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.timestamps
    end

    add_index :space_memberships, [:user_id, :space_id], unique: true
  end
end
```

- [ ] **Step 5: Generate Boxes migration**

```bash
bin/rails generate migration CreateBoxes space:references name:string description:text qr_token:string
```

Edit:

```ruby
class CreateBoxes < ActiveRecord::Migration[8.1]
  def change
    create_table :boxes do |t|
      t.references :space, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :qr_token, null: false
      t.timestamps
    end

    add_index :boxes, :qr_token, unique: true
  end
end
```

- [ ] **Step 6: Generate Items migration**

```bash
bin/rails generate migration CreateItems box:references name:string description:text
```

Edit:

```ruby
class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.references :box, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.timestamps
    end
  end
end
```

- [ ] **Step 7: Generate Tags migration**

```bash
bin/rails generate migration CreateTags name:string space:references
```

Edit:

```ruby
class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.references :space, null: false, foreign_key: true
      t.timestamps
    end

    add_index :tags, [:name, :space_id], unique: true
  end
end
```

- [ ] **Step 8: Generate Taggings migration**

```bash
bin/rails generate migration CreateTaggings item:references tag:references
```

Edit:

```ruby
class CreateTaggings < ActiveRecord::Migration[8.1]
  def change
    create_table :taggings do |t|
      t.references :item, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.timestamps
    end

    add_index :taggings, [:item_id, :tag_id], unique: true
  end
end
```

- [ ] **Step 9: Generate FTS migration**

```bash
bin/rails generate migration AddFullTextSearchToItems
```

Edit the generated file:

```ruby
class AddFullTextSearchToItems < ActiveRecord::Migration[8.1]
  def up
    add_column :items, :search_vector, :tsvector

    execute <<-SQL
      CREATE OR REPLACE FUNCTION items_search_vector_update() RETURNS trigger AS $$
      BEGIN
        NEW.search_vector :=
          to_tsvector('english',
            COALESCE(NEW.name, '') || ' ' || COALESCE(NEW.description, '')
          );
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER items_search_vector_trigger
      BEFORE INSERT OR UPDATE ON items
      FOR EACH ROW EXECUTE FUNCTION items_search_vector_update();
    SQL

    add_index :items, :search_vector, using: :gin
  end

  def down
    execute <<-SQL
      DROP TRIGGER IF EXISTS items_search_vector_trigger ON items;
      DROP FUNCTION IF EXISTS items_search_vector_update();
    SQL

    remove_column :items, :search_vector
  end
end
```

- [ ] **Step 10: Run all migrations**

```bash
bin/rails db:create db:migrate
```

Expected: Database created, all migrations run without errors. `bin/rails db:schema:dump` shows all tables.

- [ ] **Step 11: Commit**

```bash
git add db/
git commit -m "feat: add all database migrations"
```

---

## Task 3: Models

**Files:**
- Create: `app/models/jwt_denylist.rb`
- Modify: `app/models/user.rb`
- Create: `app/models/space.rb`
- Create: `app/models/space_membership.rb`
- Create: `app/models/box.rb`
- Create: `app/models/item.rb`
- Create: `app/models/tag.rb`
- Create: `app/models/tagging.rb`

- [ ] **Step 1: Write model tests**

Create `test/models/user_test.rb`:

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "creates personal space on signup" do
    user = User.create!(email: "test@example.com", password: "password123")
    assert_equal 1, user.spaces.count
    assert_equal "Personal", user.spaces.first.name
    assert user.space_memberships.first.owner?
  end

  test "is invalid without email" do
    user = User.new(password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end
end
```

Create `test/models/space_test.rb`:

```ruby
require "test_helper"

class SpaceTest < ActiveSupport::TestCase
  test "is invalid without name" do
    space = Space.new
    assert_not space.valid?
    assert_includes space.errors[:name], "can't be blank"
  end
end
```

Create `test/models/box_test.rb`:

```ruby
require "test_helper"

class BoxTest < ActiveSupport::TestCase
  test "generates qr_token before create" do
    user = users(:one)
    space = user.spaces.first
    box = Box.create!(space: space, name: "Test Box")
    assert_not_nil box.qr_token
    assert_match(/\A[0-9a-f-]{36}\z/, box.qr_token)
  end
end
```

Create `test/models/item_test.rb`:

```ruby
require "test_helper"

class ItemTest < ActiveSupport::TestCase
  test "is invalid without name" do
    box = boxes(:one)
    item = Item.new(box: box)
    assert_not item.valid?
    assert_includes item.errors[:name], "can't be blank"
  end
end
```

- [ ] **Step 2: Run tests to see them fail**

```bash
bin/rails test test/models/
```

Expected: Failures about missing models/fixtures.

- [ ] **Step 3: Create JwtDenylist model**

Create `app/models/jwt_denylist.rb`:

```ruby
class JwtDenylist < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist

  self.table_name = "jwt_denylist"
end
```

- [ ] **Step 4: Create User model**

Replace `app/models/user.rb`:

```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :validatable,
         :omniauthable, omniauth_providers: %i[google_oauth2 apple],
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  has_many :space_memberships, dependent: :destroy
  has_many :spaces, through: :space_memberships

  after_create :create_personal_space

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
    end
  end

  private

  def create_personal_space
    space = Space.create!(name: "Personal")
    SpaceMembership.create!(user: self, space: space, role: :owner)
  end
end
```

- [ ] **Step 5: Create Space model**

Create `app/models/space.rb`:

```ruby
class Space < ApplicationRecord
  has_many :space_memberships, dependent: :destroy
  has_many :members, through: :space_memberships, source: :user
  has_many :boxes, dependent: :destroy
  has_many :tags, dependent: :destroy

  validates :name, presence: true
end
```

- [ ] **Step 6: Create SpaceMembership model**

Create `app/models/space_membership.rb`:

```ruby
class SpaceMembership < ApplicationRecord
  belongs_to :user
  belongs_to :space

  enum :role, { member: 0, admin: 1, owner: 2 }

  validates :user_id, uniqueness: { scope: :space_id }
end
```

- [ ] **Step 7: Create Box model**

Create `app/models/box.rb`:

```ruby
class Box < ApplicationRecord
  belongs_to :space
  has_many :items, dependent: :destroy
  has_one_attached :qr_code_image

  validates :name, presence: true

  before_create :generate_qr_token

  after_create_commit :enqueue_qr_generation

  private

  def generate_qr_token
    self.qr_token = SecureRandom.uuid
  end

  def enqueue_qr_generation
    GenerateQrCodeJob.perform_later(id)
  end
end
```

- [ ] **Step 8: Create Item model**

Create `app/models/item.rb`:

```ruby
class Item < ApplicationRecord
  belongs_to :box
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings
  has_many_attached :photos

  validates :name, presence: true

  scope :search, ->(query) {
    where("search_vector @@ plainto_tsquery('english', ?)", query)
      .order(Arel.sql("ts_rank(search_vector, plainto_tsquery('english', #{connection.quote(query)})) DESC"))
  }
end
```

- [ ] **Step 9: Create Tag model**

Create `app/models/tag.rb`:

```ruby
class Tag < ApplicationRecord
  belongs_to :space
  has_many :taggings, dependent: :destroy
  has_many :items, through: :taggings

  validates :name, presence: true
  validates :name, uniqueness: { scope: :space_id, case_sensitive: false }
end
```

- [ ] **Step 10: Create Tagging model**

Create `app/models/tagging.rb`:

```ruby
class Tagging < ApplicationRecord
  belongs_to :item
  belongs_to :tag

  validates :item_id, uniqueness: { scope: :tag_id }
end
```

- [ ] **Step 11: Run model tests**

```bash
bin/rails test test/models/
```

Expected: All 4 tests pass. (Fixtures for `users(:one)` and `boxes(:one)` may need to be created — if errors appear about missing fixtures, add minimal ones to `test/fixtures/users.yml` and `test/fixtures/boxes.yml` and run again.)

- [ ] **Step 12: Commit**

```bash
git add app/models/ test/models/
git commit -m "feat: add all models with validations and associations"
```

---

## Task 4: Devise + JWT + OAuth Configuration

**Files:**
- Create: `config/initializers/devise.rb`
- Modify: `config/initializers/cors.rb`
- Modify: `app/controllers/application_controller.rb`

- [ ] **Step 1: Generate Devise initializer**

```bash
bin/rails generate devise:install
```

This creates `config/initializers/devise.rb`. Replace its full content with:

```ruby
Devise.setup do |config|
  config.mailer_sender = "noreply@boxyn.com"
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth, :token_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.reconfirmable = false
  config.expire_all_remember_me_on_sign_out = true
  config.password_length = 8..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours
  config.sign_out_via = :delete
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other

  config.jwt do |jwt|
    jwt.secret = ENV.fetch("DEVISE_JWT_SECRET_KEY", Rails.application.secret_key_base)
    jwt.dispatch_requests = [
      ["POST", %r{^/auth/sign_in$}]
    ]
    jwt.revocation_requests = [
      ["DELETE", %r{^/auth/sign_out$}]
    ]
    jwt.expiration_time = 1.day.to_i
  end

  config.omniauth :google_oauth2,
    ENV.fetch("GOOGLE_CLIENT_ID", ""),
    ENV.fetch("GOOGLE_CLIENT_SECRET", ""),
    scope: "email,profile"

  config.omniauth :apple,
    ENV.fetch("APPLE_TEAM_ID", ""),
    ENV.fetch("APPLE_CLIENT_ID", ""),
    key_id: ENV.fetch("APPLE_KEY_ID", ""),
    pem: ENV.fetch("APPLE_PRIVATE_KEY", "").gsub("\\n", "\n")
end
```

- [ ] **Step 2: Enable CORS**

Replace `config/initializers/cors.rb`:

```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("ALLOWED_ORIGINS", "*").split(",")

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ["Authorization"]
  end
end
```

Note: `expose: ["Authorization"]` is required for devise-jwt — the client reads the JWT from this header on sign-in.

- [ ] **Step 3: Update ApplicationController**

Replace `app/controllers/application_controller.rb`:

```ruby
class ApplicationController < ActionController::API
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email, :password, :password_confirmation])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password])
  end
end
```

- [ ] **Step 4: Commit**

```bash
git add config/initializers/ app/controllers/application_controller.rb
git commit -m "feat: configure Devise, JWT, OAuth, and CORS"
```

---

## Task 5: Auth Controllers

**Files:**
- Create: `app/controllers/auth/sessions_controller.rb`
- Create: `app/controllers/auth/registrations_controller.rb`
- Create: `app/controllers/auth/omniauth_callbacks_controller.rb`

- [ ] **Step 1: Create Sessions controller**

Create `app/controllers/auth/sessions_controller.rb`:

```ruby
class Auth::SessionsController < Devise::SessionsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    render json: UserBlueprint.render(resource), status: :ok
  end

  def respond_to_on_destroy
    head :no_content
  end
end
```

- [ ] **Step 2: Create Registrations controller**

Create `app/controllers/auth/registrations_controller.rb`:

```ruby
class Auth::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: UserBlueprint.render(resource), status: :created
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
```

- [ ] **Step 3: Create OmniAuth Callbacks controller**

Create `app/controllers/auth/omniauth_callbacks_controller.rb`:

```ruby
class Auth::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    handle_auth
  end

  def apple
    handle_auth
  end

  private

  def handle_auth
    @user = User.from_omniauth(request.env["omniauth.auth"])
    if @user.persisted?
      sign_in @user
      render json: UserBlueprint.render(@user), status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
```

- [ ] **Step 4: Commit**

```bash
git add app/controllers/auth/
git commit -m "feat: add Devise auth controllers (sessions, registrations, oauth)"
```

---

## Task 6: Blueprinter Serializers

**Files:**
- Create: `app/blueprints/user_blueprint.rb`
- Create: `app/blueprints/space_blueprint.rb`
- Create: `app/blueprints/box_blueprint.rb`
- Create: `app/blueprints/item_blueprint.rb`
- Create: `app/blueprints/tag_blueprint.rb`

- [ ] **Step 1: Create UserBlueprint**

Create `app/blueprints/user_blueprint.rb`:

```ruby
class UserBlueprint < Blueprinter::Base
  identifier :id

  fields :email, :provider, :created_at
end
```

- [ ] **Step 2: Create TagBlueprint**

Create `app/blueprints/tag_blueprint.rb`:

```ruby
class TagBlueprint < Blueprinter::Base
  identifier :id

  fields :name
end
```

- [ ] **Step 3: Create ItemBlueprint**

Create `app/blueprints/item_blueprint.rb`:

```ruby
class ItemBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :description, :created_at, :updated_at

  view :with_tags do
    association :tags, blueprint: TagBlueprint
  end

  view :with_box do
    association :tags, blueprint: TagBlueprint
    field :box_name do |item|
      item.box.name
    end
    field :box_id do |item|
      item.box.id
    end
  end

  view :full do
    association :tags, blueprint: TagBlueprint
    field :photo_urls do |item, options|
      item.photos.map { |photo| options[:url_helpers].rails_blob_url(photo) }
    end
  end
end
```

- [ ] **Step 4: Create BoxBlueprint**

Create `app/blueprints/box_blueprint.rb`:

```ruby
class BoxBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :description, :qr_token, :created_at, :updated_at

  field :qr_code_url do |box, options|
    box.qr_code_image.attached? ? options[:url_helpers].rails_blob_url(box.qr_code_image) : nil
  end

  view :with_items do
    association :items, blueprint: ItemBlueprint, view: :with_tags
  end
end
```

- [ ] **Step 5: Create SpaceBlueprint**

Create `app/blueprints/space_blueprint.rb`:

```ruby
class SpaceBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :description, :created_at

  view :with_boxes do
    association :boxes, blueprint: BoxBlueprint
  end
end
```

- [ ] **Step 6: Commit**

```bash
git add app/blueprints/
git commit -m "feat: add Blueprinter serializers for all models"
```

---

## Task 7: Routes

**Files:**
- Modify: `config/routes.rb`

- [ ] **Step 1: Replace routes.rb**

```ruby
Rails.application.routes.draw do
  devise_for :users,
    path: "auth",
    path_names: {
      sign_in: "sign_in",
      sign_out: "sign_out",
      registration: "sign_up"
    },
    controllers: {
      sessions: "auth/sessions",
      registrations: "auth/registrations",
      omniauth_callbacks: "auth/omniauth_callbacks"
    }

  namespace :api do
    namespace :v1 do
      resources :spaces do
        resources :memberships, only: [:create, :destroy],
          controller: "space_memberships"
        resources :boxes, only: [:index, :create]
        resources :tags, only: [:index, :create]
      end

      resources :boxes, only: [:show, :update, :destroy] do
        resources :items, only: [:create]
        collection do
          # Must be declared before :id routes to prevent conflict
          get "scan/:qr_token", to: "boxes#scan", as: :scan
        end
      end

      resources :items, only: [:update, :destroy]

      get "search", to: "search#index"
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
```

- [ ] **Step 2: Verify routes load**

```bash
bin/rails routes | grep api
```

Expected: Shows all `/api/v1/` routes including `scan`.

- [ ] **Step 3: Commit**

```bash
git add config/routes.rb
git commit -m "feat: define all API routes"
```

---

## Task 8: API Base Controller + Space Authorization Concern

**Files:**
- Create: `app/controllers/api/v1/base_controller.rb`
- Create: `app/controllers/concerns/space_authorization.rb`

- [ ] **Step 1: Create SpaceAuthorization concern**

Create `app/controllers/concerns/space_authorization.rb`:

```ruby
module SpaceAuthorization
  extend ActiveSupport::Concern

  def find_space
    @space = Space.find(params[:space_id] || params[:id])
  end

  def current_membership
    @current_membership ||= @space.space_memberships.find_by(user: current_user)
  end

  def require_membership!
    find_space
    render json: { error: "Forbidden" }, status: :forbidden unless current_membership
  end

  def require_admin!
    find_space
    unless current_membership&.admin? || current_membership&.owner?
      render json: { error: "Forbidden" }, status: :forbidden
    end
  end

  def require_owner!
    find_space
    render json: { error: "Forbidden" }, status: :forbidden unless current_membership&.owner?
  end
end
```

- [ ] **Step 2: Create API Base controller**

Create `app/controllers/api/v1/base_controller.rb`:

```ruby
class Api::V1::BaseController < ApplicationController
  before_action :authenticate_user!
  include SpaceAuthorization

  private

  def url_helpers
    Rails.application.routes.url_helpers
  end

  def render_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end
end
```

- [ ] **Step 3: Commit**

```bash
git add app/controllers/api/ app/controllers/concerns/space_authorization.rb
git commit -m "feat: add API base controller and space authorization concern"
```

---

## Task 9: Spaces Controller

**Files:**
- Create: `app/controllers/api/v1/spaces_controller.rb`
- Create: `app/controllers/api/v1/space_memberships_controller.rb`
- Create: `test/controllers/api/v1/spaces_controller_test.rb`

- [ ] **Step 1: Write failing tests**

Create `test/controllers/api/v1/spaces_controller_test.rb`:

```ruby
require "test_helper"

class Api::V1::SpacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "owner@example.com", password: "password123")
    @token = jwt_for(@user)
    @space = @user.spaces.first  # Personal space created automatically
  end

  test "GET /api/v1/spaces returns user spaces" do
    get api_v1_spaces_url,
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json.length
    assert_equal "Personal", json.first["name"]
  end

  test "POST /api/v1/spaces creates a space" do
    post api_v1_spaces_url,
      params: { space: { name: "Garage", description: "Storage boxes" } },
      headers: { "Authorization" => "Bearer #{@token}" },
      as: :json
    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Garage", json["name"]
  end

  test "DELETE /api/v1/spaces/:id destroys space if owner" do
    space = Space.create!(name: "To Delete")
    SpaceMembership.create!(user: @user, space: space, role: :owner)
    delete api_v1_space_url(space),
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :no_content
    assert_not Space.exists?(space.id)
  end

  test "DELETE /api/v1/spaces/:id returns forbidden if not owner" do
    other = User.create!(email: "other@example.com", password: "password123")
    other_token = jwt_for(other)
    space = Space.create!(name: "Private")
    SpaceMembership.create!(user: @user, space: space, role: :owner)
    SpaceMembership.create!(user: other, space: space, role: :member)
    delete api_v1_space_url(space),
      headers: { "Authorization" => "Bearer #{other_token}" }
    assert_response :forbidden
  end
end
```

Add the following helper to `test/test_helper.rb`:

```ruby
require "test_helper"

# Existing content stays. Add below:
module JwtTestHelper
  def jwt_for(user)
    Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
  end
end

class ActionDispatch::IntegrationTest
  include JwtTestHelper
end
```

- [ ] **Step 2: Run tests to verify failure**

```bash
bin/rails test test/controllers/api/v1/spaces_controller_test.rb
```

Expected: Error — `SpacesController` not found.

- [ ] **Step 3: Create Spaces controller**

Create `app/controllers/api/v1/spaces_controller.rb`:

```ruby
class Api::V1::SpacesController < Api::V1::BaseController
  before_action :set_space, only: [:show, :update, :destroy]

  def index
    spaces = current_user.spaces
    render json: SpaceBlueprint.render(spaces)
  end

  def show
    require_membership!
    render json: SpaceBlueprint.render(@space, view: :with_boxes)
  end

  def create
    space = Space.new(space_params)
    if space.save
      SpaceMembership.create!(user: current_user, space: space, role: :owner)
      render json: SpaceBlueprint.render(space), status: :created
    else
      render_error(space.errors.full_messages.join(", "))
    end
  end

  def update
    require_admin!
    if @space.update(space_params)
      render json: SpaceBlueprint.render(@space)
    else
      render_error(@space.errors.full_messages.join(", "))
    end
  end

  def destroy
    require_owner!
    @space.destroy
    head :no_content
  end

  private

  def set_space
    @space = Space.find(params[:id])
  end

  def space_params
    params.require(:space).permit(:name, :description)
  end
end
```

- [ ] **Step 4: Create SpaceMemberships controller**

Create `app/controllers/api/v1/space_memberships_controller.rb`:

```ruby
class Api::V1::SpaceMembershipsController < Api::V1::BaseController
  before_action :set_space

  def create
    require_admin!
    invited = User.find_by!(email: params[:email])
    membership = SpaceMembership.new(user: invited, space: @space, role: params[:role] || :member)
    if membership.save
      render json: { message: "Invitation sent" }, status: :created
    else
      render_error(membership.errors.full_messages.join(", "))
    end
  end

  def destroy
    require_admin!
    membership = @space.space_memberships.find(params[:id])
    render_error("Cannot remove the owner", :forbidden) and return if membership.owner?
    membership.destroy
    head :no_content
  end

  private

  def set_space
    @space = Space.find(params[:space_id])
  end
end
```

- [ ] **Step 5: Run tests**

```bash
bin/rails test test/controllers/api/v1/spaces_controller_test.rb
```

Expected: All 4 tests pass.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/api/v1/spaces_controller.rb \
        app/controllers/api/v1/space_memberships_controller.rb \
        test/controllers/api/v1/spaces_controller_test.rb \
        test/test_helper.rb
git commit -m "feat: add Spaces and SpaceMemberships controllers"
```

---

## Task 10: Boxes Controller

**Files:**
- Create: `app/controllers/api/v1/boxes_controller.rb`
- Create: `test/controllers/api/v1/boxes_controller_test.rb`

- [ ] **Step 1: Write failing tests**

Create `test/controllers/api/v1/boxes_controller_test.rb`:

```ruby
require "test_helper"

class Api::V1::BoxesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "boxuser@example.com", password: "password123")
    @token = jwt_for(@user)
    @space = @user.spaces.first
  end

  test "GET /api/v1/spaces/:space_id/boxes returns boxes" do
    Box.create!(space: @space, name: "Box A")
    get api_v1_space_boxes_url(@space),
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json.length
    assert_equal "Box A", json.first["name"]
  end

  test "POST /api/v1/spaces/:space_id/boxes creates a box" do
    post api_v1_space_boxes_url(@space),
      params: { box: { name: "Winter Clothes" } },
      headers: { "Authorization" => "Bearer #{@token}" },
      as: :json
    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Winter Clothes", json["name"]
    assert_not_nil json["qr_token"]
  end

  test "GET /api/v1/boxes/scan/:qr_token returns box contents" do
    box = Box.create!(space: @space, name: "Scannable Box")
    Item.create!(box: box, name: "Lamp")
    get scan_api_v1_boxes_url(qr_token: box.qr_token),
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Scannable Box", json["name"]
    assert_equal 1, json["items"].length
  end

  test "DELETE /api/v1/boxes/:id destroys the box" do
    box = Box.create!(space: @space, name: "Old Box")
    delete api_v1_box_url(box),
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :no_content
    assert_not Box.exists?(box.id)
  end
end
```

- [ ] **Step 2: Run to verify failure**

```bash
bin/rails test test/controllers/api/v1/boxes_controller_test.rb
```

Expected: Error — `BoxesController` not found.

- [ ] **Step 3: Create Boxes controller**

Create `app/controllers/api/v1/boxes_controller.rb`:

```ruby
class Api::V1::BoxesController < Api::V1::BaseController
  before_action :set_space, only: [:index, :create]
  before_action :set_box, only: [:show, :update, :destroy]

  def index
    require_membership!
    render json: BoxBlueprint.render(@space.boxes)
  end

  def create
    require_membership!
    box = @space.boxes.new(box_params)
    if box.save
      render json: BoxBlueprint.render(box), status: :created
    else
      render_error(box.errors.full_messages.join(", "))
    end
  end

  def show
    authorize_box_access!
    render json: BoxBlueprint.render(@box, view: :with_items, url_helpers: url_helpers)
  end

  def scan
    @box = Box.find_by!(qr_token: params[:qr_token])
    @space = @box.space
    authorize_box_access!
    render json: BoxBlueprint.render(@box, view: :with_items, url_helpers: url_helpers)
  end

  def update
    authorize_box_access!
    if @box.update(box_params)
      render json: BoxBlueprint.render(@box)
    else
      render_error(@box.errors.full_messages.join(", "))
    end
  end

  def destroy
    authorize_box_access!
    @box.destroy
    head :no_content
  end

  private

  def set_space
    @space = Space.find(params[:space_id])
  end

  def set_box
    @box = Box.find(params[:id])
    @space = @box.space
  end

  def box_params
    params.require(:box).permit(:name, :description)
  end

  def authorize_box_access!
    membership = @space.space_memberships.find_by(user: current_user)
    render json: { error: "Forbidden" }, status: :forbidden unless membership
  end
end
```

- [ ] **Step 4: Run tests**

```bash
bin/rails test test/controllers/api/v1/boxes_controller_test.rb
```

Expected: All 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/api/v1/boxes_controller.rb \
        test/controllers/api/v1/boxes_controller_test.rb
git commit -m "feat: add Boxes controller with QR scan endpoint"
```

---

## Task 11: Items + Tags Controllers

**Files:**
- Create: `app/controllers/api/v1/items_controller.rb`
- Create: `app/controllers/api/v1/tags_controller.rb`
- Create: `test/controllers/api/v1/items_controller_test.rb`

- [ ] **Step 1: Write failing tests**

Create `test/controllers/api/v1/items_controller_test.rb`:

```ruby
require "test_helper"

class Api::V1::ItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "itemuser@example.com", password: "password123")
    @token = jwt_for(@user)
    @space = @user.spaces.first
    @box = Box.create!(space: @space, name: "Test Box")
  end

  test "POST /api/v1/boxes/:box_id/items creates an item" do
    post api_v1_box_items_url(@box),
      params: { item: { name: "Vintage Lamp", description: "From 1970s" } },
      headers: { "Authorization" => "Bearer #{@token}" },
      as: :json
    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Vintage Lamp", json["name"]
  end

  test "PATCH /api/v1/items/:id updates an item" do
    item = Item.create!(box: @box, name: "Old Name")
    patch api_v1_item_url(item),
      params: { item: { name: "New Name" } },
      headers: { "Authorization" => "Bearer #{@token}" },
      as: :json
    assert_response :success
    assert_equal "New Name", JSON.parse(response.body)["name"]
  end

  test "DELETE /api/v1/items/:id destroys an item" do
    item = Item.create!(box: @box, name: "Disposable")
    delete api_v1_item_url(item),
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :no_content
    assert_not Item.exists?(item.id)
  end
end
```

- [ ] **Step 2: Run to verify failure**

```bash
bin/rails test test/controllers/api/v1/items_controller_test.rb
```

Expected: Error — `ItemsController` not found.

- [ ] **Step 3: Create Items controller**

Create `app/controllers/api/v1/items_controller.rb`:

```ruby
class Api::V1::ItemsController < Api::V1::BaseController
  before_action :set_box, only: [:create]
  before_action :set_item, only: [:update, :destroy]

  def create
    authorize_space_member!(@box.space)
    item = @box.items.new(item_params)
    if item.save
      render json: ItemBlueprint.render(item, view: :with_tags), status: :created
    else
      render_error(item.errors.full_messages.join(", "))
    end
  end

  def update
    authorize_space_member!(@item.box.space)
    tag_ids = params.dig(:item, :tag_ids)
    if @item.update(item_params)
      @item.taggings.where.not(tag_id: tag_ids).destroy_all if tag_ids
      tag_ids&.each { |id| @item.taggings.find_or_create_by!(tag_id: id) }
      render json: ItemBlueprint.render(@item.reload, view: :with_tags)
    else
      render_error(@item.errors.full_messages.join(", "))
    end
  end

  def destroy
    authorize_space_member!(@item.box.space)
    @item.destroy
    head :no_content
  end

  private

  def set_box
    @box = Box.find(params[:box_id])
  end

  def set_item
    @item = Item.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:name, :description, photos: [])
  end

  def authorize_space_member!(space)
    unless space.space_memberships.exists?(user: current_user)
      render json: { error: "Forbidden" }, status: :forbidden
    end
  end
end
```

- [ ] **Step 4: Create Tags controller**

Create `app/controllers/api/v1/tags_controller.rb`:

```ruby
class Api::V1::TagsController < Api::V1::BaseController
  before_action :set_space

  def index
    require_membership!
    render json: TagBlueprint.render(@space.tags)
  end

  def create
    require_membership!
    tag = @space.tags.new(tag_params)
    if tag.save
      render json: TagBlueprint.render(tag), status: :created
    else
      render_error(tag.errors.full_messages.join(", "))
    end
  end

  private

  def set_space
    @space = Space.find(params[:space_id])
  end

  def tag_params
    params.require(:tag).permit(:name)
  end
end
```

- [ ] **Step 5: Run tests**

```bash
bin/rails test test/controllers/api/v1/items_controller_test.rb
```

Expected: All 3 tests pass.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/api/v1/items_controller.rb \
        app/controllers/api/v1/tags_controller.rb \
        test/controllers/api/v1/items_controller_test.rb
git commit -m "feat: add Items and Tags controllers"
```

---

## Task 12: QR Code Job

**Files:**
- Create: `app/jobs/generate_qr_code_job.rb`
- Create: `test/jobs/generate_qr_code_job_test.rb`

- [ ] **Step 1: Write failing test**

Create `test/jobs/generate_qr_code_job_test.rb`:

```ruby
require "test_helper"

class GenerateQrCodeJobTest < ActiveJob::TestCase
  test "attaches qr_code_image to box" do
    user = User.create!(email: "qrjob@example.com", password: "password123")
    space = user.spaces.first
    # Prevent job from auto-running so we can test it explicitly
    box = nil
    assert_no_enqueued_jobs do
      box = Box.new(space: space, name: "QR Test Box")
      box.save_without_callbacks rescue box.save  # save without triggering after_create
    end
    box = Box.create!(space: space, name: "QR Box Direct")
    
    GenerateQrCodeJob.perform_now(box.id)

    box.reload
    assert box.qr_code_image.attached?
    assert_equal "image/png", box.qr_code_image.content_type
  end
end
```

- [ ] **Step 2: Run to verify failure**

```bash
bin/rails test test/jobs/generate_qr_code_job_test.rb
```

Expected: Error — `GenerateQrCodeJob` not found.

- [ ] **Step 3: Create the job**

Create `app/jobs/generate_qr_code_job.rb`:

```ruby
class GenerateQrCodeJob < ApplicationJob
  queue_as :default

  def perform(box_id)
    box = Box.find_by(id: box_id)
    return unless box

    url = "#{ENV.fetch('APP_BASE_URL', 'http://localhost:3000')}/scan/#{box.qr_token}"
    qr = RQRCode::QRCode.new(url)
    png = qr.as_png(size: 300, border_modules: 2)

    box.qr_code_image.attach(
      io: StringIO.new(png.to_s),
      filename: "box-#{box.qr_token}.png",
      content_type: "image/png"
    )
  end
end
```

- [ ] **Step 4: Run tests**

```bash
bin/rails test test/jobs/generate_qr_code_job_test.rb
```

Expected: 1 test passes.

- [ ] **Step 5: Commit**

```bash
git add app/jobs/generate_qr_code_job.rb test/jobs/
git commit -m "feat: add GenerateQrCodeJob for async QR code image creation"
```

---

## Task 13: Search Endpoint

**Files:**
- Create: `app/controllers/api/v1/search_controller.rb`
- Create: `test/controllers/api/v1/search_controller_test.rb`

- [ ] **Step 1: Write failing test**

Create `test/controllers/api/v1/search_controller_test.rb`:

```ruby
require "test_helper"

class Api::V1::SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "searcher@example.com", password: "password123")
    @token = jwt_for(@user)
    @space = @user.spaces.first
    @box = Box.create!(space: @space, name: "Electronics Box")
    @item = Item.create!(box: @box, name: "Vintage Lamp", description: "From the 1970s")
    # Refresh the tsvector (the trigger fires on INSERT but we need to ensure it ran)
    @item.touch
  end

  test "GET /api/v1/search finds items by name" do
    get api_v1_search_url,
      params: { q: "Vintage", space_id: @space.id },
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json.length
    assert_equal "Vintage Lamp", json.first["name"]
    assert_equal "Electronics Box", json.first["box_name"]
  end

  test "GET /api/v1/search returns empty array when no match" do
    get api_v1_search_url,
      params: { q: "nonexistent", space_id: @space.id },
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end

  test "GET /api/v1/search returns forbidden for space user is not member of" do
    other_space = Space.create!(name: "Secret")
    get api_v1_search_url,
      params: { q: "anything", space_id: other_space.id },
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :forbidden
  end
end
```

- [ ] **Step 2: Run to verify failure**

```bash
bin/rails test test/controllers/api/v1/search_controller_test.rb
```

Expected: Error — `SearchController` not found.

- [ ] **Step 3: Create Search controller**

Create `app/controllers/api/v1/search_controller.rb`:

```ruby
class Api::V1::SearchController < Api::V1::BaseController
  def index
    space = Space.find_by(id: params[:space_id])
    unless space&.space_memberships&.exists?(user: current_user)
      return render json: { error: "Forbidden" }, status: :forbidden
    end

    if params[:q].blank?
      return render json: []
    end

    items = Item.joins(:box)
                .where(boxes: { space_id: space.id })
                .search(params[:q])
                .includes(:tags)

    render json: ItemBlueprint.render(items, view: :with_box)
  end
end
```

- [ ] **Step 4: Run tests**

```bash
bin/rails test test/controllers/api/v1/search_controller_test.rb
```

Expected: All 3 tests pass.

- [ ] **Step 5: Run the full test suite**

```bash
bin/rails test
```

Expected: All tests pass. Fix any failures before proceeding.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/api/v1/search_controller.rb \
        test/controllers/api/v1/search_controller_test.rb
git commit -m "feat: add full-text search endpoint using PostgreSQL tsvector"
```

---

## Task 14: Final Wiring + Smoke Test

**Files:**
- Verify: `config/application.rb` (Solid Queue adapter)
- Run: security and style checks

- [ ] **Step 1: Verify Solid Queue is the queue adapter**

Open `config/application.rb` and ensure this line exists (add it if not):

```ruby
config.active_job.queue_adapter = :solid_queue
```

- [ ] **Step 2: Start the server and verify it boots**

```bash
bin/rails server
```

Expected: Server starts on port 3000 with no errors. Hit `http://localhost:3000/up` and get a 200 response.

Stop the server with Ctrl+C.

- [ ] **Step 3: Run Brakeman security scan**

```bash
bundle exec brakeman --no-pager
```

Expected: 0 warnings, or review and document any that are acceptable.

- [ ] **Step 4: Run Bundler audit**

```bash
bundle exec bundler-audit check --update
```

Expected: No vulnerabilities found.

- [ ] **Step 5: Commit**

```bash
git add config/application.rb
git commit -m "feat: verify Solid Queue adapter and complete Boxyn API implementation"
```

---

## Implementation Complete

All 14 tasks implement the full Boxyn API as specified:

| Feature | Task |
|---------|------|
| Gemfile (auth, oauth, test gems) | Task 1 |
| All DB migrations + FTS trigger | Task 2 |
| All models + validations | Task 3 |
| Devise + JWT + OAuth + CORS config | Task 4 |
| Auth controllers (sign-in, sign-up, OAuth) | Task 5 |
| Blueprinter serializers | Task 6 |
| Routes | Task 7 |
| Base controller + SpaceAuthorization | Task 8 |
| Spaces + Memberships controllers | Task 9 |
| Boxes controller + QR scan | Task 10 |
| Items + Tags controllers | Task 11 |
| GenerateQrCodeJob | Task 12 |
| Search endpoint | Task 13 |
| Final wiring + security checks | Task 14 |
