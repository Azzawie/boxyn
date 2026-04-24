class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :validatable,
         :omniauthable, :jwt_authenticatable,
         omniauth_providers: %i[google_oauth2 apple],
         jwt_revocation_strategy: JwtDenylist

  has_many :space_memberships, dependent: :destroy
  has_many :spaces, through: :space_memberships

  after_create :create_personal_space

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
    end
  end

  private

  def create_personal_space
    ActiveRecord::Base.transaction do
      space = Space.create!(name: "Personal")
      SpaceMembership.create!(user: self, space: space, role: :owner)
    end
  end
end
