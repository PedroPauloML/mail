$(() => {
  $(document).ready(() => {
    let btn_filter = document.getElementById("filter-gmail-mails")
    let filter_from = document.getElementById("gmail-from")
    let filter_is_unread = document.getElementById("gmail-is-unread")

    btn_filter.onclick = (evt) => fetchMails()
    filter_from.onkeyup = (evt) => {
      if (evt.keyCode == 13) { fetchMails() }
    }
    filter_is_unread.onchange = (evt) => fetchMails()

    fetchMails((succeed = true) => {
      if (succeed) {
        let container_filters = document.getElementById("gmail-filters")
        container_filters.classList.add("d-flex")
        container_filters.classList.remove("d-none")
      }
    })
  })

  function fetchMails(callback = (succeed) => {}) {
    let spinner_table = document.getElementById("gmail-spinner-table")
    let filter_from = document.getElementById("gmail-from")
    let filter_is_unread = document.getElementById("gmail-is-unread")
    let btn_filter = document.getElementById("filter-gmail-mails")

    if (btn_filter && !btn_filter.disabled) {
      let url = new URL(document.location.host + "/inbox.json")

      if (!!filter_from.value) {
        url.searchParams.set("options[q]", `from:${filter_from.value}`)
      }

      if (filter_is_unread.checked) {
        url.searchParams.set(
          "options[q]",
          (url.searchParams.get("options[q]") || "") + ` is:unread`
        )
      }

      $.ajax({
        url: "/gmail_inbox.json" + url.search,
        method: "GET",
        dataType: "json",
        xhr: () => {
          xhr = new window.XMLHttpRequest()

          // Upload progress
          xhr.upload.addEventListener(
            "progress",
            (evt) => {
              if (evt.lengthComputable) {
                let percentComplete = evt.loaded / evt.total
                let xhr_progress_bar = document.getElementById("xhr-progress-bar")
                xhr_progress_bar.style.width = `${percentComplete * 100}%`
              }
            },
            false
          )

          // Download progress
          xhr.addEventListener(
            "progress",
            (evt) => {
              if (evt.lengthComputable) {
                percentComplete = evt.loaded / evt.total
                xhr_progress_bar = document.getElementById("xhr-progress-bar")
                xhr_progress_bar.style.width = `${percentComplete * 100}%`
              }
            },
            false
          )

          return xhr
        },
        beforeSend: () => {
          spinner_table.classList.remove("d-none")
          filter_from.disabled = true
          filter_is_unread.disabled = true
          btn_filter.disabled = true
          console.log("Fetching...")
        },
        success: (response) => {
          console.log("Success...")
          console.log(response)
          table_mails = document.getElementById("gmail-mails")

          table_mails.dataset.nextPageToken = response.next_page_token
          table_mails.tBodies[0].innerHTML = ""

          if (response.data.length > 0) {
            response.data.forEach((mail) => {
              let tr = document.createElement("tr")
              let td_id = document.createElement("td")
              let td_subject = document.createElement("td")
              let td_sender = document.createElement("td")
              let td_received_at = document.createElement("td")

              if (mail.unread) {
                td_id.innerHTML = `<span class="badge badge-primary">NEW</span> ${mail.id}`
              } else {
                td_id.innerText = mail.id
              }
              td_subject.innerText = mail.subject
              td_sender.innerText = mail.from
              td_received_at.innerText = mail.date_formatted

              tr.appendChild(td_id)
              tr.appendChild(td_subject)
              tr.appendChild(td_sender)
              tr.appendChild(td_received_at)

              table_mails.tBodies[0].appendChild(tr)
            })
          } else {
            let tr = document.createElement("tr")
            let td = document.createElement("td")

            td.innerText = "No messages found"
            td.colSpan = 4

            tr.appendChild(td)
            table_mails.tBodies[0].appendChild(tr)
          }

          callback(true)
        },
        error: (err) => {
          callback(false)
          console.log("Error...")
          console.log(err)
        },
        complete: () => {
          let xhr_progress_bar = document.getElementById("xhr-progress-bar")
          if (xhr_progress_bar) {
            setTimeout(() => { xhr_progress_bar.style.width = "0" }, 1000)
          }
          spinner_table.classList.add("d-none")
          filter_from.disabled = false
          filter_is_unread.disabled = false
          btn_filter.disabled = false
          console.log("Fetched...")
        }
      })
    }
  }
})
