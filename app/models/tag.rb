class Tag < ApplicationRecord
  belongs_to :space
  has_many :taggings, dependent: :destroy
  has_many :items, through: :taggings

  validates :name, presence: true
  validates :name, uniqueness: { scope: :space_id, case_sensitive: false }
end
