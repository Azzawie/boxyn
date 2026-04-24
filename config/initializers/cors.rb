Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    allowed = ENV.fetch("ALLOWED_ORIGINS") do
      Rails.env.production? ? "" : "http://localhost:3000"
    end
    origins allowed.split(",").map(&:strip).reject(&:empty?)

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ["Authorization"]
  end
end
