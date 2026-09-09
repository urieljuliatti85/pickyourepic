# frozen_string_literal: true

require "test_helper"

class EmptyStateComponentTest < ViewComponent::TestCase
  # A component test is not a controller test, so the route helpers are not
  # there by default — and this component takes a path.
  #
  # Delegated rather than included: `include url_helpers` also brings
  # `test_session_path`, and Minitest collects every method starting with
  # `test_` as a test case, so the helper itself would be run as one and fail
  # for want of its :user_id.
  def method_missing(name, *args, &block)
    if name.to_s.end_with?("_path", "_url")
      Rails.application.routes.url_helpers.public_send(name, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    name.to_s.end_with?("_path", "_url") || super
  end

  test "renders with icon and title" do
    component = EmptyStateComponent.new(
      icon: "🎵",
      title: "No Epics yet"
    )
    render_inline(component)

    assert_text "🎵"
    assert_text "No Epics yet"
  end

  test "renders with all parameters" do
    component = EmptyStateComponent.new(
      icon: "⭐",
      title: "No favorites",
      message: "Save your favorite moments",
      action_text: "Discover",
      action_path: discover_path
    )
    render_inline(component)

    assert_text "⭐"
    assert_text "No favorites"
    assert_text "Save your favorite moments"
    assert_link "Discover", href: discover_path
  end

  test "renders without optional parameters" do
    component = EmptyStateComponent.new(icon: "📚")
    render_inline(component)

    assert_text "📚"
    assert_no_link
  end

  test "has proper styling" do
    component = EmptyStateComponent.new(
      icon: "🎵",
      title: "Test"
    )
    render_inline(component)

    assert_selector ".rounded-3xl"
    assert_selector ".bg-ink-soft"
    # Tailwind's opacity slash is not a valid CSS selector — Nokogiri reads the
    # "/" as a child combinator — so this class is matched on the attribute.
    assert_selector "[class~='border-white/10']"
  end

  test "action link has correct styling" do
    component = EmptyStateComponent.new(
      action_text: "Create",
      action_path: new_epic_path(track_id: "some_track")
    )
    render_inline(component)

    assert_selector "a.bg-lime-accent"
    assert_selector "a.text-neutral-950"
  end
end
