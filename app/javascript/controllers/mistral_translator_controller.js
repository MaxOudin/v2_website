// app/javascript/controllers/mistral_translator_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field"]

  connect() {
    // Écouter les réponses AJAX pour mettre à jour les champs
    document.addEventListener("ajax:success", this.handleSuccess.bind(this))
    document.addEventListener("ajax:error", this.handleError.bind(this))
  }

  disconnect() {
    document.removeEventListener("ajax:success", this.handleSuccess.bind(this))
    document.removeEventListener("ajax:error", this.handleError.bind(this))
  }

  handleSuccess(event) {
    const [data, status, xhr] = event.detail
    const button = event.target.closest("form") || event.target

    if (data.success && data.translated_text) {
      // Trouver le champ correspondant
      const fieldName = button.dataset.field
      if (fieldName) {
        // Chercher le champ input ou textarea
        let field = document.querySelector(`[name="${fieldName}"]`)
        
        if (field) {
          if (field.tagName === "TEXTAREA" || field.type === "text" || field.type === "hidden") {
            field.value = data.translated_text
            // Déclencher l'événement input pour que les frameworks réactifs détectent le changement
            field.dispatchEvent(new Event("input", { bubbles: true }))
          }
        } else {
          // Pour les champs ActionText/Trix, chercher l'input hidden
          const hiddenInput = document.querySelector(`input[type="hidden"][name="${fieldName}"]`)
          if (hiddenInput) {
            // Trouver l'éditeur Trix associé
            const trixEditor = hiddenInput.closest("trix-toolbar")?.parentElement?.querySelector("trix-editor")
            if (trixEditor && trixEditor.editor) {
              trixEditor.editor.loadHTML(data.translated_text)
              // Mettre à jour aussi l'input hidden
              hiddenInput.value = data.translated_text
            }
          }
        }
        
        // Afficher un message de succès
        this.showNotification("Traduction effectuée avec succès !", "success")
      } else if (data.success && data.translated_count) {
        // Traduction de tous les champs
        this.showNotification(`${data.translated_count} champ(s) traduit(s) avec succès !`, "success")
        // Recharger la page pour voir les changements
        setTimeout(() => {
          window.location.reload()
        }, 1500)
      }
    }
  }

  handleError(event) {
    const [data, status, xhr] = event.detail
    const errorMessage = data?.error || "Une erreur est survenue lors de la traduction"
    this.showNotification(errorMessage, "error")
  }

  showNotification(message, type) {
    // Créer une notification temporaire
    const notification = document.createElement("div")
    notification.className = `fixed top-4 right-4 z-50 px-4 py-3 rounded-md shadow-lg ${
      type === "success" ? "bg-green-500 text-white" : "bg-red-500 text-white"
    }`
    notification.textContent = message

    document.body.appendChild(notification)

    setTimeout(() => {
      notification.remove()
    }, 3000)
  }
}
