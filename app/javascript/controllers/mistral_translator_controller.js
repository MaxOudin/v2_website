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

  translateAll(event) {
    const button = event.currentTarget
    const from = button.dataset.from
    const url = button.dataset.url
    const confirmMessage = button.dataset.confirm

    if (confirmMessage && !confirm(confirmMessage)) {
      return
    }

    // Désactiver le bouton pendant la requête
    button.disabled = true
    const originalText = button.innerHTML
    button.innerHTML = '<span class="animate-spin">⏳</span>'

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": csrfToken,
        "Accept": "application/json"
      },
      body: new URLSearchParams({
        from: from,
        authenticity_token: csrfToken
      })
    })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          const count = data.translated_count || 0
          this.showNotification(
            count > 0 
              ? `${count} champ(s) traduit(s) avec succès !` 
              : "Aucune traduction nécessaire.",
            "success"
          )
          // Recharger la page pour voir les changements
          setTimeout(() => {
            window.location.reload()
          }, 1500)
        } else {
          this.showNotification(data.error || "Erreur lors de la traduction", "error")
        }
      })
      .catch(error => {
        console.error("Erreur:", error)
        this.showNotification("Une erreur est survenue lors de la traduction", "error")
      })
      .finally(() => {
        button.disabled = false
        button.innerHTML = originalText
      })
  }

  handleSuccess(event) {
    // Garder pour compatibilité avec les anciens formulaires si nécessaire
    const [data, status, xhr] = event.detail
    if (data.success && data.translated_text) {
      this.showNotification("Traduction effectuée avec succès !", "success")
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

