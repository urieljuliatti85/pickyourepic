import { Controller } from "@hotwired/stimulus"

// An Epic's play button. It plays nothing itself: it asks the global bar to
// play (player_bar_controller), which is what holds the SDK device.
//
// An Epic is an interval of a track, so the event carries start/end.
export default class extends Controller {
  static values = {
    uri: String,
    startTime: Number,
    endTime: Number,
    title: String,
    subtitle: String,
    artwork: String,
    queue: Array
  }

  play() {
    document.dispatchEvent(new CustomEvent("epic:play", {
      detail: {
        uri: this.uriValue,
        startTime: this.startTimeValue,
        endTime: this.endTimeValue,
        title: this.titleValue,
        subtitle: this.subtitleValue,
        artwork: this.artworkValue
      }
    }))
  }

  // A whole Collection: the bar plays in sequence and advances on its own.
  playQueue() {
    document.dispatchEvent(new CustomEvent("epic:play-queue", {
      detail: { epics: this.queueValue, startIndex: 0 }
    }))
  }
}
