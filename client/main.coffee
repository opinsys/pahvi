

views = NS "Pahvi.views"
models = NS "Pahvi.models"

class Workspace extends Backbone.Router

  constructor: ({@settings}) ->
    super

    @settings.bind "change:mode", =>
      @navigate @settings.get "mode"

    @settings.bind "change:activeBox", =>
      @navigate "#{ @settings.get "mode" }/#{ @settings.get "activeBox" }"

  routes:
    "presentation": "presentation"
    "presentation/:name": "presentation"
    "edit": "edit"

  presentation: (boxName) ->
    @settings.set mode: "presentation"

  edit: ->
    @settings.set mode: "edit"


$ ->


  settings = new models.Settings
    id: "settings"

  boxes = new models.Boxes

  router = new Workspace
    settings: settings


  menu = new views.Menu
    el: ".menu"
    settings: settings

  menu.render()


  board = new views.Cardboard
    el: ".pahvi"
    settings: settings
    collection: boxes

  board.render()


  sidemenu = new views.SideMenu
    el: ".mediamenu"
    collection: boxes
    settings: settings

  sidemenu.render()


  board.loadBoxesFromLocalStorage()
  Backbone.history.start()

  views.showMessage "Welcome to Pahvi!"

