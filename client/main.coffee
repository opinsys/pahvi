

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


  addTextBox = (pos) ->
    t = new views.TextBox
      name: "Testi"
      settings: settings
      position: pos

    $(".pasteboard").append t.el
    t.render()
    t.startDrag()


  addTextBox
    top: 100
    left: 100

  addTextBox
    top: 300
    left: 200
