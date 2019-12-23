$(document).ready(() => {
  console.log("Hi!")
  $.ajax({
    url: "/inbox.js",
    dataType: "application/json",
    success: (response) => {
      console.log(response)
    },
    error: (err) => { console.log(err) }
  })
})
