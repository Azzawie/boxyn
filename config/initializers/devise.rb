require 'devise/orm/active_record'

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

  # Pure JSON API — no navigational formats means Devise never attempts
  # to set flash messages, avoiding the flash/session errors in API mode
  config.navigational_formats = []

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

  # Mount OmniAuth at /auth/oauth/* so it doesn't clash with
  # Devise's own /auth/sign_in and /auth/sign_up routes
  config.omniauth_path_prefix = '/auth/oauth'

  # Google OAuth - only mount if credentials are present
  if ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
    config.omniauth :google_oauth2,
      ENV.fetch("GOOGLE_CLIENT_ID"),
      ENV.fetch("GOOGLE_CLIENT_SECRET"),
      scope: "email,profile"
  end

  # Apple OAuth - only mount if credentials are present
  if ENV["APPLE_TEAM_ID"].present? && ENV["APPLE_CLIENT_ID"].present? &&
     ENV["APPLE_KEY_ID"].present? && ENV["APPLE_PRIVATE_KEY"].present?
    config.omniauth :apple,
      ENV.fetch("APPLE_TEAM_ID"),
      ENV.fetch("APPLE_CLIENT_ID"),
      key_id: ENV.fetch("APPLE_KEY_ID"),
      pem: ENV.fetch("APPLE_PRIVATE_KEY").gsub("\\n", "\n")
  end
end
