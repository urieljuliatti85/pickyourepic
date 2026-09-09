import { Controller } from "@hotwired/stimulus"

// Botao de play de um Epic. Nao toca nada: so pede para a barra global tocar
// (player_bar_controller), que e quem detem o device do SDK.
//
// Um Epic e um intervalo de um track, entao o evento carrega start/end.
export default class extends Controller {
  static values = {
    uri: String,
    startTime: Number,
    endTime: Number,
    title: String,
    subtitle: String
  }

  play() {
    document.dispatchEvent(new CustomEvent("epic:play", {
      detail: {
        uri: this.uriValue,
        startTime: this.startTimeValue,
        endTime: this.endTimeValue,
        title: this.titleValue,
        subtitle: this.subtitleValue
      }
    }))
  }
}
