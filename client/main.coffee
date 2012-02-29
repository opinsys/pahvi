

views = NS "Pahvi.views"
models = NS "Pahvi.models"
helpers = NS "Pahvi.helpers"


class Workspace extends Backbone.Router

  constructor: ({@settings, @collection}) ->
    super

    @settings.bind "change:mode", =>
      if boxId = @settings.get "activeBox"
        box = @collection.get boxId
        @navigateToBox box
      else
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
    "": "root"
    "presentation": "presentation"
    "presentation/:name": "presentation"

  root: ->
    return if not window.AUTH_KEY

    @settings.set mode: "edit"

    return if @shown

    views.showMessage helpers.template "startinfo"
      publicUrl: @settings.getPublicURL()
      adminUrl:  @settings.getAdminURL()
    , true

    @shown = true



  navigateToBox: (box, trigger) ->
    @navigate "#{ @settings.get "mode" }/#{ escape box.get "name" }", trigger

  presentation: (boxName) ->
    @settings.set mode: "presentation"

    if boxName
      box = @collection.find (box) -> box.get("name") is unescape boxName

    if box
      @settings.set activeBox: box.id
      @navigateToBox box
    else
      @settings.set activeBox: null
      helpers.zoomOut()


$ ->


  window.settings = new models.Settings
    id: "settings"

  if not settings.pahviId
    alert "bad url"
    return

  if window.AUTH_KEY
    $("html").removeClass "presentation"
    $("html").addClass "edit"

  settings.bind "change:mode", ->
    settings.set activeBox: null
    if settings.get("mode") is "edit"
      $("html").removeClass "presentation"
      $("html").addClass "edit"

    if settings.get("mode") is "presentation"
      $("html").addClass "presentation"
      $("html").removeClass "edit"

  window.boxes = new models.Boxes [],
    collectionId: "boxes"
    typeMapping: Pahvi.typeMapping
    modelClasses: (Model for __, Model of models when Model::?.type)


  router = new Workspace
    settings: settings
    collection: boxes

  if window.AUTH_KEY
    menu = new views.Menu
      el: ".menu"
      settings: settings

    menu.render()


  board = new views.Cardboard
    el: ".pahvi"
    settings: settings
    collection: boxes

  board.render()

  board.bind "viewsloaded", _.once ->
    # TODO: Why on earth this is called twice??
    Backbone.history?.start()
    if not window.AUTH_KEY
      settings.set mode: "presentation"



  sidemenu = new views.SideMenu
    el: ".mediamenu"
    collection: boxes
    settings: settings

  sidemenu.render()

  linkbox = new views.LinkBox
    el: ".readOnlyLink"
    settings: settings
  linkbox.render()



  boxes.bind "syncerror", (model, method, err) ->
    if err is "forbidden"
      return helpers.showFatalError "Your authentication key is bad. Please check the URL bar and reload this page."

    helpers.showFatalError "Data synchronization error: '#{ err }'."


  sharejs.open settings.pahviId, "json", (err, doc) =>

    if err
      helpers.showFatalError msg = "Failed to connect synchronization server: #{ err.message }"
      console.log msg, err
      return

    # TODO: remove
    if not doc.connection
      helpers.showWarning "Notice for Pahvi devs: Running on bad ShareJS version. Check the docs."
    else
      doc.connection.on "disconnect", ->
        helpers.showFatalError "Server disconnected. Please reload page."


    boxes.fetch
      sharejsDoc: doc
      success: ->
        settings.set activeBox: null

      error: ->
        alert "Failed to connect"


