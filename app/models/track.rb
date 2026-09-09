# Metadata and a reference to a Spotify song. Never audio
# (CLAUDE.md § Spotify policy constraints).
class Track < ApplicationRecord
  has_many :epics, dependent: :destroy

  validates :spotify_id, presence: true, uniqueness: true
  validates :name, :artist_name, presence: true
  validates :duration_ms, numericality: { only_integer: true, greater_than: 0 }

  # A song exists once in the database. The race between two concurrent searches
  # for the same track is settled by the unique index, not by the find.
  def self.upsert_from_spotify!(attributes)
    spotify_id = attributes.fetch(:spotify_id)

    track = find_or_initialize_by(spotify_id: spotify_id)
    track.assign_attributes(attributes)
    track.save!
    track
  rescue ActiveRecord::RecordNotUnique
    find_by!(spotify_id: spotify_id)
  end

  def to_param = spotify_id
end
