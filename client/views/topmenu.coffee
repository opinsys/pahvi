
views = NS "Pahvi.views"
t = NS "Pahvi.translate"



class views.Menu extends Backbone.View

  className: "topMenu"


  constructor: ({@settings}) ->
    super
    @$el = $ @el

    @settings.bind "change:mode", => @render()


  events:
    "click button.modeToggle": "toggle"
    "click button.openRemote": "openRemote"

  openRemote: (e) ->
    e.preventDefault()
    window.open @settings.getRemoteURL(), "remote-#{ @settings.pahviId }", [
      "directories=no",
      "titlebar=no",
      "toolbar=no",
      "location=no",
      "status=no",
      "menubar=no",
      "scrollbars=yes",
      "resizable=yes",
      "width=400",
      "height=500",
    ].join(",")


  toggle: ->
    if @settings.get("mode") is "edit"
      @settings.set mode: "presentation"
    else
      @settings.set mode: "edit"

  render: ->

    ob =
      modeName: "Unkown mode"

    if @settings.get("mode") is "edit"
      ob.modeName = t "topmenu.presentation"

    if @settings.get("mode") is "presentation"
      ob.modeName = t "topmenu.edit"
      ob.presentation = true

    @$el.html @renderTemplate "topmenu", ob



