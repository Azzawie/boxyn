class Box < ApplicationRecord
  belongs_to :space
  has_many :items, dependent: :destroy
  has_one_attached :qr_code_image

  validates :name, presence: true

  before_create :generate_qr_token

  after_create_commit :enqueue_qr_generation

  private

  def generate_qr_token
    self.qr_token = SecureRandom.uuid
  end

  def enqueue_qr_generation
    GenerateQrCodeJob.perform_later(id)
  end
end
