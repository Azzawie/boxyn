require "test_helper"

class SpaceTest < ActiveSupport::TestCase
  test "is invalid without name" do
    space = Space.new
    assert_not space.valid?
    assert_includes space.errors[:name], "can't be blank"
  end
end
