import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkIn", "checkOut", "status", "bookLink", "bookButton"]
  static values = { url: String, roomId: Number }

  check() {
    const checkIn = this.checkInTarget.value
    const checkOut = this.checkOutTarget.value
    if (!checkIn || !checkOut) {
      this.renderStatus(null)
      return
    }
    if (checkOut <= checkIn) {
      this.renderStatus("invalid")
      return
    }

    const params = new URLSearchParams({ check_in: checkIn, check_out: checkOut })
    fetch(`${this.urlValue}?${params}`, { headers: { "Accept": "application/json" } })
      .then((response) => response.json())
      .then((rooms) => this.renderStatus(rooms.some((room) => room.id === this.roomIdValue)))
      .catch(() => this.renderStatus(null))
  }

  renderStatus(available) {
    const status = this.statusTarget
    const link = this.bookLinkTarget
    const button = this.bookButtonTarget

    if (available === null || available === "invalid") {
      status.textContent = available === "invalid" ? "Выезд должен быть позже заезда" : "Проверьте доступность"
      status.className = "text-sm text-slate-500 dark:text-slate-400"
      link.classList.add("hidden")
      button.classList.remove("hidden")
      return
    }

    if (available) {
      status.textContent = "Номер свободен на эти даты"
      status.className = "text-sm font-medium text-emerald-600 dark:text-emerald-400"
      link.href = this.buildBookingUrl()
      link.classList.remove("hidden")
      button.classList.add("hidden")
    } else {
      status.textContent = "Номер занят на эти даты"
      status.className = "text-sm font-medium text-red-600 dark:text-red-400"
      link.classList.add("hidden")
      button.classList.remove("hidden")
    }
  }

  buildBookingUrl() {
    const url = new URL(this.bookLinkTarget.dataset.baseUrl, window.location.origin)
    url.searchParams.set("check_in", this.checkInTarget.value)
    url.searchParams.set("check_out", this.checkOutTarget.value)
    return url.toString()
  }
}
