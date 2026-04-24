require 'rails_helper'

RSpec.describe 'Auth', type: :request do
  describe 'POST /auth/sign_up' do
    let(:valid_params) do
      {
        user: {
          email: Faker::Internet.unique.email,
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
    end

    context 'with valid credentials' do
      it 'returns 201 and the user payload' do
        post '/auth/sign_up', params: valid_params.to_json,
          headers: { 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:created)
        expect(json['email']).to eq(valid_params[:user][:email])
        expect(json).to include('id')
        expect(json.keys).not_to include('encrypted_password')
      end

      it 'returns a JWT in the Authorization header' do
        post '/auth/sign_up', params: valid_params.to_json,
          headers: { 'Content-Type' => 'application/json' }

        expect(response.headers['Authorization']).to be_present
        expect(response.headers['Authorization']).to start_with('Bearer ')
      end

      it 'creates a Personal space for the new user' do
        post '/auth/sign_up', params: valid_params.to_json,
          headers: { 'Content-Type' => 'application/json' }

        user = User.find(json['id'])
        expect(user.spaces.pluck(:name)).to include('Personal')
        expect(user.space_memberships.first.role).to eq('owner')
      end
    end

    context 'with invalid credentials' do
      it 'returns 422 when email is missing' do
        post '/auth/sign_up',
          params: { user: { password: 'password123', password_confirmation: 'password123' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['errors']).to be_present
      end

      it 'returns 422 when password confirmation does not match' do
        post '/auth/sign_up',
          params: { user: { email: 'a@b.com', password: 'password123', password_confirmation: 'wrong' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns 422 when email is already taken' do
        create(:user, email: 'taken@example.com')
        post '/auth/sign_up',
          params: { user: { email: 'taken@example.com', password: 'password123', password_confirmation: 'password123' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'POST /auth/sign_in' do
    let!(:user) { create(:user, email: 'login@example.com', password: 'password123') }

    context 'with valid credentials' do
      it 'returns 200 and the user payload' do
        post '/auth/sign_in',
          params: { user: { email: 'login@example.com', password: 'password123' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:ok)
        expect(json['email']).to eq('login@example.com')
      end

      it 'returns a JWT in the Authorization header' do
        post '/auth/sign_in',
          params: { user: { email: 'login@example.com', password: 'password123' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }

        expect(response.headers['Authorization']).to be_present
        expect(response.headers['Authorization']).to start_with('Bearer ')
      end
    end

    context 'with invalid credentials' do
      it 'returns 401 for wrong password' do
        post '/auth/sign_in',
          params: { user: { email: 'login@example.com', password: 'wrongpassword' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns 401 for unknown email' do
        post '/auth/sign_in',
          params: { user: { email: 'ghost@example.com', password: 'password123' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /auth/sign_out' do
    let!(:user) { create(:user) }

    it 'returns 204 and revokes the token' do
      token = jwt_for(user)
      headers = { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' }

      delete '/auth/sign_out', headers: headers
      expect(response).to have_http_status(:no_content)

      # Token should now be revoked — subsequent request returns 401
      get '/api/v1/spaces', headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'unauthenticated API access' do
    it 'returns 401 when no token is provided' do
      get '/api/v1/spaces'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 when token is invalid' do
      get '/api/v1/spaces', headers: { 'Authorization' => 'Bearer totallyinvalidtoken' }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
