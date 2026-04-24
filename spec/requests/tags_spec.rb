require 'rails_helper'

RSpec.describe 'Tags', type: :request do
  let!(:user)    { create(:user) }
  let!(:space)   { user.spaces.first }
  let!(:headers) { auth_headers(user) }

  describe 'GET /api/v1/spaces/:space_id/tags' do
    it 'returns all tags in the space' do
      create_list(:tag, 3, space: space)

      get "/api/v1/spaces/#{space.id}/tags", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json.length).to eq(3)
    end

    it 'does not return tags from other spaces' do
      other_space = create(:space)
      create(:tag, space: other_space, name: 'alien-tag')

      get "/api/v1/spaces/#{space.id}/tags", headers: headers

      names = json.map { |t| t['name'] }
      expect(names).not_to include('alien-tag')
    end

    it 'returns 403 when user is not a member of the space' do
      other = create(:space)

      get "/api/v1/spaces/#{other.id}/tags", headers: headers

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/v1/spaces/:space_id/tags' do
    it 'creates a tag in the space' do
      post "/api/v1/spaces/#{space.id}/tags",
        params: { tag: { name: 'fragile' } }.to_json,
        headers: headers.merge('Content-Type' => 'application/json')

      expect(response).to have_http_status(:created)
      expect(json['name']).to eq('fragile')
    end

    it 'returns 422 for a duplicate tag name in the same space' do
      create(:tag, space: space, name: 'fragile')

      post "/api/v1/spaces/#{space.id}/tags",
        params: { tag: { name: 'fragile' } }.to_json,
        headers: headers.merge('Content-Type' => 'application/json')

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'allows the same tag name in a different space' do
      other_space = create(:space)
      create(:space_membership, user: user, space: other_space, role: :owner)
      create(:tag, space: space, name: 'fragile')

      post "/api/v1/spaces/#{other_space.id}/tags",
        params: { tag: { name: 'fragile' } }.to_json,
        headers: headers.merge('Content-Type' => 'application/json')

      expect(response).to have_http_status(:created)
    end

    it 'returns 422 when name is missing' do
      post "/api/v1/spaces/#{space.id}/tags",
        params: { tag: { name: '' } }.to_json,
        headers: headers.merge('Content-Type' => 'application/json')

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 403 when user is not a member' do
      other = create(:space)

      post "/api/v1/spaces/#{other.id}/tags",
        params: { tag: { name: 'fragile' } }.to_json,
        headers: headers.merge('Content-Type' => 'application/json')

      expect(response).to have_http_status(:forbidden)
    end
  end
end
