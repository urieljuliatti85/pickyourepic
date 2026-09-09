# frozen_string_literal: true

# Toast notification component for transient user feedback.
#
# Usage:
#   <%= render ToastComponent.new(type: :success, message: "Epic picked!") %>
#
# Types: :success (green), :error (red), :info (blue)
# The component auto-dismisses after 4 seconds unless closed manually.
#
# Rendered via turbo_stream in controller responses:
#   <%= turbo_stream.append "toasts-container" do %>
#     <%= render ToastComponent.new(type: :success, message: "Picked!") %>
#   <% end %>

class ToastComponent < ViewComponent::Base
  def initialize(type:, message:)
    @type = type.to_sym
    @message = message
  end

  private

  # Toasts are appended to a shared container, so each needs an id of its own —
  # the Stimulus controller removes the element it is attached to, and two of
  # them sharing an id would make that ambiguous.
  #
  # Rails' dom_id cannot supply it: it expects an Active Record, and calls
  # `to_key` on whatever it is given.
  def toast_id
    @toast_id ||= "toast_#{SecureRandom.hex(6)}"
  end

  def color_classes
    case @type
    when :success
      "bg-emerald-950 border-emerald-700 text-emerald-200"
    when :error
      "bg-red-950 border-red-700 text-red-200"
    when :info
      "bg-blue-950 border-blue-700 text-blue-200"
    else
      "bg-neutral-900 border-neutral-700 text-neutral-200"
    end
  end

  def icon
    case @type
    when :success
      "✓"
    when :error
      "✕"
    when :info
      "ⓘ"
    else
      "•"
    end
  end
end
