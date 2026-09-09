# frozen_string_literal: true

module ErrorMessagesHelper
  # User-friendly error messages for validation failures.
  # Maps error keys to descriptive messages with context.
  #
  # Usage:
  #   <%= friendly_error(:cannot_pick_private_epic) %>
  #   → "🔒 Can't pick private Epics"

  FRIENDLY_ERRORS = {
    # Pick errors
    cannot_pick_private_epic: {
      title: "🔒 Can't pick private Epics",
      message: "Only public Epics can be picked. Ask the creator to make it public."
    },
    cannot_pick_own_epic: {
      title: "🎯 Can't pick your own Epic",
      message: "Picking is for moments created by others. Try picking from Discover!"
    },
    pick_already_exists: {
      title: "💫 Already picked!",
      message: "You've already picked this Epic. Unpick if you change your mind."
    },

    # Favorite errors
    cannot_favorite_private_epic_from_another_user: {
      title: "🔒 Can't favorite this Epic",
      message: "It's private and belongs to another user. Only your own Epics can be favorited privately."
    },
    favorite_already_exists: {
      title: "⭐ Already favorited!",
      message: "You've already saved this to your favorites. Remove it if needed."
    },

    # Collection errors
    cannot_add_private_epic_from_another_user: {
      title: "🔒 Can't add to collection",
      message: "This Epic is private and belongs to another user. Only add public Epics to collections."
    },
    collection_epic_already_exists: {
      title: "🔁 Already in collection",
      message: "This Epic is already part of this collection."
    },

    # Epic creation errors
    invalid_mmss_format: {
      title: "⏱️ Invalid time format",
      message: "Use MM:SS format (e.g., 01:30). Minutes and seconds separated by a colon."
    },
    end_time_before_start: {
      title: "▶️ End time must be after start",
      message: "The Epic must end after it begins. Check your times."
    },
    end_time_exceeds_duration: {
      title: "📍 End time exceeds track length",
      message: "The Epic ends after the track does. Shorten the end time."
    },
    epic_title_missing: {
      title: "📝 Epic needs a title",
      message: "Give your Epic a short, memorable name."
    }
  }.freeze

  def friendly_error(error_key)
    error_data = FRIENDLY_ERRORS[error_key.to_sym]
    return error_key.to_s if error_data.nil?

    error_data[:title]
  end

  def friendly_error_message(error_key)
    error_data = FRIENDLY_ERRORS[error_key.to_sym]
    return nil if error_data.nil?

    error_data[:message]
  end

  def error_icon(error_key)
    title = friendly_error(error_key)
    title.split(" ").first # Extract emoji from "🔒 Can't pick..."
  end
end
