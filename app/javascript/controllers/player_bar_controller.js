import { Controller } from "@hotwired/stimulus"

// Barra de player global (CLAUDE.md § Architecture — Playback).
//
// Os players antigos viviam dentro da pagina: sair dela destruia o controller,
// e com ele o device do SDK, entao o som parava. Este vive no layout, dentro de
// um turbo-frame permanent, e sobrevive a navegacao — o Turbo reaproveita o
// mesmo elemento em vez de recria-lo.
//
// Uma pagina nao instancia mais o SDK: ela despacha `epic:play` (um Epic) ou
// `epic:play-queue` (uma Collection inteira) e esta barra toca. Ver
// shared/_epic_play_button e shared/_collection_player.
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

    // A fila e sempre um array; um Epic avulso e uma fila de um.
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

  // --- API da barra ---

  async playQueue(epics, startIndex) {
    if (!epics || epics.length === 0) return

    const sameQueue = this.queue.length === epics.length &&
      this.queue.every((e, i) => e.uri === epics[i].uri && e.startTime === epics[i].startTime)

    // Reclicar no que ja toca alterna play/pause em vez de reiniciar.
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
      // Retoma de onde parou, nao do inicio do trecho.
      this.playCurrent({ from: this.elapsedMs() })
    }
  }

  next() {
    if (this.index >= this.queue.length - 1) return
    this.index += 1
    this.playCurrent()
  }

  previous() {
    // Como num player de musica: depois de alguns segundos o "anterior"
    // reinicia o trecho atual em vez de pular para o de tras.
    if (this.elapsedMs() > 3000 || this.index === 0) {
      this.playCurrent()
      return
    }
    this.index -= 1
    this.playCurrent()
  }

  // O range envia input durante o arrasto e change ao soltar: mover o ponteiro
  // so atualiza o rotulo, e o seek de verdade sai uma vez, no fim.
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

  // --- Privado ---

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
    this.render({ title: epic.title, subtitle: epic.subtitle, artwork: epic.artwork, status: from ? null : "Carregando…" })
    this.renderQueuePosition()

    try {
      const token = await this.fetchToken()
      if (!token) return

      if (!this.player) await this.initializePlayer(token)
      await this.startPlayback(token, from)
    } catch (error) {
      this.render({ status: "Erro na reprodução" })
      console.error("Playback error:", error)
    }
  }

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
      volume: this.hasVolumeTarget ? this.volumeTarget.value / 100 : 0.8
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
      this.render({ status: "Não foi possível tocar" })
      return
    }

    this.playing = true
    this.setButton("⏸")
    this.render({ subtitle: epic.subtitle })

    // O Epic e um trecho: para no end_time. Numa fila, o fim de um e o
    // comeco do proximo.
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
      this.render({ status: this.queue.length > 1 ? "Collection terminou" : "Epic terminou" })
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

    // Um Epic avulso nao e uma fila: mostrar "1/1" so faria ruido.
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
