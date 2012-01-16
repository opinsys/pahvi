

views = NS "Example.views"
models = NS "Example.models"

$ ->

  window.settings = new models.LocalStore
    name: "settings"
    defaults:
      mode: "presentation"

  menu = new views.Menu
    el: ".menu"
    settings: settings
  menu.render()



  t = new views.TextBox
    name: "Testi"
    settings: settings

  $("body").append t.el
  t.render()
  t.startDrag()



