# frozen_string_literal: true

require "test_helper"

class SkeletonComponentTest < ViewComponent::TestCase
  test "renders single skeleton by default" do
    component = SkeletonComponent.new
    render_inline(component)

    assert_selector "[data-testid='skeleton-card-0']"
    assert_no_selector "[data-testid='skeleton-card-1']"
  end

  test "renders multiple skeletons" do
    component = SkeletonComponent.new(count: 4)
    render_inline(component)

    assert_selector "[data-testid='skeleton-card-0']"
    assert_selector "[data-testid='skeleton-card-3']"
    assert_no_selector "[data-testid='skeleton-card-4']"
  end

  test "renders card type skeleton" do
    component = SkeletonComponent.new(type: :card)
    render_inline(component)

    assert_selector ".w-56.aspect-square"
    assert_selector ".animate-shimmer"
  end

  test "renders row type skeleton" do
    component = SkeletonComponent.new(type: :row)
    render_inline(component)

    assert_selector ".h-16.w-full"
  end

  test "renders hero type skeleton" do
    component = SkeletonComponent.new(type: :hero)
    render_inline(component)

    assert_selector ".h-64.w-full.rounded-3xl"
  end

  test "renders mini type skeleton" do
    component = SkeletonComponent.new(type: :mini)
    render_inline(component)

    assert_selector ".h-8.w-8.rounded-full"
  end

  test "has accessibility attributes" do
    component = SkeletonComponent.new
    render_inline(component)

    assert_selector "[aria-hidden='true']"
  end

  test "has shimmer animation" do
    component = SkeletonComponent.new
    render_inline(component)

    assert_selector ".animate-shimmer"
  end
end
