

Pahvi = NS "Pahvi"
views = NS "Pahvi.views"
helpers = NS "Pahvi.helpers"


Pahvi.init (err, settings, boxes, boardProperties) ->

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





  router = new Pahvi.Router
    settings: settings
    collection: boxes

  if window.AUTH_KEY
    menu = new views.Menu
      el: ".menu"
      settings: settings

    menu.render()



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

  boxes.bind "disconnect", ->
    helpers.showFatalError "Server disconnected. Please reload page."


  board = new views.Cardboard
    el: ".pahvi"
    settings: settings
    collection: boxes
    boardProperties: boardProperties

  console.log "Loading views"
  board.bind "viewsloaded", _.once ->
    console.log "Views loaded"
    # TODO: Why on earth this is called twice??
    Backbone.history?.start()
    if not window.AUTH_KEY
      settings.set mode: "presentation"

  board.render()
