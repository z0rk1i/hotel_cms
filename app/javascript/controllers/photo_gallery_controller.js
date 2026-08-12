import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "slide", "counter", "prevButton", "nextButton"]
  static values = { index: { type: Number, default: 0 } }

  connect() {
    this.onKeydown = (event) => {
      if (event.key === "Escape") this.close()
      if (event.key === "ArrowRight") this.indexValue = this.nextIndex
      if (event.key === "ArrowLeft") this.indexValue = this.previousIndex
    }
  }

  get nextIndex() {
    return (this.indexValue + 1) % this.slideTargets.length
  }

  get previousIndex() {
    return (this.indexValue - 1 + this.slideTargets.length) % this.slideTargets.length
  }

  open(event) {
    this.indexValue = parseInt(event.currentTarget.dataset.photoGalleryIndexParam, 10)
    this.overlayTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    document.addEventListener("keydown", this.onKeydown)
    this.indexValueChanged()
  }

  next() {
    this.indexValue = this.nextIndex
  }

  previous() {
    this.indexValue = this.previousIndex
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this.onKeydown)
  }

  backdropClick(event) {
    if (event.target === event.currentTarget) this.close()
  }

  indexValueChanged() {
    if (this.slideTargets.length === 0) return
    this.slideTargets.forEach((slide, index) => {
      slide.classList.toggle("hidden", index !== this.indexValue)
    })
    this.counterTarget.textContent = `${this.indexValue + 1} / ${this.slideTargets.length}`
    this.prevButtonTarget.disabled = this.slideTargets.length <= 1
    this.nextButtonTarget.disabled = this.slideTargets.length <= 1
  }
}