import { Controller } from "@hotwired/stimulus"

// Submete o form de busca enquanto a pessoa digita.
//
// O debounce existe porque sem ele cada tecla dispara uma requisicao: numa
// busca de 12 letras seriam 12 idas ao servidor, e as respostas podem chegar
// fora de ordem — a lista acabaria mostrando o resultado de um termo antigo.
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
