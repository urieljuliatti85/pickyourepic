module ApplicationHelper
  # Times live in ms in the domain; mm:ss exists only in the view
  # (CLAUDE.md § Domain rules and where they are enforced).
  def formatted_duration(milliseconds)
    return "--:--" if milliseconds.blank?

    total_seconds = milliseconds.to_i / 1000
    format("%d:%02d", total_seconds / 60, total_seconds % 60)
  end

  # Ids of the Epics the signed-in user picked, loaded once per request.
  #
  # shared/_pick_button appears once per Epic in a list; an `exists?` per button
  # would be one query per row (CLAUDE.md § Testing — the profile has an N+1
  # test). A single pluck answers every row on the page.
  def picked_epic_ids
    return @picked_epic_ids if defined?(@picked_epic_ids)

    @picked_epic_ids = current_user ? current_user.picks.pluck(:epic_id).to_set : Set.new
  end
end
