# Metadados e referencia a uma musica do Spotify. Nunca audio
# (CLAUDE.md § Spotify policy constraints).
class Track < ApplicationRecord
  has_many :epics, dependent: :destroy

  validates :spotify_id, presence: true, uniqueness: true
  validates :name, :artist_name, presence: true
  validates :duration_ms, numericality: { only_integer: true, greater_than: 0 }

  # Uma musica existe uma unica vez no banco. A corrida entre duas buscas
  # simultaneas pela mesma faixa e resolvida pelo indice unico, nao pelo find.
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
