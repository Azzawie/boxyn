class SpaceMembership < ApplicationRecord
  belongs_to :user
  belongs_to :space

  enum :role, { member: 0, admin: 1, owner: 2 }

  validates :user_id, uniqueness: { scope: :space_id }
end
