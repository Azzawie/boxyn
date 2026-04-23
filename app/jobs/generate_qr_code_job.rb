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
