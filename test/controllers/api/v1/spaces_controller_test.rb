require "test_helper"

class Api::V1::SpacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "owner@example.com", password: "password123")
    @token = jwt_for(@user)
    @space = @user.spaces.first  # Personal space created automatically
  end

  test "GET /api/v1/spaces returns user spaces" do
    get api_v1_spaces_url,
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json.length
    assert_equal "Personal", json.first["name"]
  end

  test "POST /api/v1/spaces creates a space" do
    post api_v1_spaces_url,
      params: { space: { name: "Garage", description: "Storage boxes" } },
      headers: { "Authorization" => "Bearer #{@token}" },
      as: :json
    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Garage", json["name"]
  end

  test "DELETE /api/v1/spaces/:id destroys space if owner" do
    space = Space.create!(name: "To Delete")
    SpaceMembership.create!(user: @user, space: space, role: :owner)
    delete api_v1_space_url(space),
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :no_content
    assert_not Space.exists?(space.id)
  end

  test "DELETE /api/v1/spaces/:id returns forbidden if not owner" do
    other = User.create!(email: "other@example.com", password: "password123")
    other_token = jwt_for(other)
    space = Space.create!(name: "Private")
    SpaceMembership.create!(user: @user, space: space, role: :owner)
    SpaceMembership.create!(user: other, space: space, role: :member)
    delete api_v1_space_url(space),
      headers: { "Authorization" => "Bearer #{other_token}" }
    assert_response :forbidden
  end
end
