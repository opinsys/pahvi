

views = NS "Pahvi.views"
models = NS "Pahvi.models"


$ ->

  window.settings = new models.Settings
    name: "settings"


  menu = new views.Menu
    el: ".menu"
    settings: settings
  menu.render()

  boxes = new models.Boxes
  boxes.bind "add", -> console.log "box added"

  window.sidemenu = new views.SideMenu
    el: ".mediamenu"
    collection: boxes
    settings: settings

  sidemenu.render()


  parent = $(".pahvi")

  addTextBox = (name) ->
    m = new models.TextBoxModel
      name: name

    boxes.add m

    t = new views.TextBox
      settings: settings
      model: m

    parent.append t.el

    t.render()
    t.startDrag()


  addTextBox "a"
  addTextBox "b"
  addTextBox "c"
  addTextBox "d"

