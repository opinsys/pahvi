

views = NS "Pahvi.views"
models = NS "Pahvi.models"
helpers = NS "Pahvi.helpers"

class Workspace extends Backbone.Router

  constructor: ({@settings}) ->
    super

    @settings.bind "change:mode", =>
      @navigate @settings.get "mode"

    @settings.bind "change:activeBox", =>
      if boxId = @settings.get "activeBox"
        @navigate "#{ @settings.get "mode" }/#{ escape boxId }"
      else
        @navigate "#{ @settings.get "mode" }"

  routes:
    "": "welcome"
    "/": "welcome"
    "presentation": "presentation"
    "presentation/:name": "presentation"
    "edit": "edit"
    "edit/:name": "edit"


  welcome: ->
    views.showMessage "Welcome to Pahvi!"


  for mode in ["presentation", "edit"] then do (mode) ->
    Workspace::[mode] = (boxName) ->
      @settings.set mode: mode

      if boxName
        @settings.set activeBox: unescape boxName
      else
        @settings.set activeBox: null
        helpers.zoomOut()



$ ->


  settings = new models.Settings
    id: "settings"

  boxes = new models.Boxes



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


  board.loadBoxes ->
    router = new Workspace
      settings: settings
    Backbone.history.start()


