
views = NS "Pahvi.views"


requireMode = (mode) -> (method) -> ->
  if @settings.get("mode") is mode
    return method.apply @, arguments
  else
    undefined



class views.BaseBox extends Backbone.View

  className: "box"

  type: null

  constructor: ({@settings}) ->
    super
    @$el = $ @el

    @model.bind "change", => @render()
    @model.bind "destroy", => @remove()

    $(window).click (e) =>
      if $(e.target).has(@el).size() > 0
        @_offClick(e)


    @settings.bind "change:activeBox", =>
      if @settings.get("activeBox") is @model.cid
        @$el.addClass "selected"
      else
        @$el.removeClass "selected"


    @delegateEvents @baseEvents


  baseEvents:
    "click button.up": "up"
    "click button.down": "down"
    "click": "zoom"

    "click .delete": "delete"
    "click": "activate"
    "dragstart": "activate"

    "resizestop": "saveEdit"
    "dragstop": "saveEdit"

  activate: ->
    @settings.set activeBox: @model.cid

  isActive: ->
    @settings.get("activeBox") is @model.cid

  delete: ->
    @model.destroy()

  _offClick: (e) ->
    return unless @isActive()

    @settings.set activeBox: null

    @$el.resizable()
    @saveEdit()

    if @settings.get("mode") is "presentation"
      $("body").zoomTo
        targetSize: 1.0

  startDrag: requireMode("edit") ->
    @$el.draggable cursor: "pointer"

  endDrag: ->
    @$el.draggable "destroy"

  up: ->
    @model.trigger "pushup", @model

  down: ->
    @model.trigger "pushdown", @model

  zoom: requireMode("presentation") ->
    $(@el).zoomTo()

  saveEdit: ->
    @model.set
      left: @$el.css "left"
      top: @$el.css "top"
      width: @$el.css "width"
      height: @$el.css "height"
      fontSize: @$el.css "font-size"

  render: ->
    @$el.resizable "destroy"

    @$el.html @template @model.toJSON()

    @$el.css
      left: @model.get "left"
      top: @model.get "top"
      width: @model.get "width"
      height: @model.get "height"
      "z-index": @model.get "zIndex"
      "background-color": @model.get("backgroundColor") or "white" # XXX

    @$el.resizable()





class views.PlainBox extends views.BaseBox

  className: "box plainBox"

  type: "plain"

  constructor: ({@settings}) ->
    super

    source  = $("#plainboxTemplate").html()
    @template = Handlebars.compile source

  render: -> super





class views.TextBox extends views.BaseBox

  type: "text"

  className: "box textBox"

  constructor: ({@settings}) ->
    super

    source  = $("#textboxTemplate").html()
    @template = Handlebars.compile source



    @settings.bind "change:mode", =>
      if @settings.get("mode") is "presentation"
        @endDrag()
        @_endEdit()
      if @settings.get("mode") is "edit"
        @_endEdit()
        @startDrag()


  events:
    "click .edit": "startEdit"
    "dblclick": "startEdit"


  # Find maximun font-size that fits in this widget
  fitFontSize: ->

    maxWidth = parseInt @$el.width()
    maxHeight = parseInt @$el.height()

    # Add some safe margins
    maxWidth -= 20
    maxHeight -= 50

    prev = null
    do recurse = (min=6, max=1000) =>

      size = Math.round (min + max) / 2

      # Exit condition: Font size did barely change any more. We are down to
      # one pixel precision to optimal size
      if size is prev
        # Go one size back to prevent edge case overflow and be done with it.
        @edit.css "font-size", "#{ size - 1 }px"
        return

      prev = size

      @edit.css "font-size", "#{ size }px"

      # Check widget boundaries
      if parseInt(@edit.width()) >= maxWidth or parseInt(@edit.height()) >= maxHeight
        # Font overflown. Take smaller half
        return recurse min, size
      else
        # Font can be larger. Take bigger half
        return recurse size, max






  _offClick: (e) ->
    super

    if @settings.get("mode") is "edit"
      @_endEdit()
      @startDrag()


  startEdit: requireMode("edit") ->
    @endDrag()

    $("span", @el).hallo
      editable: true
      plugins:
        halloformat: {}

    @edit.focus()

    @$el.addClass "editing"

  _endEdit: ->
    @edit.blur()
    $(".content span", @el).hallo
      editable: false
      plugins:
        halloformat: {}

    @$el.removeClass "editing"



  saveEdit: ->
    @fitFontSize()
    @model.set text: @$(".content span").html()
    super



  render: ->
    super

    @$el.css "font-size", @model.get "font-size"
    @$el.css "color", @model.get "textColor"
    @edit = @$(".content span")

    @fitFontSize()

