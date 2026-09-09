# frozen_string_literal: true

require "test_helper"

class ToastComponentTest < ViewComponent::TestCase
  test "renders success toast" do
    component = ToastComponent.new(type: :success, message: "Test success")
    render_inline(component)

    assert_text "✓"
    assert_text "Test success"
    assert_selector ".bg-emerald-950"
  end

  test "renders error toast" do
    component = ToastComponent.new(type: :error, message: "Test error")
    render_inline(component)

    assert_text "✕"
    assert_text "Test error"
    assert_selector ".bg-red-950"
  end

  test "renders info toast" do
    component = ToastComponent.new(type: :info, message: "Test info")
    render_inline(component)

    assert_text "ⓘ"
    assert_text "Test info"
    assert_selector ".bg-blue-950"
  end

  test "includes dismiss button" do
    component = ToastComponent.new(type: :success, message: "Test")
    render_inline(component)

    assert_selector "button[aria-label='Dismiss']"
  end

  test "has accessibility attributes" do
    component = ToastComponent.new(type: :success, message: "Test")
    render_inline(component)

    assert_selector "[role='alert']"
    assert_selector "[aria-live='polite']"
  end

  test "includes toast controller" do
    component = ToastComponent.new(type: :success, message: "Test")
    render_inline(component)

    assert_selector "[data-controller='toast']"
    assert_selector "[data-toast-auto-dismiss-value='true']"
    assert_selector "[data-toast-duration-value='4000']"
  end
end
