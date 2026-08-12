import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkIn", "checkOut", "room", "price", "summary"]
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
    this.cacheRooms(rooms)
    if (rooms.length === 0) {
      const option = document.createElement("option")
      option.value = ""
      option.textContent = "Нет свободных номеров на эти даты"
      select.appendChild(option)
      this.updateTotal()
      return
    }

    rooms.forEach((room) => {
      const option = document.createElement("option")
      option.value = room.id
      option.dataset.price = room.price
      option.dataset.totalPrice = room.total_price
      option.textContent = `${room.label} — ${room.price} ₽/ночь`
      select.appendChild(option)
    })

    if (currentlyBlocked) {
      select.value = ""
    } else if (current && [...select.options].some((option) => option.value === current)) {
      select.value = current
    }
    this.updateTotal()
  }

  cacheRooms(rooms) {
    this._rooms = Array.isArray(rooms) ? rooms : []
  }

  updateTotal() {
    const nights = this.nightCount()
    const option = this.roomTarget.selectedOptions[0]
    if (!option || !option.value || nights === 0) {
      this.hideSummary()
      return
    }

    const total = Number(option.dataset.totalPrice)
    const price = Number(option.dataset.price)
    this.summaryTarget.textContent =
      `Итого за ${nights} ${this.nightsWord(nights)} — ${total} ₽ (${price} ₽/ночь)`
    this.summaryTarget.classList.remove("hidden")
  }

  hideSummary() {
    this.summaryTarget.classList.add("hidden")
  }

  nightCount() {
    const checkIn = new Date(this.checkInTarget.value)
    const checkOut = new Date(this.checkOutTarget.value)
    if (Number.isNaN(checkIn.getTime()) || Number.isNaN(checkOut.getTime()) || checkOut <= checkIn) return 0
    return Math.round((checkOut - checkIn) / 86400000)
  }

  nightsWord(n) {
    const mod10 = n % 10
    const mod100 = n % 100
    if (mod10 === 1 && mod100 !== 11) return "ночь"
    if (mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14)) return "ночи"
    return "ночей"
  }
}
