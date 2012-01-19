

views = NS "Pahvi.views"
models = NS "Pahvi.models"

$ ->

  window.settings = new models.Settings
    name: "settings"

  boxes = new models.Boxes


  menu = new views.Menu
    el: ".menu"
    settings: settings

  menu.render()


  board = new views.Cardboard
    settings: settings
    collection: boxes

  board.render()


  window.sidemenu = new views.SideMenu
    el: ".mediamenu"
    collection: boxes
    settings: settings

  sidemenu.render()


