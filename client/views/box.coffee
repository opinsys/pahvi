
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
    @events = _.extend {}, views.BaseBox::events, @events
    super

    @$el = $ @el

    @model.bind "change", => @render()
    @model.bind "destroy", => @remove()

    $(window).click (e) =>
      if $(e.target).has(@el).size() > 0
        @_offClick(e)

    @settings.bind "change:activeBox", =>
      if @isActive()
          @onActivate()
      else
        @onDeactivate()


    @$el.hover =>
      @settings.set hoveredBox: @model.id
    , =>
      @settings.set hoveredBox: null

    @settings.bind "change:hoveredBox", =>
      if @settings.get("hoveredBox") is @model.id
        @$el.addClass "hovering"
      else
        @$el.removeClass "hovering"


    @settings.bind "change:mode", =>

      if @settings.get("mode") is "presentation"
        @startPresentation()

      if @settings.get("mode") is "edit"
        @endPresentation()



  events:
    "click button.up": "up"
    "click button.down": "down"

    "click": "activate"

    "click .delete": "delete"
    "dragstart": "activate"
    "resizestart": "activate"

    "resizestop": "saveEdit"
    "dragstop": "saveEdit"


  startPresentation: ->
    @disableResize()
    @disableDrag()
    @deactivate()


  endPresentation: ->
    @activateResize()
    @activateDrag()

  activateDrag: requireMode("edit") -> @$el.draggable()
  disableDrag: -> @$el.draggable "destroy"

  activateResize: ->
    @$el.resizable()
    @$el.transformable
      skewable: false
      scalable: false
      rotatable: true
      rotateStop: => @onRotateStop.apply this, arguments


  onRotateStop: (e, ui) ->
    @model.set rotate: ui.angle.rad

  disableResize: ->
    @$el.resizable "destroy"
    @$el.transformable "destroy"

  onActivate: ->

    if @settings.get("mode") is "presentation"
      @$el.zoomTo()

    @$el.addClass "selected"


  onDeactivate: ->
    @$el.removeClass "selected"

  activate: ->
    @settings.set activeBox: @model.id

  isActive: ->
    @settings.get("activeBox") is @model.id

  deactivate: ->
    @settings.set activeBox: null

  delete: ->
    @model.destroy()

  _offClick: (e) ->
    return unless @isActive()

    @deactivate()

    if @settings.get("mode") is "edit"
      @saveEdit()

    if @settings.get("mode") is "presentation"
      $("body").zoomTo
        targetSize: 1.0



  up: ->
    @model.trigger "pushup", @model

  down: ->
    @model.trigger "pushdown", @model


  saveEdit: ->
    @model.set
      left: @$el.css "left"
      top: @$el.css "top"
      width: @$el.css "width"
      height: @$el.css "height"
      fontSize: @$el.css "font-size"

  render: ->

    @disableResize()

    @$el.html @template @model.toJSON()

    @$el.css
      left: @model.get "left"
      top: @model.get "top"
      width: @model.get "width"
      height: @model.get "height"
      "z-index": @model.get "zIndex"
      "background-color": @model.get("backgroundColor") or "white" # XXX



    # We need to activate resizable always after rendering because jQuery UI
    # adds some elements to this widget
    if @settings.get("mode") is "edit"
      @activateResize()

    @$el.setTransform "rotate", @model.get "rotate"





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


  events:
    "click .edit": "startEdit"
    "dblclick": "startEdit"

  startPresentation: ->
    super
    @_endEdit()


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
      @activateDrag()


  startEdit:  ->
    @disableDrag()

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

