module JwtHelper
  def jwt_for(user)
    Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
  end

  def auth_headers(user)
    { 'Authorization' => "Bearer #{jwt_for(user)}" }
  end
end
