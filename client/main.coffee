

views = NS "Example.views"
models = NS "Example.models"

$ ->

  window.settings = new models.LocalStore
    name: "settings"

  t = new views.TextBox
    name: "Testi"
    settings: settings

  $("body").append t.el
  t.render()
  t.startDrag()



  if window.location.hash is "#zoom"
    settings.set mode: "presentation"
  else
    settings.set mode: "edit"




