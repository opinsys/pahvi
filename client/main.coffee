

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

  $(".closeOpenMediamenuBtn").click (e) ->
    mediamenu = $(".mediamenu")
    if mediamenu.hasClass('open') then mediamenu.removeClass('open').addClass('closed') else if mediamenu.hasClass('closed') then mediamenu.removeClass('closed').addClass('open')
    mediamenu.animate
      right : if parseInt(mediamenu.css('right'),10) is 0 then -mediamenu.outerWidth() else 0


  addTextBox "a"
  addTextBox "b"
  addTextBox "c"
  addTextBox "d"

