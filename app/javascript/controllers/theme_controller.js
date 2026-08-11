import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "hotel-theme"

export default class extends Controller {
  static targets = ["icon"]
  static values = { current: String }

  connect() {
    const saved = localStorage.getItem(STORAGE_KEY)
    if (saved === "light" || saved === "dark") {
      this.apply(saved)
    } else {
      this.apply(window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")
    }
  }

  toggle() {
    const next = document.documentElement.classList.contains("dark") ? "light" : "dark"
    this.apply(next)
    localStorage.setItem(STORAGE_KEY, next)
  }

  apply(theme) {
    document.documentElement.classList.toggle("dark", theme === "dark")
    this.currentValue = theme
  }

  currentValueChanged() {
    if (!this.hasIconTarget) return
    this.iconTarget.innerHTML = this.currentValue === "dark"
      ? '<svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"/></svg>'
      : '<svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"/></svg>'
  }
}
