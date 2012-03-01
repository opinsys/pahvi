
Pahvi = NS "Pahvi"


class Pahvi.Router extends Backbone.Router

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
