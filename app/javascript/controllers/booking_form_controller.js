import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkIn", "checkOut", "room", "price"]
  static values = { url: String, exclude: Number }

  connect() {
    this.refreshRooms()
  }

  refreshRooms() {
    const checkIn = this.checkInTarget.value
    const checkOut = this.checkOutTarget.value
    if (!checkIn || !checkOut) return

    const params = new URLSearchParams({ check_in: checkIn, check_out: checkOut })
    if (this.excludeValue) params.append("exclude", this.excludeValue)

    fetch(`${this.urlValue}?${params}`, { headers: { "Accept": "application/json" } })
      .then((response) => response.json())
      .then((rooms) => this.renderRooms(rooms))
      .catch(() => {})
  }

  renderRooms(rooms) {
    const select = this.roomTarget
    const current = select.value
    const currentlyBlocked = current !== "" && !rooms.some((room) => room.id.toString() === current)

    select.innerHTML = ""
    if (rooms.length === 0) {
      const option = document.createElement("option")
      option.value = ""
      option.textContent = "Нет свободных номеров на эти даты"
      select.appendChild(option)
      return
    }

    rooms.forEach((room) => {
      const option = document.createElement("option")
      option.value = room.id
      option.textContent = `${room.label} — ${room.price} ₽`
      select.appendChild(option)
    })

    if (currentlyBlocked) {
      select.value = ""
    } else if (current && [...select.options].some((option) => option.value === current)) {
      select.value = current
    }
  }
}
