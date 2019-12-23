$(document).ready(() => {
  let spinner_table = document.getElementById("spinner-table")

  $.ajax({
    url: "/inbox.json",
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
      console.log("Fetching...")
    },
    success: (response) => {
      console.log("Success...")
      console.log(response)
      table_mails = document.getElementById("mails")

      table_mails.tBodies[0].innerHTML = ""

      response.inbox.forEach((mail) => {
        let tr = document.createElement("tr")
        let td_id = document.createElement("td")
        let td_subject = document.createElement("td")
        let td_received_at = document.createElement("td")

        td_id.innerText = mail.id
        td_subject.innerText = mail.subject
        td_received_at.innerText = mail.date_formatted

        tr.appendChild(td_id)
        tr.appendChild(td_subject)
        tr.appendChild(td_received_at)

        table_mails.tBodies[0].appendChild(tr)
      })
    },
    error: (err) => {
      console.log("Error...")
      console.log(err)
    },
    complete: () => {
      console.log("Fetched...")
      let xhr_progress_bar = document.getElementById("xhr-progress-bar")
      if (xhr_progress_bar) {
        setTimeout(() => { xhr_progress_bar.style.width = "0" }, 1000)
      }
      spinner_table.classList.add("d-none")
    }
  })
})
