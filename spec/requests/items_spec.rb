require 'rails_helper'

RSpec.describe 'Items', type: :request do
  let!(:user)    { create(:user) }
  let!(:space)   { user.spaces.first }
  let!(:box)     { create(:box, space: space) }
  let!(:headers) { auth_headers(user) }

  describe 'POST /api/v1/boxes/:box_id/items' do
    it 'creates an item in the box' do
      post "/api/v1/boxes/#{box.id}/items",
        params: { item: { name: 'Vintage Lamp', description: 'From the 1970s' } }.to_json,
        headers: headers.merge('Content-Type' => 'application/json')

      expect(response).to have_http_status(:created)
      expect(json['name']).to eq('Vintage Lamp')
      expect(json['description']).to eq('From the 1970s')
      expect(json['tags']).to eq([])
    end

    it 'returns 422 when name is missing' do
      post "/api/v1/boxes/#{box.id}/items",
        params: { item: { description: 'No name' } }.to_json,
        headers: headers.merge('Content-Type' => 'application/json')

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 403 when user does not belong to the space' do
      outsider = create(:user)

      post "/api/v1/boxes/#{box.id}/items",
        params: { item: { name: 'Sneaky Item' } }.to_json,
        headers: auth_headers(outsider).merge('Content-Type' => 'application/json')

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PATCH /api/v1/items/:id' do
    let!(:item) { create(:item, box: box, name: 'Old Name') }

    it 'updates the item name and description' do
      patch "/api/v1/items/#{item.id}",
        params: { item: { name: 'New Name', description: 'Updated desc' } }.to_json,
        headers: headers.merge('Content-Type' => 'application/json')

      expect(response).to have_http_status(:ok)
      expect(json['name']).to eq('New Name')
      expect(json['description']).to eq('Updated desc')
    end

    it 'assigns tags when tag_ids are provided' do
      tag1 = create(:tag, space: space)
      tag2 = create(:tag, space: space)

      patch "/api/v1/items/#{item.id}",
        params: { item: { name: item.name, tag_ids: [tag1.id, tag2.id] } }.to_json,
        headers: headers.merge('Content-Type' => 'application/json')

      expect(response).to have_http_status(:ok)
      tag_names = json['tags'].map { |t| t['name'] }
      expect(tag_names).to include(tag1.name, tag2.name)
    end

    it 'replaces existing tags when new tag_ids are provided' do
      old_tag = create(:tag, space: space)
      create(:tagging, item: item, tag: old_tag)
      new_tag = create(:tag, space: space)

      patch "/api/v1/items/#{item.id}",
        params: { item: { name: item.name, tag_ids: [new_tag.id] } }.to_json,
        headers: headers.merge('Content-Type' => 'application/json')

      expect(response).to have_http_status(:ok)
      expect(json['tags'].map { |t| t['id'] }).to eq([new_tag.id])
    end

    it 'returns 403 when user does not belong to the space' do
      outsider = create(:user)

      patch "/api/v1/items/#{item.id}",
        params: { item: { name: 'Hacked' } }.to_json,
        headers: auth_headers(outsider).merge('Content-Type' => 'application/json')

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE /api/v1/items/:id' do
    let!(:item) { create(:item, box: box) }

    it 'destroys the item' do
      delete "/api/v1/items/#{item.id}", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(Item.exists?(item.id)).to be false
    end

    it 'also destroys associated taggings' do
      tag = create(:tag, space: space)
      tagging = create(:tagging, item: item, tag: tag)

      delete "/api/v1/items/#{item.id}", headers: headers

      expect(Tagging.exists?(tagging.id)).to be false
    end

    it 'returns 403 when user does not belong to the space' do
      outsider = create(:user)

      delete "/api/v1/items/#{item.id}", headers: auth_headers(outsider)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
