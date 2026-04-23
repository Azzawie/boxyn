require "test_helper"

class Api::V1::SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "searcher@example.com", password: "password123")
    @token = jwt_for(@user)
    @space = @user.spaces.first
    @box = Box.create!(space: @space, name: "Electronics Box")
    @item = Item.create!(box: @box, name: "Vintage Lamp", description: "From the 1970s")
    # Refresh the tsvector (the trigger fires on INSERT but we need to ensure it ran)
    @item.touch
  end

  test "GET /api/v1/search finds items by name" do
    get api_v1_search_url,
      params: { q: "Vintage", space_id: @space.id },
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json.length
    assert_equal "Vintage Lamp", json.first["name"]
    assert_equal "Electronics Box", json.first["box_name"]
  end

  test "GET /api/v1/search returns empty array when no match" do
    get api_v1_search_url,
      params: { q: "nonexistent", space_id: @space.id },
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end

  test "GET /api/v1/search returns forbidden for space user is not member of" do
    other_space = Space.create!(name: "Secret")
    get api_v1_search_url,
      params: { q: "anything", space_id: other_space.id },
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :forbidden
  end
end
