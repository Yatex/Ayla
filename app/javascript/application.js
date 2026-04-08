// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

const syncAssistantChannelPanel = () => {
  const forms = document.querySelectorAll("[data-assistant-channel-form]")

  forms.forEach((form) => {
    const radios = Array.from(form.querySelectorAll("[data-assistant-channel-radio]"))
    if (radios.length === 0) return

    const update = () => {
      const selectedRadio = radios.find((radio) => radio.checked)
      const selectedChannel = selectedRadio?.dataset.channel || "telegram"

      form.querySelectorAll("[data-assistant-channel-panel]").forEach((panel) => {
        panel.classList.toggle("is-hidden", panel.dataset.assistantChannelPanel !== selectedChannel)
      })

      form.querySelectorAll("[data-assistant-channel-selected]").forEach((pill) => {
        pill.classList.toggle("is-hidden", pill.dataset.assistantChannelSelected !== selectedChannel)
      })
    }

    radios.forEach((radio) => radio.addEventListener("change", update))
    update()
  })
}

const setupAutosaveForms = () => {
  const forms = document.querySelectorAll("[data-autosave-form]")

  forms.forEach((form) => {
    if (form.dataset.autosaveBound === "true") return
    form.dataset.autosaveBound = "true"

    let timeoutId = null
    let saveController = null

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")

    const submitForm = async () => {
      if (timeoutId) clearTimeout(timeoutId)

      if (saveController) saveController.abort()
      saveController = new AbortController()

      const formData = new FormData(form)
      const method = (form.getAttribute("method") || "post").toUpperCase()

      try {
        await fetch(form.action, {
          method,
          body: formData,
          credentials: "same-origin",
          signal: saveController.signal,
          headers: {
            Accept: "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
            "X-CSRF-Token": csrfToken || ""
          }
        })
      } catch (error) {
        if (error.name !== "AbortError") {
          console.error("Autosave failed", error)
        }
      }
    }

    form.addEventListener("change", (event) => {
      const target = event.target
      if (!(target instanceof HTMLElement)) return
      if (target.matches("[data-autosave-debounce]")) return

      submitForm()
    })

    form.addEventListener("input", (event) => {
      const target = event.target
      if (!(target instanceof HTMLElement)) return
      if (!target.matches("[data-autosave-debounce]")) return

      if (timeoutId) clearTimeout(timeoutId)
      timeoutId = window.setTimeout(() => {
        submitForm()
      }, 500)
    })

    form.addEventListener("blur", (event) => {
      const target = event.target
      if (!(target instanceof HTMLElement)) return
      if (!target.matches("[data-autosave-debounce]")) return

      submitForm()
    }, true)

    form.addEventListener("submit", (event) => {
      event.preventDefault()
      submitForm()
    })
  })
}

document.addEventListener("turbo:load", syncAssistantChannelPanel)
document.addEventListener("turbo:load", setupAutosaveForms)
document.addEventListener("DOMContentLoaded", syncAssistantChannelPanel)
document.addEventListener("DOMContentLoaded", setupAutosaveForms)
