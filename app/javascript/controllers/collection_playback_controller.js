import { Controller } from "@hotwired/stimulus"

// Stimulus controller para reprodução sequencial de uma Collection.
// Toca cada Epic na ordem (position), auto-avançando para o próximo.
// Reutiliza o mesmo Web Playback SDK device.
export default class extends Controller {
  static values = {
    epics: Array,     // [{spotifyUri, startTime, endTime, title}]
    tokenUrl: String  // "/api/playback_token"
  }

  static targets = ["status", "button", "current"]

  connect() {
    this.player = null
    this.deviceId = null
    this.playing = false
    this.currentIndex = 0
    this.stopTimer = null
    this.accessToken = null
  }

  disconnect() {
    this.cleanup()
  }

  async play() {
    if (this.playing) {
      this.pause()
      return
    }

    if (this.epicsValue.length === 0) {
      this.updateStatus("No Epics in collection")
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
        this.updateButton("▶ Play Collection")
        return
      }

      this.accessToken = tokenData.access_token

      // 2. Initialize SDK if not already done
      if (!this.player) {
        await this.initializePlayer(this.accessToken)
      }

      // 3. Start playing from current index
      await this.playEpic(this.currentIndex)
    } catch (error) {
      this.updateStatus("Playback error")
      this.updateButton("▶ Play Collection")
      console.error("Collection playback error:", error)
    }
  }

  pause() {
    if (this.player) {
      this.player.pause()
    }
    this.playing = false
    this.clearStopTimer()
    this.updateButton("▶ Play Collection")
    this.updateStatus("Paused")
  }

  // Skip to next epic
  next() {
    if (this.currentIndex < this.epicsValue.length - 1) {
      this.clearStopTimer()
      this.currentIndex++
      this.playEpic(this.currentIndex)
    }
  }

  // --- Private ---

  async playEpic(index) {
    const epic = this.epicsValue[index]
    if (!epic) {
      this.finishCollection()
      return
    }

    this.currentIndex = index
    this.updateCurrent(`${index + 1}/${this.epicsValue.length}: ${epic.title}`)
    this.updateStatus("Playing...")
    this.updateButton("⏸ Pause")

    // Refresh token if needed
    try {
      const tokenResponse = await fetch(this.tokenUrlValue, {
        headers: { "Accept": "application/json" }
      })
      const tokenData = await tokenResponse.json()
      if (tokenResponse.ok) {
        this.accessToken = tokenData.access_token
      }
    } catch (e) {
      // Use existing token
    }

    const response = await fetch(`https://api.spotify.com/v1/me/player/play?device_id=${this.deviceId}`, {
      method: "PUT",
      headers: {
        "Authorization": `Bearer ${this.accessToken}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        uris: [epic.spotifyUri],
        position_ms: epic.startTime
      })
    })

    if (!response.ok) {
      console.error("Spotify play error for epic:", epic.title)
      this.updateStatus("Cannot play this Epic")
      // Try next
      if (index < this.epicsValue.length - 1) {
        setTimeout(() => this.playEpic(index + 1), 1000)
      }
      return
    }

    this.playing = true

    // Auto-advance to next epic when this one ends
    const duration = epic.endTime - epic.startTime
    this.clearStopTimer()
    this.stopTimer = setTimeout(() => {
      if (index < this.epicsValue.length - 1) {
        this.playEpic(index + 1)
      } else {
        this.finishCollection()
      }
    }, duration)
  }

  finishCollection() {
    if (this.player) {
      this.player.pause()
    }
    this.playing = false
    this.currentIndex = 0
    this.clearStopTimer()
    this.updateButton("▶ Play Collection")
    this.updateStatus("Collection finished!")
    this.updateCurrent("")
  }

  async initializePlayer(accessToken) {
    return new Promise((resolve, reject) => {
      if (!window.Spotify) {
        // O callback antes do appendChild: com o script em cache o SDK dispara
        // onSpotifyWebPlaybackSDKReady antes da atribuicao acontecer, e a
        // promise nunca resolvia.
        window.onSpotifyWebPlaybackSDKReady = () => {
          this.createPlayer(accessToken, resolve, reject)
        }

        const script = document.createElement("script")
        script.src = "https://sdk.scdn.co/spotify-player.js"
        script.onerror = () => reject(new Error("Spotify SDK failed to load"))
        document.head.appendChild(script)
      } else {
        this.createPlayer(accessToken, resolve, reject)
      }
    })
  }

  createPlayer(accessToken, resolve, reject) {
    this.player = new window.Spotify.Player({
      name: "Pick Up Your Epic! Collection",
      getOAuthToken: (cb) => {
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

    this.player.connect()
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
    if (this.hasStatusTarget) this.statusTarget.textContent = text
  }

  updateButton(text) {
    if (this.hasButtonTarget) this.buttonTarget.textContent = text
  }

  updateCurrent(text) {
    if (this.hasCurrentTarget) this.currentTarget.textContent = text
  }
}
