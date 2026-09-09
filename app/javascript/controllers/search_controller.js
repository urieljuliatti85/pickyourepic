import { Controller } from "@hotwired/stimulus"

// Submits the search form as the person types.
//
// The debounce exists because without it every keystroke fires a request: a
// twelve-letter search would be twelve round trips, and the answers can arrive
// out of order — the list would end up showing the result of an older term.
export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } }

  submit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
