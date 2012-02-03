

views = NS "Pahvi.views"
models = NS "Pahvi.models"
helpers = NS "Pahvi.helpers"

# Create model/view/configure mapping of available Box types.  Box Models,
# Views and Configure views are connected together by their `type` property.
# This will go through those and creates `Boxes.types` mapping for them.
# Later this can be used to get corresponding View/Model/CongigureView
typeMapping = {}
typeSources =
  Model: models
  View: views
for metaClassName, namespace of typeSources
  for __, metaClass of namespace when metaClass.prototype?.type
    typeMapping[metaClass.prototype.type] ?= {}
    typeMapping[metaClass.prototype.type][metaClassName] = metaClass






class Workspace extends Backbone.Router

  constructor: ({@settings, @collection}) ->
    super

    @settings.bind "change:mode", =>
      @navigate @settings.get "mode"

    @collection.bind "change:name", (box) =>
      if box.id is  @settings.get "activeBox"
        @navigateToBox box

    @settings.bind "change:activeBox", =>
      if boxId = @settings.get "activeBox"
        box = @collection.get boxId
        @navigateToBox box
      else
        @navigate @settings.get "mode"

  routes:
    "presentation": "presentation"
    "presentation/:name": "presentation"
    "edit": "edit"
    "edit/:name": "edit"



  navigateToBox: (box, trigger) ->
    @navigate "#{ @settings.get "mode" }/#{ escape box.get "name" }", trigger

  for mode in ["presentation", "edit"] then do (mode) ->
    Workspace::[mode] = (boxName) ->

      if mode is "edit" and not window.AUTH_KEY
        return @navigate "presentation", true


      @settings.set mode: mode

      if boxName
        box = @collection.find (box) -> box.get("name") is unescape boxName

      if box
        @settings.set activeBox: box.id
        @navigateToBox box
      else
        @navigate @settings.get "mode"
        if @settings.get("mode") is "presentation"
          @settings.set activeBox: null
          helpers.zoomOut()


$ ->

  settings = new models.Settings
    id: "settings"


  boxes = new models.Boxes [],
    collectionId: "boxes"
    typeMapping: typeMapping
    modelClasses: (Model for __, Model of models when Model::?.type)



  menu = new views.Menu
    el: ".menu"
    settings: settings

  menu.render()


  board = new views.Cardboard
    el: ".pahvi"
    settings: settings
    collection: boxes

  board.render()

  pahviId = window.location.pathname.split("/")[2]
  if not pahviId
    alert "bad url"

  startUpNotification = ->
    return if not window.AUTH_KEY

    uri = parseUri window.location.href
    publicUrl = "#{ uri.protocol }://#{ uri.authority }#{ uri.path }"
    adminUrl = "#{ publicUrl }?auth=#{ window.AUTH_KEY }"

    views.showMessage helpers.template "startinfo"
      publicUrl: publicUrl
      adminUrl: adminUrl



  sidemenu = new views.SideMenu
    el: ".mediamenu"
    collection: boxes
    settings: settings

  sidemenu.render()


  sharejs.open pahviId, "json", (err, doc) =>
    throw err if err

    boxes.fetch
      sharejsDoc: doc
      success: ->
        settings.set activeBox: null

        router = new Workspace
          settings: settings
          collection: boxes
        Backbone.history.start()
        startUpNotification()

      error: ->
        alert "Failed to connect"


