import { Controller } from "@hotwired/stimulus"

// Copies the source field's text and says so for a moment.
export default class extends Controller {
  static targets = ["source", "status"]
  static values = { copied: String }

  async copy() {
    await navigator.clipboard.writeText(this.sourceTarget.value)
    this.statusTarget.textContent = this.copiedValue
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => { this.statusTarget.textContent = "" }, 2000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
