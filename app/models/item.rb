class Item < ApplicationRecord
  belongs_to :box
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings
  has_many_attached :photos

  validates :name, presence: true

  scope :search, ->(query) {
    where("search_vector @@ plainto_tsquery('english', ?)", query)
      .order(Arel.sql("ts_rank(search_vector, plainto_tsquery('english', #{connection.quote(query)})) DESC"))
  }
end
