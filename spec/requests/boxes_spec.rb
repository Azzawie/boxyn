require 'rails_helper'

RSpec.describe 'Boxes', type: :request do
  let!(:user)    { create(:user) }
  let!(:space)   { user.spaces.first }
  let!(:headers) { auth_headers(user) }

  describe 'GET /api/v1/spaces/:space_id/boxes' do
    it 'returns all boxes in the space' do
      create_list(:box, 3, space: space)

      get "/api/v1/spaces/#{space.id}/boxes", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json.length).to eq(3)
    end

    it 'returns 403 for a space the user does not belong to' do
      other = create(:space)

      get "/api/v1/spaces/#{other.id}/boxes", headers: headers

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/v1/spaces/:space_id/boxes' do
    it 'creates a box with a qr_token' do
      post "/api/v1/spaces/#{space.id}/boxes",
        params: { box: { name: 'Winter Clothes', description: 'Jackets' } }.to_json,
        headers: headers.merge('Content-Type' => 'application/json')

      expect(response).to have_http_status(:created)
      expect(json['name']).to eq('Winter Clothes')
      expect(json['qr_token']).to be_present
      expect(json['qr_token']).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'enqueues a QR code generation job' do
      expect {
        post "/api/v1/spaces/#{space.id}/boxes",
          params: { box: { name: 'New Box' } }.to_json,
          headers: headers.merge('Content-Type' => 'application/json')
      }.to have_enqueued_job(GenerateQrCodeJob)
    end

    it 'returns 422 when name is missing' do
      post "/api/v1/spaces/#{space.id}/boxes",
        params: { box: { description: 'No name' } }.to_json,
        headers: headers.merge('Content-Type' => 'application/json')

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 403 for a space the user does not belong to' do
      other = create(:space)

      post "/api/v1/spaces/#{other.id}/boxes",
        params: { box: { name: 'Sneaky Box' } }.to_json,
        headers: headers.merge('Content-Type' => 'application/json')

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/v1/boxes/:id' do
    let!(:box)  { create(:box, space: space, name: 'My Box') }
    let!(:item) { create(:item, box: box, name: 'Old Camera') }

    it 'returns the box with its items' do
      get "/api/v1/boxes/#{box.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json['name']).to eq('My Box')
      expect(json['items'].first['name']).to eq('Old Camera')
    end

    it 'returns 403 when user does not belong to the space' do
      outsider = create(:user)

      get "/api/v1/boxes/#{box.id}", headers: auth_headers(outsider)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/v1/boxes/scan/:qr_token' do
    let!(:box)  { create(:box, space: space) }
    let!(:item) { create(:item, box: box) }

    it 'returns the box and its items by QR token' do
      get "/api/v1/boxes/scan/#{box.qr_token}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json['id']).to eq(box.id)
      expect(json['items'].length).to eq(1)
    end

    it 'returns 404 for an unknown QR token' do
      get "/api/v1/boxes/scan/00000000-0000-0000-0000-000000000000", headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 403 when user is not a member of the box space' do
      outsider = create(:user)

      get "/api/v1/boxes/scan/#{box.qr_token}", headers: auth_headers(outsider)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PATCH /api/v1/boxes/:id' do
    let!(:box) { create(:box, space: space, name: 'Old Name') }

    it 'updates the box' do
      patch "/api/v1/boxes/#{box.id}",
        params: { box: { name: 'New Name' } }.to_json,
        headers: headers.merge('Content-Type' => 'application/json')

      expect(response).to have_http_status(:ok)
      expect(json['name']).to eq('New Name')
    end

    it 'returns 403 when user does not belong to the space' do
      outsider = create(:user)

      patch "/api/v1/boxes/#{box.id}",
        params: { box: { name: 'Hacked' } }.to_json,
        headers: auth_headers(outsider).merge('Content-Type' => 'application/json')

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE /api/v1/boxes/:id' do
    let!(:box) { create(:box, space: space) }

    it 'destroys the box and its items' do
      item = create(:item, box: box)

      delete "/api/v1/boxes/#{box.id}", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(Box.exists?(box.id)).to be false
      expect(Item.exists?(item.id)).to be false
    end

    it 'returns 403 when user does not belong to the space' do
      outsider = create(:user)

      delete "/api/v1/boxes/#{box.id}", headers: auth_headers(outsider)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
