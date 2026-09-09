# Um Epic representa um intervalo específico de uma Track (CLAUDE.md § Product — Core concepts).
# O Epic NÃO contém áudio.
class Epic < ApplicationRecord
  belongs_to :user
  belongs_to :track
  has_many :picks, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :collection_epics, dependent: :destroy

  enum :visibility, { public: 0, private: 1 }, prefix: :visibility

  # Validações conforme CLAUDE.md § Domain rules and where they are enforced
  validates :title, presence: true, length: { minimum: 1, maximum: 255 }
  # `unless ..._input_invalid?`: quando o texto MM:SS nao parseia, o campo
  # numerico fica nil e estas validacoes empilhariam "can't be blank" e "is not
  # a number" sobre a mensagem de formato, que e a unica acionavel.
  validates :start_time, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 },
    unless: :start_time_input_invalid?
  validates :end_time, presence: true, numericality: { only_integer: true },
    unless: :end_time_input_invalid?
  validate :end_time_greater_than_start_time
  validate :end_time_within_track_duration
  validate :validate_mmss_format

  # Epics que `user` pode colocar numa Collection: os proprios (publicos ou
  # privados) e os publicos de qualquer um. Espelha a validacao de
  # CollectionEpic (CLAUDE.md § Authorization) — sem isso a busca ofereceria
  # Epics que o save recusaria depois.
  scope :addable_by, ->(user) {
    where(visibility: :public).or(where(user_id: user.id))
  }

  # Busca por titulo do Epic, nome da faixa ou artista. ILIKE porque a busca
  # nao deve depender de caixa; o valor vai por bind, entao nao ha injecao.
  scope :matching, ->(term) {
    next all if term.blank?

    pattern = "%#{sanitize_sql_like(term.to_s.strip)}%"
    joins(:track).where(
      "epics.title ILIKE :q OR tracks.name ILIKE :q OR tracks.artist_name ILIKE :q",
      q: pattern
    )
  }

  # O formulario fala em MM:SS (como um player), mas as colunas sao
  # milissegundos (CLAUDE.md §4). A conversao vive aqui para que o form leia e
  # escreva a mesma unidade.
  #
  # O texto cru digitado e preservado em @..._input: se for invalido nao ha
  # numero para converter, e sem guardar o original o campo voltaria vazio no
  # re-render, escondendo do usuario o que ele havia digitado.
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

  # Formato aceito: MM:SS ou M:SS, com segundos < 60. Fracao de segundo
  # ("1:30.5") passa, para nao perder precisao de quem cola um timestamp.
  MMSS_MESSAGE = "must be in MM:SS format (e.g. 1:30)".freeze
  MMSS = /\A(\d+):([0-5]?\d(?:\.\d+)?)\z/

  def ms_to_mmss(ms)
    return nil if ms.nil?

    total = ms / 1000.0
    seconds = total % 60
    # Sem casa decimal quando exato: "1:30", nao "1:30.0".
    seconds = seconds == seconds.to_i ? seconds.to_i.to_s.rjust(2, "0") : format("%05.2f", seconds)
    "#{(total / 60).to_i}:#{seconds}"
  end

  def mmss_to_ms(value)
    return nil if value.blank?

    match = MMSS.match(value.to_s.strip)
    return nil unless match

    ((match[1].to_i * 60 + match[2].to_f) * 1000).round
  end

  # Um texto invalido vira nil no campo numerico, e "can't be blank" nao diria
  # ao usuario qual e o problema real.
  def validate_mmss_format
    errors.add(:start_time, MMSS_MESSAGE) if start_time_input_invalid?
    errors.add(:end_time, MMSS_MESSAGE) if end_time_input_invalid?
  end

  def start_time_input_invalid? = mmss_input_invalid?(@start_time_input)
  def end_time_input_invalid?   = mmss_input_invalid?(@end_time_input)

  def mmss_input_invalid?(input)
    input.present? && !MMSS.match?(input.to_s.strip)
  end

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
