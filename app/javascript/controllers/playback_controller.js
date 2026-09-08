import { Controller } from "@hotwired/stimulus"

// Stimulus controller para o Spotify Web Playback SDK.
// Toca um Epic (intervalo start_time → end_time de um track).
// Requer Spotify Premium (CLAUDE.md § 7).
export default class extends Controller {
  static values = {
    spotifyUri: String,   // "spotify:track:XXXXX"
    startTime: Number,    // milliseconds
    endTime: Number,      // milliseconds
    tokenUrl: String      // "/api/playback_token"
  }

  static targets = ["status", "button"]

  connect() {
    this.player = null
    this.deviceId = null
    this.playing = false
    this.stopTimer = null
  }

  disconnect() {
    this.cleanup()
  }

  async play() {
    if (this.playing) {
      this.pause()
      return
    }

    this.updateStatus("Loading...")
    this.updateButton("...")

    try {
      // 1. Get fresh token
      const tokenResponse = await fetch(this.tokenUrlValue, {
        headers: { "Accept": "application/json" }
      })
      const tokenData = await tokenResponse.json()

      if (!tokenResponse.ok) {
        this.updateStatus(tokenData.error || "Cannot play")
        this.updateButton("▶ Play")
        return
      }

      const accessToken = tokenData.access_token

      // 2. Initialize SDK if not already done
      if (!this.player) {
        await this.initializePlayer(accessToken)
      }

      // 3. Start playback at start_time
      await this.startPlayback(accessToken)
    } catch (error) {
      this.updateStatus("Playback error")
      this.updateButton("▶ Play")
      console.error("Playback error:", error)
    }
  }

  pause() {
    if (this.player) {
      this.player.pause()
    }
    this.playing = false
    this.clearStopTimer()
    this.updateButton("▶ Play")
    this.updateStatus("Paused")
  }

  // --- Private ---

  async initializePlayer(accessToken) {
    return new Promise((resolve, reject) => {
      // Load SDK script if not already loaded
      if (!window.Spotify) {
        const script = document.createElement("script")
        script.src = "https://sdk.scdn.co/spotify-player.js"
        document.head.appendChild(script)

        window.onSpotifyWebPlaybackSDKReady = () => {
          this.createPlayer(accessToken, resolve, reject)
        }
      } else {
        this.createPlayer(accessToken, resolve, reject)
      }
    })
  }

  createPlayer(accessToken, resolve, reject) {
    this.player = new window.Spotify.Player({
      name: "Pick Up Your Epic!",
      getOAuthToken: (cb) => {
        // Refresh token on demand
        fetch(this.tokenUrlValue, { headers: { "Accept": "application/json" } })
          .then(r => r.json())
          .then(data => cb(data.access_token))
          .catch(() => cb(accessToken))
      },
      volume: 0.8
    })

    this.player.addListener("ready", ({ device_id }) => {
      this.deviceId = device_id
      resolve()
    })

    this.player.addListener("not_ready", () => {
      this.updateStatus("Device not ready")
      reject(new Error("Device not ready"))
    })

    this.player.addListener("player_state_changed", (state) => {
      if (!state) return

      if (state.paused && this.playing) {
        this.playing = false
        this.clearStopTimer()
        this.updateButton("▶ Play")
        this.updateStatus("Stopped")
      }
    })

    this.player.connect()
  }

  async startPlayback(accessToken) {
    // PUT /v1/me/player/play com device_id, uris, position_ms
    const response = await fetch(`https://api.spotify.com/v1/me/player/play?device_id=${this.deviceId}`, {
      method: "PUT",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        uris: [this.spotifyUriValue],
        position_ms: this.startTimeValue
      })
    })

    if (!response.ok) {
      const text = await response.text()
      console.error("Spotify play error:", text)
      this.updateStatus("Cannot play")
      this.updateButton("▶ Play")
      return
    }

    this.playing = true
    this.updateButton("⏸ Pause")
    this.updateStatus("Playing...")

    // Auto-stop at end_time
    const duration = this.endTimeValue - this.startTimeValue
    this.clearStopTimer()
    this.stopTimer = setTimeout(() => {
      this.pause()
      this.updateStatus("Epic finished")
    }, duration)
  }

  clearStopTimer() {
    if (this.stopTimer) {
      clearTimeout(this.stopTimer)
      this.stopTimer = null
    }
  }

  cleanup() {
    this.clearStopTimer()
    if (this.player) {
      this.player.disconnect()
      this.player = null
    }
  }

  updateStatus(text) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = text
    }
  }

  updateButton(text) {
    if (this.hasButtonTarget) {
      this.buttonTarget.textContent = text
    }
  }
}
