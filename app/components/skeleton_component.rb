# frozen_string_literal: true

# Skeleton/placeholder component for loading states.
# Shows a shimmer animation while content loads.
#
# Usage:
#   <%= render SkeletonComponent.new(type: :card, count: 3) %>
#   <%= render SkeletonComponent.new(type: :row) %>
#   <%= render SkeletonComponent.new(type: :hero) %>
#
# Types:
#   - :card — Square placeholder (for collection/epic cards)
#   - :row — Horizontal placeholder (for epic rows)
#   - :hero — Large hero placeholder (for featured epic)
#   - :mini — Tiny placeholder (for avatars, badges)

class SkeletonComponent < ViewComponent::Base
  def initialize(type: :card, count: 1)
    @type = type.to_sym
    @count = count
  end

  private

  def skeleton_classes
    base = "rounded-lg bg-gradient-to-r from-neutral-700 via-neutral-600 to-neutral-700 bg-[length:1000px_100%] animate-shimmer"

    case @type
    when :card
      "#{base} aspect-square w-56"
    when :row
      "#{base} h-16 w-full"
    when :hero
      "#{base} h-64 w-full rounded-3xl"
    when :mini
      "#{base} h-8 w-8 rounded-full"
    else
      "#{base} h-12 w-full"
    end
  end
end
