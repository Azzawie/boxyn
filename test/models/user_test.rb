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
