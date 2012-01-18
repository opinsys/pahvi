
views = NS "Pahvi.views"



class views.Menu extends Backbone.View

  events:
    "click button.modeToggle": "toggle"

  constructor: ({@settings}) ->
    super

    source  = $("#topmenuTemplate").html()
    @template = Handlebars.compile source

    @settings.bind "change:mode", => @render()


  toggle: ->
    if @settings.get("mode") is "edit"
      @settings.set mode: "presentation"
    else
      @settings.set mode: "edit"

  render: ->

    ob = modeName: "Unkown mode"

    if @settings.get("mode") is "edit"
      ob.modeName = "Switch to presentation mode"
      $("body").removeClass "presentation"
      $("body").addClass "edit"

    if @settings.get("mode") is "presentation"
      ob.modeName = "Switch to edit mode"
      $("body").addClass "presentation"
      $("body").removeClass "edit"


    $(@el).html @template ob



