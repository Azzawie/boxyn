class GenerateQrCodeJob < ApplicationJob
  queue_as :default

  def perform(box_id)
    box = Box.find_by(id: box_id)
    return unless box

    app_base_url = ENV.fetch('APP_BASE_URL') do
      Rails.env.development? ? 'http://localhost:3000' : nil
    end
    raise "APP_BASE_URL must be set in production" if app_base_url.blank?

    url = "#{app_base_url}/scan/#{box.qr_token}"
    qr = RQRCode::QRCode.new(url)
    png = qr.as_png(size: 300, border_modules: 2)

    box.qr_code_image.attach(
      io: StringIO.new(png.to_s),
      filename: "box-#{box.qr_token}.png",
      content_type: "image/png"
    )
  end
end
