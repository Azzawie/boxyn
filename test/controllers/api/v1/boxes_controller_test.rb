require "test_helper"

class Api::V1::BoxesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "boxuser@example.com", password: "password123")
    @token = jwt_for(@user)
    @space = @user.spaces.first
  end

  test "GET /api/v1/spaces/:space_id/boxes returns boxes" do
    Box.create!(space: @space, name: "Box A")
    get api_v1_space_boxes_url(@space),
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json.length
    assert_equal "Box A", json.first["name"]
  end

  test "POST /api/v1/spaces/:space_id/boxes creates a box" do
    post api_v1_space_boxes_url(@space),
      params: { box: { name: "Winter Clothes" } },
      headers: { "Authorization" => "Bearer #{@token}" },
      as: :json
    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Winter Clothes", json["name"]
    assert_not_nil json["qr_token"]
  end

  test "GET /api/v1/boxes/scan/:qr_token returns box contents" do
    box = Box.create!(space: @space, name: "Scannable Box")
    Item.create!(box: box, name: "Lamp")
    get scan_api_v1_boxes_url(qr_token: box.qr_token),
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Scannable Box", json["name"]
    assert_equal 1, json["items"].length
  end

  test "DELETE /api/v1/boxes/:id destroys the box" do
    box = Box.create!(space: @space, name: "Old Box")
    delete api_v1_box_url(box),
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :no_content
    assert_not Box.exists?(box.id)
  end
end
