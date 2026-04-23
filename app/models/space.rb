class Space < ApplicationRecord
  has_many :space_memberships, dependent: :destroy
  has_many :members, through: :space_memberships, source: :user
  has_many :boxes, dependent: :destroy
  has_many :tags, dependent: :destroy

  validates :name, presence: true
end
