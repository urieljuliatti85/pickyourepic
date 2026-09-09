# An Epic is a specific interval of a Track (CLAUDE.md § Product — Core concepts).
# An Epic holds NO audio.
class Epic < ApplicationRecord
  belongs_to :user
  belongs_to :track
  has_many :picks, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :collection_epics, dependent: :destroy

  enum :visibility, { public: 0, private: 1 }, prefix: :visibility

  # Validations per CLAUDE.md § Domain rules and where they are enforced
  validates :title, presence: true, length: { minimum: 1, maximum: 255 }
  # `unless ..._input_invalid?`: when the MM:SS text does not parse, the numeric
  # field is left nil and these validations would stack "can't be blank" and "is
  # not a number" on top of the format message, the only actionable one.
  validates :start_time, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 },
    unless: :start_time_input_invalid?
  validates :end_time, presence: true, numericality: { only_integer: true },
    unless: :end_time_input_invalid?
  validate :end_time_greater_than_start_time
  validate :end_time_within_track_duration
  validate :validate_mmss_format

  # Epics `user` may put in a Collection: their own (public or private) and
  # anyone's public ones. Mirrors the CollectionEpic validation
  # (CLAUDE.md § Authorization) — without it the search would offer Epics that
  # the save then refuses.
  scope :addable_by, ->(user) {
    where(visibility: :public).or(where(user_id: user.id))
  }

  # Search by Epic title, track name or artist. ILIKE because search should not
  # depend on case; the value goes through a bind, so there is no injection.
  scope :matching, ->(term) {
    next all if term.blank?

    pattern = "%#{sanitize_sql_like(term.to_s.strip)}%"
    joins(:track).where(
      "epics.title ILIKE :q OR tracks.name ILIKE :q OR tracks.artist_name ILIKE :q",
      q: pattern
    )
  }

  # The form speaks MM:SS (like a player), but the columns are milliseconds
  # (CLAUDE.md §4). The conversion lives here so the form reads and writes the
  # same unit.
  #
  # The raw text typed is kept in @..._input: an invalid one leaves no number to
  # convert, and without the original the field would come back empty on
  # re-render, hiding from the user what they had typed.
  def start_time_mmss = @start_time_input || ms_to_mmss(start_time)
  def end_time_mmss   = @end_time_input   || ms_to_mmss(end_time)

  def start_time_mmss=(value)
    @start_time_input = value
    self.start_time = mmss_to_ms(value)
  end

  def end_time_mmss=(value)
    @end_time_input = value
    self.end_time = mmss_to_ms(value)
  end

  private

  # Accepted format: MM:SS or M:SS, seconds < 60. A fractional second
  # ("1:30.5") passes, so a pasted timestamp does not lose precision.
  MMSS_MESSAGE = "must be in MM:SS format (e.g. 1:30)".freeze
  MMSS = /\A(\d+):([0-5]?\d(?:\.\d+)?)\z/

  def ms_to_mmss(ms)
    return nil if ms.nil?

    total = ms / 1000.0
    seconds = total % 60
    # No decimal when exact: "1:30", not "1:30.0".
    seconds = seconds == seconds.to_i ? seconds.to_i.to_s.rjust(2, "0") : format("%05.2f", seconds)
    "#{(total / 60).to_i}:#{seconds}"
  end

  def mmss_to_ms(value)
    return nil if value.blank?

    match = MMSS.match(value.to_s.strip)
    return nil unless match

    ((match[1].to_i * 60 + match[2].to_f) * 1000).round
  end

  # Invalid text lands as nil in the numeric field, and "can't be blank" would
  # not tell the user what the real problem is.
  def validate_mmss_format
    errors.add(:start_time, MMSS_MESSAGE) if start_time_input_invalid?
    errors.add(:end_time, MMSS_MESSAGE) if end_time_input_invalid?
  end

  def start_time_input_invalid? = mmss_input_invalid?(@start_time_input)
  def end_time_input_invalid?   = mmss_input_invalid?(@end_time_input)

  def mmss_input_invalid?(input)
    input.present? && !MMSS.match?(input.to_s.strip)
  end

  # end_time > start_time (per Domain Rules)
  def end_time_greater_than_start_time
    if start_time.present? && end_time.present? && end_time <= start_time
      errors.add(:end_time, "must be greater than start_time")
    end
  end

  # end_time <= track duration when known (per Domain Rules)
  def end_time_within_track_duration
    if end_time.present? && track && track.duration_ms && end_time > track.duration_ms
      errors.add(:end_time, "exceeds track duration")
    end
  end
end
