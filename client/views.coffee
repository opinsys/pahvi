
views = NS "Example.views"

requireMode = (mode) -> (method) -> ->
  if @settings.get("mode") is mode
    return method.apply @, arguments
  else
    console.log "not allowed call in #{ mode } mode"
    undefined

class views.TextBox extends Backbone.View

  className: "box textBox"

  constructor: ({@name, @settings, position}) ->
    super

    $(@el).css
      left: position.left + "px"
      top: position.top + "px"

    source  = $("#textboxTemplate").html()
    @template = Handlebars.compile source

    @settings.bind "change:mode", =>
      if @settings.get("mode") is "presentation"
        @_endDrag()
        @_endEdit()
      if @settings.get("mode") is "edit"
        @startDrag()


    $(window).click (e) =>
      if $(e.target).has(@el).size() > 0
        @_offClick(e)

  events:
    "click .edit": "startEdit"
    "click .delete": "remove"
    "click": "zoom"

  zoom: requireMode("presentation") ->
    $(@el).zoomTo()


  _offClick: (e) ->
    console.log "off"

    if @settings.get("mode") is "edit"
      @startDrag()

    if @settings.get("mode") is "presentation"
      $("body").zoomTo
        targetSize: 1.0


  startEdit: requireMode("edit") ->
    @_endDrag()
    @edit.attr "contenteditable", true
    @edit.focus()
    console.log "Start edit"

  startDrag: requireMode("edit") ->
    @_endEdit()
    $(@el).draggable
      cursor: "pointer"
    console.log "Dragging"


  _endEdit: ->
    @edit.removeAttr "contenteditable"
    console.log "End edit"

  _endDrag: ->
    $(@el).draggable("destroy")
    console.log "end drag"

  render: ->

    $(@el).html @template()

    @edit = @$(".content span")



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

    if @settings.get("mode") is "presentation"
      ob.modeName = "Switch to edit mode"
      $("body").addClass "presentation"


    $(@el).html @template ob



