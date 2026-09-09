# frozen_string_literal: true

# Empty state component for when a section has no content.
#
# Usage:
#   <%= render EmptyStateComponent.new(
#     icon: "🎵",
#     title: "No Epics yet",
#     message: "Create your first Epic to get started",
#     action_text: "Create Epic",
#     action_path: new_epic_path
#   ) %>
#
# All parameters except icon are optional.

class EmptyStateComponent < ViewComponent::Base
  def initialize(icon: nil, title: nil, message: nil, action_text: nil, action_path: nil)
    @icon = icon
    @title = title
    @message = message
    @action_text = action_text
    @action_path = action_path
  end
end
