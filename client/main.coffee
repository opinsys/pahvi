

views = NS "Example.views"
models = NS "Example.models"

$ ->

  window.settings = new models.Settings
    name: "settings"


  menu = new views.Menu
    el: ".menu"
    settings: settings
  menu.render()

  boxes = new models.Boxes
  boxes.bind "add", -> console.log "box added"

  window.layers = new views.Layers
    collection: boxes
    settings: settings

  layers.render()
  $(".media").html layers.el



  parent = $(".pahvi")

  addTextBox = (name) ->
    m = new models.TextBoxModel
      name: name

    boxes.add m

    t = new views.TextBox
      settings: settings
      model: m
      parent: parent

    parent.append t.el

    t.render()
    t.startDrag()


  addTextBox "a"
  addTextBox "b"
  addTextBox "c"
  addTextBox "d"

