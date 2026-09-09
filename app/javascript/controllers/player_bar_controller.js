import { Controller } from "@hotwired/stimulus"

// Global player bar (CLAUDE.md § Architecture — Playback).
//
// The old players lived inside the page: leaving it destroyed the controller,
// and with it the SDK device, so the sound stopped. This one lives in the
// layout, inside a permanent turbo-frame, and survives navigation — Turbo
// reuses the same element instead of recreating it.
//
// A page no longer instantiates the SDK: it dispatches `epic:play` (one Epic) or
// `epic:play-queue` (a whole Collection) and this bar plays. See
// shared/_epic_play_button and shared/_collection_player.
export default class extends Controller {
  static targets = [
    "title", "subtitle", "artwork", "button", "prev", "next",
    "elapsed", "total", "progress", "scrubber", "volume", "queuePosition"
  ]
  static values = { tokenUrl: String }

  connect() {
    this.player = null
    this.deviceId = null
    this.playing = false
    this.stopTimer = null
    this.tickTimer = null

    // The queue is always an array; a lone Epic is a queue of one.
    this.queue = []
    this.index = 0
    this.seekOffset = 0
    this.scrubbing = false

    this.onPlay = (event) => this.playQueue([event.detail], 0)
    this.onPlayQueue = (event) => this.playQueue(event.detail.epics, event.detail.startIndex || 0)

    document.addEventListener("epic:play", this.onPlay)
    document.addEventListener("epic:play-queue", this.onPlayQueue)
  }

  disconnect() {
    document.removeEventListener("epic:play", this.onPlay)
    document.removeEventListener("epic:play-queue", this.onPlayQueue)
    this.clearTimers()
    if (this.player) this.player.disconnect()
  }

  // --- The bar's API ---

  async playQueue(epics, startIndex) {
    if (!epics || epics.length === 0) return

    const sameQueue = this.queue.length === epics.length &&
      this.queue.every((e, i) => e.uri === epics[i].uri && e.startTime === epics[i].startTime)

    // Clicking again on what is already playing toggles play/pause instead of restarting.
    if (sameQueue && this.index === startIndex && this.playing) {
      this.pause()
      return
    }

    this.queue = epics
    this.index = startIndex
    await this.playCurrent()
  }

  toggle() {
    if (this.queue.length === 0) return

    if (this.playing) {
      this.pause()
    } else {
      // Resumes where it stopped, not from the start of the excerpt.
      this.playCurrent({ from: this.elapsedMs() })
    }
  }

  next() {
    if (this.index >= this.queue.length - 1) return
    this.index += 1
    this.playCurrent()
  }

  previous() {
    // As in a music player: after a few seconds "previous" restarts the current
    // excerpt instead of jumping to the one behind.
    if (this.elapsedMs() > 3000 || this.index === 0) {
      this.playCurrent()
      return
    }
    this.index -= 1
    this.playCurrent()
  }

  // The range fires input while dragging and change on release: moving the thumb
  // only updates the label, and the real seek goes out once, at the end.
  scrubbing_start() {
    this.scrubbing = true
  }

  scrub(event) {
    this.scrubbing = true
    const target = this.current()
    if (!target || !this.hasElapsedTarget) return
    const ms = (event.target.value / 100) * this.duration()
    this.elapsedTarget.textContent = this.format(ms)
  }

  seek(event) {
    this.scrubbing = false
    if (!this.current()) return
    this.playCurrent({ from: (event.target.value / 100) * this.duration() })
  }

  setVolume(event) {
    if (this.player) this.player.setVolume(event.target.value / 100)
  }

  pause() {
    if (this.player) this.player.pause()
    this.playing = false
    this.pausedAt = this.elapsedMs()
    this.clearTimers()
    this.setButton("▶")
  }

  // --- Private ---

  current() {
    return this.queue[this.index]
  }

  duration() {
    const epic = this.current()
    return epic ? epic.endTime - epic.startTime : 0
  }

  elapsedMs() {
    if (!this.playing) return this.pausedAt || 0
    return Math.min(Date.now() - this.startedAt + this.seekOffset, this.duration())
  }

  async playCurrent({ from = 0 } = {}) {
    const epic = this.current()
    if (!epic) return

    this.seekOffset = from
    this.render({ title: epic.title, subtitle: epic.subtitle, artwork: epic.artwork, status: from ? null : "Loading…" })
    this.renderQueuePosition()

    try {
      const token = await this.fetchToken()
      if (!token) return

      if (!this.player) await this.initializePlayer(token)
      await this.startPlayback(token, from)
    } catch (error) {
      this.render({ status: "Playback error" })
      console.error("Playback error:", error)
    }
  }

  async fetchToken() {
    const response = await fetch(this.tokenUrlValue, { headers: { Accept: "application/json" } })
    const data = await response.json()

    if (!response.ok) {
      // A 403 here is the normal case of an account without Premium.
      this.render({ status: data.error || "Could not play" })
      return null
    }
    return data.access_token
  }

  initializePlayer(accessToken) {
    return new Promise((resolve, reject) => {
      if (window.Spotify) return this.createPlayer(accessToken, resolve, reject)

      // The callback MUST exist before the script enters the DOM: the SDK invokes
      // it as soon as it loads, and with the script cached that happens before the
      // next line runs — the bar stayed stuck on "Loading…" forever because
      // nobody called createPlayer.
      window.onSpotifyWebPlaybackSDKReady = () => this.createPlayer(accessToken, resolve, reject)

      const script = document.createElement("script")
      script.src = "https://sdk.scdn.co/spotify-player.js"
      script.onerror = () => reject(new Error("Spotify SDK failed to load"))
      document.head.appendChild(script)
    })
  }

  createPlayer(accessToken, resolve, reject) {
    this.player = new window.Spotify.Player({
      name: "Pick Up Your Epic!",
      getOAuthToken: (cb) => {
        fetch(this.tokenUrlValue, { headers: { Accept: "application/json" } })
          .then((r) => r.json())
          .then((data) => cb(data.access_token))
          .catch(() => cb(accessToken))
      },
      volume: this.hasVolumeTarget ? this.volumeTarget.value / 100 : 0.8
    })

    this.player.addListener("ready", ({ device_id }) => {
      this.deviceId = device_id
      resolve()
    })

    // `not_ready` also fires later, when the device goes offline. Rejecting an
    // already-resolved promise does nothing, but clearing deviceId makes sure the
    // next play reconnects instead of playing on a dead device.
    this.player.addListener("not_ready", () => {
      this.deviceId = null
      reject(new Error("Device not ready"))
    })

    // Without these listeners an auth/account failure stayed silent and the bar
    // just looked "stuck".
    this.player.addListener("initialization_error", ({ message }) => reject(new Error(message)))
    this.player.addListener("authentication_error", ({ message }) => reject(new Error(message)))
    this.player.addListener("account_error", ({ message }) => reject(new Error(message)))

    this.player.connect()
  }

  async startPlayback(accessToken, from = 0) {
    const epic = this.current()

    const response = await fetch(
      `https://api.spotify.com/v1/me/player/play?device_id=${this.deviceId}`,
      {
        method: "PUT",
        headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
        body: JSON.stringify({ uris: [epic.uri], position_ms: epic.startTime + from })
      }
    )

    if (!response.ok) {
      this.render({ status: "Could not play" })
      return
    }

    this.playing = true
    this.setButton("⏸")
    this.render({ subtitle: epic.subtitle })

    // An Epic is an excerpt: it stops at end_time. In a queue, the end of one is
    // the start of the next.
    const remaining = this.duration() - from
    this.clearTimers()
    this.stopTimer = setTimeout(() => this.advance(), remaining)

    this.startedAt = Date.now()
    this.tick()
    this.tickTimer = setInterval(() => this.tick(), 250)
  }

  advance() {
    if (this.index < this.queue.length - 1) {
      this.index += 1
      this.playCurrent()
    } else {
      this.pause()
      this.pausedAt = 0
      this.render({ status: this.queue.length > 1 ? "Collection finished" : "Epic finished" })
      this.setProgress(0)
    }
  }

  tick() {
    const elapsed = this.elapsedMs()
    const duration = this.duration()

    if (this.hasElapsedTarget && !this.scrubbing) this.elapsedTarget.textContent = this.format(elapsed)
    if (this.hasTotalTarget) this.totalTarget.textContent = this.format(duration)
    if (!this.scrubbing) this.setProgress(duration ? (elapsed / duration) * 100 : 0)
  }

  setProgress(percent) {
    if (this.hasProgressTarget) this.progressTarget.style.width = `${percent}%`
    if (this.hasScrubberTarget) this.scrubberTarget.value = percent
  }

  format(ms) {
    const total = Math.floor(ms / 1000)
    return `${Math.floor(total / 60)}:${String(total % 60).padStart(2, "0")}`
  }

  render({ title, subtitle, artwork, status }) {
    if (title && this.hasTitleTarget) this.titleTarget.textContent = title
    if (this.hasSubtitleTarget) {
      if (status) this.subtitleTarget.textContent = status
      else if (subtitle) this.subtitleTarget.textContent = subtitle
    }
    if (this.hasArtworkTarget) {
      if (artwork) {
        this.artworkTarget.src = artwork
        this.artworkTarget.hidden = false
      } else {
        this.artworkTarget.hidden = true
      }
    }
    this.element.classList.remove("hidden")
  }

  renderQueuePosition() {
    if (!this.hasQueuePositionTarget) return

    // A lone Epic is not a queue: showing "1/1" would be noise.
    this.queuePositionTarget.textContent =
      this.queue.length > 1 ? `${this.index + 1}/${this.queue.length}` : ""

    if (this.hasPrevTarget) this.prevTarget.disabled = this.queue.length <= 1
    if (this.hasNextTarget) this.nextTarget.disabled = this.index >= this.queue.length - 1
  }

  setButton(label) {
    if (this.hasButtonTarget) this.buttonTarget.textContent = label
  }

  clearTimers() {
    if (this.stopTimer) clearTimeout(this.stopTimer)
    if (this.tickTimer) clearInterval(this.tickTimer)
    this.stopTimer = null
    this.tickTimer = null
  }
}
