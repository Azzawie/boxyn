require "test_helper"

class GenerateQrCodeJobTest < ActiveJob::TestCase
  test "attaches qr_code_image to box" do
    user = User.create!(email: "qrjob@example.com", password: "password123")
    space = user.spaces.first
    box = Box.create!(space: space, name: "QR Box Direct")

    GenerateQrCodeJob.perform_now(box.id)

    box.reload
    assert box.qr_code_image.attached?
    assert_equal "image/png", box.qr_code_image.content_type
  end
end
