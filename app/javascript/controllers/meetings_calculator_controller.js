// meetings_calculator_controller.js
// Berechnet eine Meeting-Paket-Empfehlung basierend auf Nutzereingaben.
//
// Logik:
//   Meetings/Monat × Personen × 1h (angenommene Dauer) = benötigte Stunden
//   Paket-Empfehlung basiert auf Preis-Tiers (günstigstes das ausreicht)

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["meetings", "persons"]
  static values  = { packages: Array }

  recommend() {
    const meetings = parseInt(this.meetingsTarget.value) || 0
    const persons  = parseInt(this.personsTarget.value)  || 1

    if (meetings === 0) return

    // Einfache Heuristik: Gesamtstunden = Meetings × Personen × 0.5h
    const totalScore = meetings * persons

    // Packages nach Preis sortieren (aufsteigend)
    const sorted = [...this.packagesValue].sort((a, b) => a.price - b.price)

    let recommended = sorted[sorted.length - 1] // Default: größtes Paket

    if (totalScore <= 10) {
      recommended = sorted[0]
    } else if (totalScore <= 30) {
      recommended = sorted[Math.min(1, sorted.length - 1)]
    } else {
      recommended = sorted[sorted.length - 1]
    }

    if (!recommended) return

    // Alle Package-Cards zurücksetzen
    this.resetAllPackages()

    // Empfohlenes Paket hervorheben + auswählen
    const targetCard = document.getElementById(`meeting-pkg-${recommended.id}`)
    if (targetCard) {
      targetCard.classList.add("is-selected")
      const input = targetCard.querySelector("input")
      if (input) input.checked = true

      // Badge "Empfehlung" temporär hinzufügen falls nicht vorhanden
      if (!targetCard.querySelector(".badge-recommended")) {
        const badge = document.createElement("span")
        badge.className = "badge-recommended ms-2"
        badge.textContent = "Empfehlung"
        badge.dataset.dynamicBadge = "true"
        const nameEl = targetCard.querySelector(".conf-card__radio span")
        if (nameEl) nameEl.after(badge)
      }

      // Smooth scroll zur Card
      targetCard.scrollIntoView({ behavior: "smooth", block: "nearest" })
    }
  }

  calculate() {
    // Live-Berechnung während Eingabe (optional visuelles Feedback)
    const meetings = parseInt(this.meetingsTarget.value) || 0
    const persons  = parseInt(this.personsTarget.value)  || 1
    if (meetings > 0 && persons > 0) {
      // Kein auto-recommend bei jedem Keystroke – nur auf Button-Klick
    }
  }

  resetAllPackages() {
    this.packagesValue.forEach(pkg => {
      const card = document.getElementById(`meeting-pkg-${pkg.id}`)
      if (!card) return
      card.classList.remove("is-selected")
      const input = card.querySelector("input")
      if (input) input.checked = false
      // Dynamisch hinzugefügte Badges entfernen
      card.querySelectorAll("[data-dynamic-badge]").forEach(b => b.remove())
    })
  }
}
