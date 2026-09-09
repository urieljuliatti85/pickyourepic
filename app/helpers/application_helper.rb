module ApplicationHelper
  # Tempos vivem em ms no dominio; mm:ss existe so na view
  # (CLAUDE.md § Domain rules and where they are enforced).
  def formatted_duration(milliseconds)
    return "--:--" if milliseconds.blank?

    total_seconds = milliseconds.to_i / 1000
    format("%d:%02d", total_seconds / 60, total_seconds % 60)
  end

  # Ids dos Epics que o usuario logado pickou, carregados uma vez por request.
  #
  # shared/_pick_button aparece uma vez por Epic na lista; um `exists?` por
  # botao seria uma query por linha (CLAUDE.md § Testing — o profile tem teste
  # de N+1). Um unico pluck resolve todas as linhas da pagina.
  def picked_epic_ids
    return @picked_epic_ids if defined?(@picked_epic_ids)

    @picked_epic_ids = current_user ? current_user.picks.pluck(:epic_id).to_set : Set.new
  end
end
