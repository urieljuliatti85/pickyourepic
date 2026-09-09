import { Controller } from "@hotwired/stimulus"

// Barra de player global (CLAUDE.md § Architecture — Playback).
//
// Os players antigos viviam dentro da pagina: sair dela destruia o controller,
// e com ele o device do SDK, entao o som parava. Este vive no layout, dentro de
// um turbo-frame permanent, e sobrevive a navegacao — o Turbo reaproveita o
// mesmo elemento em vez de recria-lo.
//
// Uma pagina nao instancia mais o SDK: ela so despacha o evento
// `epic:play` e esta barra toca. Ver shared/_epic_play_button.
export default class extends Controller {
  static targets = ["title", "subtitle", "button", "elapsed", "total", "progress"]
  static values = { tokenUrl: String }

  connect() {
    this.player = null
    this.deviceId = null
    this.playing = false
    this.current = null
    this.stopTimer = null
    this.tickTimer = null

    // A pagina inteira fala com a barra por este evento.
    this.onRequest = (event) => this.playEpic(event.detail)
    document.addEventListener("epic:play", this.onRequest)
  }

  disconnect() {
    document.removeEventListener("epic:play", this.onRequest)
    this.clearTimers()
    if (this.player) this.player.disconnect()
  }

  // --- API da barra ---

  async playEpic({ uri, startTime, endTime, title, subtitle }) {
    // Clicar de novo no Epic que ja toca alterna play/pause.
    if (this.playing && this.current && this.current.uri === uri &&
        this.current.startTime === startTime) {
      this.pause()
      return
    }

    this.current = { uri, startTime, endTime, title, subtitle }
    this.render({ title, subtitle, status: "Carregando…" })

    try {
      const token = await this.fetchToken()
      if (!token) return

      if (!this.player) await this.initializePlayer(token)
      await this.startPlayback(token)
    } catch (error) {
      this.render({ status: "Erro na reprodução" })
      console.error("Playback error:", error)
    }
  }

  toggle() {
    if (!this.current) return
    if (this.playing) {
      this.pause()
    } else {
      this.playEpic(this.current)
    }
  }

  pause() {
    if (this.player) this.player.pause()
    this.playing = false
    this.clearTimers()
    this.setButton("▶")
  }

  // --- Privado ---

  async fetchToken() {
    const response = await fetch(this.tokenUrlValue, { headers: { Accept: "application/json" } })
    const data = await response.json()

    if (!response.ok) {
      // 403 aqui e o caso normal de conta sem Premium.
      this.render({ status: data.error || "Não foi possível tocar" })
      return null
    }
    return data.access_token
  }

  initializePlayer(accessToken) {
    return new Promise((resolve, reject) => {
      if (window.Spotify) return this.createPlayer(accessToken, resolve, reject)

      // O callback TEM que existir antes do script entrar no DOM: o SDK o
      // invoca assim que carrega, e com o script em cache isso acontece antes
      // da linha seguinte rodar — a barra ficava presa em "Carregando…" para
      // sempre porque ninguem chamava createPlayer.
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
      volume: 0.8
    })

    this.player.addListener("ready", ({ device_id }) => {
      this.deviceId = device_id
      resolve()
    })

    // `not_ready` tambem dispara depois, quando o device sai do ar. Rejeitar
    // uma promise ja resolvida nao faz nada, mas zerar o deviceId garante que
    // o proximo play reconecte em vez de tocar num device morto.
    this.player.addListener("not_ready", () => {
      this.deviceId = null
      reject(new Error("Device not ready"))
    })

    // Sem estes listeners uma falha de auth/conta ficava silenciosa e a barra
    // parecia apenas "travada".
    this.player.addListener("initialization_error", ({ message }) => reject(new Error(message)))
    this.player.addListener("authentication_error", ({ message }) => reject(new Error(message)))
    this.player.addListener("account_error", ({ message }) => reject(new Error(message)))
    this.player.addListener("player_state_changed", (state) => {
      if (state && state.paused && this.playing) {
        this.playing = false
        this.clearTimers()
        this.setButton("▶")
      }
    })

    this.player.connect()
  }

  async startPlayback(accessToken) {
    const { uri, startTime, endTime } = this.current

    const response = await fetch(
      `https://api.spotify.com/v1/me/player/play?device_id=${this.deviceId}`,
      {
        method: "PUT",
        headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
        body: JSON.stringify({ uris: [uri], position_ms: startTime })
      }
    )

    if (!response.ok) {
      this.render({ status: "Não foi possível tocar" })
      return
    }

    this.playing = true
    this.setButton("⏸")

    // O Epic e um trecho: para sozinho no end_time.
    const duration = endTime - startTime
    this.clearTimers()
    this.stopTimer = setTimeout(() => {
      this.pause()
      this.render({ status: "Epic terminou" })
    }, duration)

    this.startedAt = Date.now()
    this.tick(duration)
    this.tickTimer = setInterval(() => this.tick(duration), 500)
  }

  tick(duration) {
    const elapsed = Math.min(Date.now() - this.startedAt, duration)
    if (this.hasElapsedTarget) this.elapsedTarget.textContent = this.format(elapsed)
    if (this.hasTotalTarget) this.totalTarget.textContent = this.format(duration)
    if (this.hasProgressTarget) {
      this.progressTarget.style.width = `${(elapsed / duration) * 100}%`
    }
  }

  format(ms) {
    const total = Math.floor(ms / 1000)
    return `${Math.floor(total / 60)}:${String(total % 60).padStart(2, "0")}`
  }

  render({ title, subtitle, status }) {
    if (title && this.hasTitleTarget) this.titleTarget.textContent = title
    if (this.hasSubtitleTarget) {
      if (status) this.subtitleTarget.textContent = status
      else if (subtitle) this.subtitleTarget.textContent = subtitle
    }
    this.element.classList.remove("hidden")
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
