class User < ApplicationRecord
  has_one :spotify_account, dependent: :destroy
  has_many :epics, dependent: :destroy
  has_many :picks, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorited_epics, through: :favorites, source: :epic
  has_many :collections, dependent: :destroy

  enum :visibility, { public_profile: 0, private_profile: 1 }, prefix: :visibility

  validates :username, presence: true, length: { maximum: 30 },
    format: { with: /\A[a-zA-Z0-9_]+\z/, message: "only letters, numbers and underscore" },
    uniqueness: { case_sensitive: false }

  def to_param = username
end
