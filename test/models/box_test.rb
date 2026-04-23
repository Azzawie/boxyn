require "test_helper"

class BoxTest < ActiveSupport::TestCase
  test "generates qr_token before create" do
    user = User.create!(email: "boxtest@example.com", password: "password123")
    space = user.spaces.first
    box = Box.create!(space: space, name: "Test Box")
    assert_not_nil box.qr_token
    assert_match(/\A[0-9a-f-]{36}\z/, box.qr_token)
  end
end
