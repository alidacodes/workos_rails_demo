import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu"]

  toggle(event) {
    event.preventDefault()
    this.menuTarget.classList.toggle("hidden")
  }

  close() {
    this.menuTarget.classList.add("hidden")
  }

  connect() {
    // Close menu when page navigates (handles Turbo)
    this._close = () => this.close()
    document.addEventListener("turbo:visit", this._close)
  }

  disconnect() {
    document.removeEventListener("turbo:visit", this._close)
  }
}
