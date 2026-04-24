require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  let!(:user)    { create(:user) }
  let!(:headers) { auth_headers(user) }
  let!(:space)   { user.spaces.first } # Personal space auto-created

  describe 'GET /api/v1/spaces' do
    it 'returns all spaces the user belongs to' do
      extra = create(:space)
      create(:space_membership, user: user, space: extra, role: :member)

      get '/api/v1/spaces', headers: headers

      expect(response).to have_http_status(:ok)
      expect(json.length).to eq(2)
      expect(json.map { |s| s['name'] }).to include('Personal', extra.name)
    end

    it 'does not return spaces the user is not a member of' do
      create(:space) # unrelated space

      get '/api/v1/spaces', headers: headers

      expect(json.length).to eq(1)
    end

    it 'returns 401 without a token' do
      get '/api/v1/spaces'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/spaces/:id' do
    it 'returns the space with its boxes' do
      create(:box, space: space, name: 'Tool Box')

      get "/api/v1/spaces/#{space.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json['name']).to eq('Personal')
      expect(json['boxes'].first['name']).to eq('Tool Box')
    end

    it 'returns 403 for a space the user is not a member of' do
      other = create(:space)

      get "/api/v1/spaces/#{other.id}", headers: headers

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/v1/spaces' do
    it 'creates a space and makes the user the owner' do
      post '/api/v1/spaces',
        params: { space: { name: 'Garage', description: 'Tools and bikes' } }.to_json,
        headers: headers.merge('Content-Type' => 'application/json')

      expect(response).to have_http_status(:created)
      expect(json['name']).to eq('Garage')

      new_space = Space.find(json['id'])
      membership = new_space.space_memberships.find_by(user: user)
      expect(membership.role).to eq('owner')
    end

    it 'returns 422 when name is missing' do
      post '/api/v1/spaces',
        params: { space: { description: 'No name' } }.to_json,
        headers: headers.merge('Content-Type' => 'application/json')

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/spaces/:id' do
    context 'as owner' do
      it 'updates the space' do
        patch "/api/v1/spaces/#{space.id}",
          params: { space: { description: 'Updated description' } }.to_json,
          headers: headers.merge('Content-Type' => 'application/json')

        expect(response).to have_http_status(:ok)
        expect(json['description']).to eq('Updated description')
      end
    end

    context 'as member' do
      it 'returns 403' do
        other_space = create(:space)
        create(:space_membership, user: user, space: other_space, role: :member)

        patch "/api/v1/spaces/#{other_space.id}",
          params: { space: { name: 'Hacked' } }.to_json,
          headers: headers.merge('Content-Type' => 'application/json')

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /api/v1/spaces/:id' do
    context 'as owner' do
      it 'destroys the space' do
        delete "/api/v1/spaces/#{space.id}", headers: headers

        expect(response).to have_http_status(:no_content)
        expect(Space.exists?(space.id)).to be false
      end
    end

    context 'as admin' do
      it 'returns 403' do
        other_space = create(:space)
        create(:space_membership, user: user, space: other_space, role: :admin)

        delete "/api/v1/spaces/#{other_space.id}", headers: headers

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'as member' do
      it 'returns 403' do
        other_space = create(:space)
        create(:space_membership, user: user, space: other_space, role: :member)

        delete "/api/v1/spaces/#{other_space.id}", headers: headers

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
