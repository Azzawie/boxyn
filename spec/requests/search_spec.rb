require 'rails_helper'

RSpec.describe 'Search', type: :request do
  let!(:user)    { create(:user) }
  let!(:space)   { user.spaces.first }
  let!(:box)     { create(:box, space: space, name: 'Electronics Box') }
  let!(:headers) { auth_headers(user) }

  # The tsvector trigger fires on INSERT, but RSpec transactional fixtures
  # can cause the trigger to not propagate. Force it by executing raw SQL.
  def create_searchable_item(attrs)
    item = create(:item, attrs)
    ActiveRecord::Base.connection.execute(
      "UPDATE items SET search_vector = " \
      "to_tsvector('english', #{ActiveRecord::Base.connection.quote(item.name)} || ' ' || " \
      "COALESCE(#{ActiveRecord::Base.connection.quote(item.description)}, '')) " \
      "WHERE id = #{item.id}"
    )
    item
  end

  describe 'GET /api/v1/search' do
    before do
      @lamp  = create_searchable_item(box: box, name: 'Vintage Lamp',  description: 'From the 1970s')
      @chair = create_searchable_item(box: box, name: 'Wooden Chair',  description: 'Oak finish')
    end

    it 'returns items matching the query by name' do
      get '/api/v1/search', params: { q: 'Vintage', space_id: space.id }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(json.length).to eq(1)
      expect(json.first['name']).to eq('Vintage Lamp')
    end

    it 'returns items matching the query by description' do
      get '/api/v1/search', params: { q: 'Oak', space_id: space.id }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(json.first['name']).to eq('Wooden Chair')
    end

    it 'includes box_name and box_id in each result' do
      get '/api/v1/search', params: { q: 'Vintage', space_id: space.id }, headers: headers

      expect(json.first['box_name']).to eq('Electronics Box')
      expect(json.first['box_id']).to eq(box.id)
    end

    it 'returns results from all boxes in the space' do
      other_box = create(:box, space: space, name: 'Other Box')
      create_searchable_item(box: other_box, name: 'Vintage Radio', description: 'Old radio')

      get '/api/v1/search', params: { q: 'Vintage', space_id: space.id }, headers: headers

      expect(json.length).to eq(2)
    end

    it 'does not return items from other spaces' do
      other_user  = create(:user)
      other_space = other_user.spaces.first
      other_box   = create(:box, space: other_space)
      create_searchable_item(box: other_box, name: 'Vintage Trophy', description: 'Golden')

      get '/api/v1/search', params: { q: 'Vintage', space_id: space.id }, headers: headers

      names = json.map { |r| r['name'] }
      expect(names).not_to include('Vintage Trophy')
    end

    it 'returns an empty array when there are no matches' do
      get '/api/v1/search', params: { q: 'nonexistent', space_id: space.id }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(json).to eq([])
    end

    it 'returns an empty array when query is blank' do
      get '/api/v1/search', params: { q: '', space_id: space.id }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(json).to eq([])
    end

    it 'returns 403 when user is not a member of the space' do
      other_space = create(:space)

      get '/api/v1/search', params: { q: 'anything', space_id: other_space.id }, headers: headers

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 when space_id does not exist' do
      get '/api/v1/search', params: { q: 'anything', space_id: 99999 }, headers: headers

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 401 without a token' do
      get '/api/v1/search', params: { q: 'Vintage', space_id: space.id }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
