module ApplicationHelper
  # Tempos vivem em ms no dominio; mm:ss existe so na view (CLAUDE.md §6).
  def formatted_duration(milliseconds)
    return "--:--" if milliseconds.blank?

    total_seconds = milliseconds.to_i / 1000
    format("%d:%02d", total_seconds / 60, total_seconds % 60)
  end
end
