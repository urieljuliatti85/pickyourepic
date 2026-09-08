# Um Epic representa um intervalo específico de uma Track (CLAUDE.md § 2).
# O Epic NÃO contém áudio.
class Epic < ApplicationRecord
  belongs_to :user
  belongs_to :track
  has_many :picks, dependent: :destroy
  has_many :collection_epics, dependent: :destroy

  enum :visibility, { public: 0, private: 1 }, prefix: :visibility

  # Validações conforme CLAUDE.md § 6 (Domain Rules)
  validates :title, presence: true, length: { minimum: 1, maximum: 255 }
  validates :start_time, :end_time, presence: true, numericality: { only_integer: true }
  validates :start_time, numericality: { greater_than_or_equal_to: 0 }
  validate :end_time_greater_than_start_time
  validate :end_time_within_track_duration

  private

  # end_time > start_time (conforme Domain Rules)
  def end_time_greater_than_start_time
    if start_time.present? && end_time.present? && end_time <= start_time
      errors.add(:end_time, "must be greater than start_time")
    end
  end

  # end_time <= track duration when known (conforme Domain Rules)
  def end_time_within_track_duration
    if end_time.present? && track && track.duration_ms && end_time > track.duration_ms
      errors.add(:end_time, "exceeds track duration")
    end
  end
end
