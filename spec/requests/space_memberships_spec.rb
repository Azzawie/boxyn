require 'rails_helper'

RSpec.describe 'SpaceMemberships', type: :request do
  let!(:owner)   { create(:user) }
  let!(:space)   { owner.spaces.first }
  let!(:headers) { auth_headers(owner) }

  describe 'POST /api/v1/spaces/:space_id/memberships' do
    let!(:invitee) { create(:user) }

    context 'as owner' do
      it 'invites a user as member' do
        post "/api/v1/spaces/#{space.id}/memberships",
          params: { email: invitee.email, role: 'member' }.to_json,
          headers: headers.merge('Content-Type' => 'application/json')

        expect(response).to have_http_status(:created)
        expect(json['message']).to eq('Invitation sent')
        expect(space.members).to include(invitee)
      end

      it 'invites a user as admin' do
        post "/api/v1/spaces/#{space.id}/memberships",
          params: { email: invitee.email, role: 'admin' }.to_json,
          headers: headers.merge('Content-Type' => 'application/json')

        expect(response).to have_http_status(:created)
        membership = SpaceMembership.find_by(user: invitee, space: space)
        expect(membership.role).to eq('admin')
      end

      it 'returns 422 when user is already a member' do
        create(:space_membership, user: invitee, space: space, role: :member)

        post "/api/v1/spaces/#{space.id}/memberships",
          params: { email: invitee.email, role: 'member' }.to_json,
          headers: headers.merge('Content-Type' => 'application/json')

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'as member' do
      it 'returns 403' do
        member_user = create(:user)
        create(:space_membership, user: member_user, space: space, role: :member)

        post "/api/v1/spaces/#{space.id}/memberships",
          params: { email: invitee.email }.to_json,
          headers: auth_headers(member_user).merge('Content-Type' => 'application/json')

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /api/v1/spaces/:space_id/memberships/:id' do
    let!(:member_user) { create(:user) }
    let!(:membership)  { create(:space_membership, user: member_user, space: space, role: :member) }

    context 'as owner' do
      it 'removes the member' do
        delete "/api/v1/spaces/#{space.id}/memberships/#{membership.id}",
          headers: headers

        expect(response).to have_http_status(:no_content)
        expect(SpaceMembership.exists?(membership.id)).to be false
      end

      it 'cannot remove the owner membership' do
        owner_membership = SpaceMembership.find_by(user: owner, space: space)

        delete "/api/v1/spaces/#{space.id}/memberships/#{owner_membership.id}",
          headers: headers

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'as member' do
      it 'returns 403' do
        other_member = create(:user)
        create(:space_membership, user: other_member, space: space, role: :member)

        delete "/api/v1/spaces/#{space.id}/memberships/#{membership.id}",
          headers: auth_headers(other_member)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
