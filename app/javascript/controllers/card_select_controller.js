// card_select_controller.js
// Steuert die Card-Auswahl im Konfigurator.
//
// Modes:
//   radio          – genau eine Card auswählbar, Auswahl wird sofort gesendet
//   radio-optional – eine oder keine Card auswählbar (Klick auf gewählte = deselect)
//   checkbox       – mehrere Cards auswählbar

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "grid"]
  static values  = { mode: { type: String, default: "radio" } }

  connect() {
    // Cards klickbar machen
    this.cardTargets.forEach(card => {
      card.addEventListener("click", (e) => this.selectCard(e, card))
      card.style.cursor = "pointer"
    })
  }

  selectCard(e, clickedCard) {
    // Verhindere Klick auf Links/Buttons innerhalb der Card
    if (e.target.closest("a, button")) return

    const mode = this.getCardMode(clickedCard)

    if (mode === "checkbox") {
      // Checkbox: toggling
      this.toggleCard(clickedCard)
    } else if (mode === "radio-optional") {
      // Radio optional: Klick auf aktive Card = deselect
      if (clickedCard.classList.contains("is-selected")) {
        this.deselectCard(clickedCard)
      } else {
        this.deselectAllInGroup(clickedCard)
        this.activateCard(clickedCard)
      }
    } else {
      // Standard Radio: immer eine Auswahl
      this.deselectAllInGroup(clickedCard)
      this.activateCard(clickedCard)
    }
  }

  // ── Card Manipulation ─────────────────────────────────────────────────────

  activateCard(card) {
    card.classList.add("is-selected")
    this.syncInput(card, true)
  }

  deselectCard(card) {
    card.classList.remove("is-selected")
    this.syncInput(card, false)
  }

  toggleCard(card) {
    const isSelected = card.classList.contains("is-selected")
    if (isSelected) {
      this.deselectCard(card)
    } else {
      this.activateCard(card)
    }
  }

  deselectAllInGroup(clickedCard) {
    // Deselect alle Cards in derselben Gruppe (data-select-group)
    const group = clickedCard.dataset.selectGroup
    this.cardTargets.forEach(card => {
      if (!group || card.dataset.selectGroup === group || !card.dataset.selectGroup) {
        if (card !== clickedCard) {
          card.classList.remove("is-selected")
          this.syncInput(card, false)
        }
      }
    })
  }

  // ── Input Synchronisierung ────────────────────────────────────────────────

  syncInput(card, selected) {
    const input = card.querySelector("input[type='radio'], input[type='checkbox']")
    if (!input) return

    const isNoSelection = card.dataset.noSelection === "true"

    if (isNoSelection) {
      // "Keine Auswahl"-Card: nichts eintragen
      input.checked = selected
      return
    }

    input.checked = selected
    input.dispatchEvent(new Event("change", { bubbles: true }))
  }

  // ── Hilfsmethoden ─────────────────────────────────────────────────────────

  getCardMode(card) {
    // Card-spezifischer Mode hat Vorrang über Controller-Mode
    return card.dataset.selectMode || this.modeValue
  }
}
