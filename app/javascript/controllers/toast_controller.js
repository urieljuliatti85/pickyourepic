import { Controller } from "@hotwired/stimulus"

// Toast notification controller
// - Auto-dismisses after duration (configurable)
// - Handles manual dismiss via button click
// - Adds fade-out animation before removal
export default class extends Controller {
  static values = {
    autoDismiss: Boolean,
    duration: Number
  }

  connect() {
    if (this.autoDismissValue) {
      this.timeout = setTimeout(() => this.dismiss(), this.durationValue)
    }
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.classList.add("animate-toast-out")
    setTimeout(() => this.element.remove(), 300)
  }
}
