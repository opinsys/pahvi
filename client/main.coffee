

Pahvi = NS "Pahvi"
views = NS "Pahvi.views"
helpers = NS "Pahvi.helpers"
t = NS "Pahvi.translate"



Pahvi.init (err, settings, boxes, boardProperties) ->


  if err
    helpers.showFatalError "Failed to load this Pahvi. <pre>#{ err.error }: #{ err.message }</pre>"
    return console.log "Error while loading Pahvi", err

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



  if window.AUTH_KEY and boxes._syncDoc.created
    views.showMessage helpers.template "startinfo"
      publicUrl: settings.getPublicURL()
      adminUrl: settings.getAdminURL()



  # router = new Pahvi.Router
  #   settings: settings
  #   collection: boxes

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
      return helpers.showFatalError t "main.authError"

    helpers.showFatalError "Data synchronization error: '#{ err }'."

  boxes.bind "disconnect", ->
    if settings.get("mode") is "presentation"
      helpers.zoomOut()
    scroll(0,0)
    helpers.showFatalError t "main.disconnectError"


  board = new views.Cardboard
    el: ".pasteboard"
    settings: settings
    collection: boxes
    boardProperties: boardProperties

  console.log "Loading views"

  board.bind "viewsloaded", _.once ->
    console.log "Views loaded"
    # TODO: Why on earth this is called twice??

    # Disable router temporarily
    # Backbone.history?.start()



    if not window.AUTH_KEY
      settings.set mode: "presentation"

  board.render()
