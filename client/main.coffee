

views = NS "Example.views"
models = NS "Example.models"

$ ->

  window.settings = new models.Settings
    name: "settings"

  menu = new views.Menu
    el: ".menu"
    settings: settings
  menu.render()


  addTextBox = (name) ->
    m = new models.TextBoxModel
      name: name

    t = new views.TextBox
      settings: settings
      model: m

    $(".pasteboard").append t.el

    t.render()
    t.startDrag()


  addTextBox "first"
  addTextBox "second"

