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
