import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkIn", "checkOut", "status", "bookLink", "bookButton", "alternatives"]
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
      .then((rooms) => {
        this.availableRooms = rooms
        this.renderStatus(rooms.some((room) => room.id === this.roomIdValue))
      })
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
      this.renderAlternatives([])
      return
    }

    if (available) {
      status.textContent = "Номер свободен на эти даты"
      status.className = "text-sm font-medium text-emerald-600 dark:text-emerald-400"
      link.href = this.buildBookingUrl()
      link.classList.remove("hidden")
      button.classList.add("hidden")
      this.renderAlternatives([])
    } else {
      status.textContent = "Номер занят на эти даты"
      status.className = "text-sm font-medium text-red-600 dark:text-red-400"
      link.classList.add("hidden")
      button.classList.remove("hidden")
      const alternatives = (this.availableRooms || []).filter((room) => room.id !== this.roomIdValue)
      this.renderAlternatives(alternatives)
    }
  }

  renderAlternatives(rooms) {
    const container = this.alternativesTarget
    container.replaceChildren()
    if (!rooms || rooms.length === 0) {
      container.classList.add("hidden")
      return
    }

    container.classList.remove("hidden")
    const title = document.createElement("p")
    title.className = "text-sm font-medium text-slate-700 dark:text-slate-300"
    title.textContent = "Доступные номера на эти даты:"
    container.appendChild(title)

    const list = document.createElement("div")
    list.className = "mt-2 space-y-2"
    rooms.forEach((room) => {
      list.appendChild(this.buildAlternativeCard(room))
    })
    container.appendChild(list)
  }

  buildAlternativeCard(room) {
    const card = document.createElement("a")
    card.href = this.buildBookingUrl(room.id)
    card.className = "flex items-center justify-between gap-3 rounded-lg border border-slate-200 dark:border-slate-700 px-3 py-2 hover:border-indigo-400 dark:hover:border-indigo-500 transition-colors"

    const info = document.createElement("span")
    info.className = "text-sm text-slate-700 dark:text-slate-300"
    info.textContent = `${room.label}${room.capacity ? ` · ${room.capacity} чел.` : ""} · ${room.price} ₽/ночь`

    const button = document.createElement("span")
    button.className = "bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-medium px-3 py-1 rounded-lg shrink-0"
    button.textContent = "Забронировать"

    card.append(info, button)
    return card
  }

  buildBookingUrl(roomId = this.roomIdValue) {
    const url = new URL(`/bookings/new?room_id=${roomId}`, window.location.origin)
    url.searchParams.set("check_in", this.checkInTarget.value)
    url.searchParams.set("check_out", this.checkOutTarget.value)
    return url.toString()
  }
}
