
views = NS "Pahvi.views"
configs = NS "Pahvi.configs"
helpers = NS "Pahvi.helpers"


requireMode = (mode) -> (method) -> ->
  if @settings.get("mode") is mode
    return method.apply @, arguments
  else
    undefined



class views.BaseBox extends Backbone.View

  className: "box"

  type: null

  loadAssets: (cb) -> cb()

  constructor: ({@settings}) ->
    @events = _.extend {}, views.BaseBox::events, @events
    super

    @$el = $ @el

    @model.bind "change", => @render()
    @settings.bind "change:mode", =>
      @render()

    @model.bind "destroy", => @remove()

    $(window).click (e) =>
      if $(e.target).has(@el).size() > 0
        @onOffClick(e)

    @settings.bind "change:activeBox", =>
      @$el.removeClass "selected"
      console.log "Removing selected from #{ @model.id }"
      return if not @isActive()
      @$el.addClass "selected"
      if @settings.get("mode") is "presentation"
        @$el.zoomTo()

    @settings.bind "change:hoveredBox", =>
      if @settings.get("hoveredBox") is @model.id
        @$el.addClass "hovering"
      else
        @$el.removeClass "hovering"





  events:
    "click button.up": "up"
    "click button.down": "down"
    "click a": "_onLinkClick"

    "click": "activate"
    "mouseenter": "_onMouseEnter"
    "mouseleave": "_onMouseLeave"

    "click .delete": "_onDeleteButtonClick"
    "dragstart": "activate"
    "resizestop": "_onResizeStop"
    "dragstop": "_onDragStop"

  _onLinkClick: (e) ->
    if @settings.get("mode") is "edit"
      console.log "Preventing link opening in edit mode. Link was #{ $(e.target).attr "href" }"
      e.preventDefault()

  _onMouseEnter: (e) -> @settings.set hoveredBox: @model.id

  _onMouseLeave: (e) -> @settings.set hoveredBox: null

  _onDeleteButtonClick: -> @model.destroy()

  _onRotateStop: (e, ui) -> @model.set rotate: ui.angle.rad


  activate: -> @settings.set activeBox: @model.id

  deactivate: -> @settings.set activeBox: null

  isActive: -> @settings.get("activeBox") is @model.id


  onOffClick: (e) ->
    return unless @isActive()

    @deactivate()

    if @settings.get("mode") is "presentation"
      helpers.zoomOut()

  up: ->
    @model.trigger "pushup", @model

  down: ->
    @model.trigger "pushdown", @model

  _onResizeStop: ->
    @model.set
      width: @$el.css "width"
      height: @$el.css "height"

  _onDragStop: ->
    @model.set
      left: @$el.css "left"
      top: @$el.css "top"

  resizableOptions: {}

  render: ->

    @$el.resizable "destroy"
    @$el.transformable "destroy"
    @$el.draggable "destroy"

    @$el.html @template @model.toJSON()


    @$el.css
      left: @model.get "left"
      top: @model.get "top"
      width: @model.get "width"
      height: @model.get "height"
      "z-index": @model.get "zIndex"
      "background-color": @model.get("backgroundColor") or "white" # XXX

    @$el.setTransform "rotate", @model.get "rotate"

    # We need to activate resizable always after rendering because jQuery UI
    # adds some elements to this widget
    if @settings.get("mode") is "edit"
      @$el.resizable @resizableOptions
      @$el.draggable()
      @$el.transformable
        skewable: false
        scalable: false
        rotatable: true
        rotateStop: => @_onRotateStop.apply this, arguments

    if @settings.get("mode") is "presentation"
      "pass"

    @$el.attr "title", @model.get "id"





class views.PlainBox extends views.BaseBox

  className: "box plainBox"

  type: "plain"


  constructor: ({@settings}) ->
    super

    source  = $("#plainboxTemplate").html()
    @template = Handlebars.compile source



class views.ImageBox extends views.BaseBox

  className: "box imageBox"

  type: "image"

  constructor: ({@settings}) ->
    super

    source  = $("#imageboxTemplate").html()
    @template = Handlebars.compile source


    @model.bind "change:imgSrc", =>
      @updateRatio true


  loadAssets: (cb) ->
    @updateRatio false, cb

  updateRatio: (reset, cb=->) ->
    if not @model.get "imgSrc"
      @resizableOptions = {}
      return

    img = new Image
    img.onload = =>
      ratio = img.width / img.height
      @resizableOptions = aspectRatio: ratio
      if reset
        @model.set
          width: 200
          height: 200 * ratio
      cb()

    img.src = @model.get "imgSrc"




class views.TextBox extends views.BaseBox

  type: "text"

  className: "box textBox"

  constructor: ({@settings}) ->
    super

    source  = $("#textboxTemplate").html()
    @template = Handlebars.compile source


  events:
    "click .edit": "_onEditButtonClick"
    "dblclick": "_onDoubleClick"

  _onEditButtonClick: -> @startEdit()
  _onDoubleClick: -> @startEdit()


  # Find maximun font-size that fits in this widget
  fitFontSize: ->

    maxWidth = parseInt @$el.width()
    maxHeight = parseInt @$el.height()

    prev = null
    do recurse = (min=1, max=1000) =>

      size = Math.round (min + max) / 2

      # Exit condition: Font size did barely change any more. We are down to
      # one pixel precision to optimal size
      if size is prev
        # Go one size back to prevent edge case overflow and be done with it.
        @text.css "font-size", "#{ size - 1 }px"
        return

      prev = size

      # Apply current size
      @text.css "font-size", "#{ size }px"

      # This id convents all elements to inline element for measurement
      @text.attr "id", "fitFontSize"
      currentWidth = parseInt @text.width()
      currentHeight = parseInt @text.height()
      @text.removeAttr "id"

      # Check widget boundaries
      if maxHeight <= currentHeight or maxWidth <= currentWidth
        # Font overflown. Take smaller half
        return recurse min, size
      else
        # Font can be larger. Take bigger half
        return recurse size, max



  _onResizeStop: ->
    super
    @fitFontSize()


  startEdit:  ->

    @$el.addClass "editing"

    lightbox = new views.LightBox
      alwaysOnTop: true
      views: new configs.TextEditor
        model: @model

    lightbox.bind "close", =>
      @$el.removeClass "editing"

    lightbox.renderToBody()


  render: ->
    super

    @$el.css "font-size", @model.get "font-size"
    @$el.css "color", @model.get "textColor"
    @text = @$(".content")
    @text.html @model.get "text"

    @fitFontSize()

