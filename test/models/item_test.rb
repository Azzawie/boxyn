require "test_helper"

class ItemTest < ActiveSupport::TestCase
  test "is invalid without name" do
    user = User.create!(email: "itemtest@example.com", password: "password123")
    space = user.spaces.first
    box = Box.create!(space: space, name: "Test Box")
    item = Item.new(box: box)
    assert_not item.valid?
    assert_includes item.errors[:name], "can't be blank"
  end
end
