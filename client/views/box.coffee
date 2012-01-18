
views = NS "Pahvi.views"


requireMode = (mode) -> (method) -> ->
  if @settings.get("mode") is mode
    return method.apply @, arguments
  else
    undefined




class views.TextBox extends Backbone.View


  className: "box textBox"

  constructor: ({@settings}, position) ->
    super
    @$el = $ @el

    source  = $("#textboxTemplate").html()
    @template = Handlebars.compile source

    @model.bind "change", => @render()


    @settings.bind "change:mode", =>
      if @settings.get("mode") is "presentation"
        @_endDrag()
        @_endEdit()
      if @settings.get("mode") is "edit"
        @startDrag()


    $(window).click (e) =>
      if $(e.target).has(@el).size() > 0
        @_offClick(e)


    $(@el).click => @settings.set activeBox: @model.cid

    @settings.bind "change:activeBox", =>
      if @settings.get("activeBox") is @model.cid
        @$el.addClass "hovering"
      else
        @$el.removeClass "hovering"



  events:
    "click .edit": "startEdit"
    "dblclick": "startEdit"
    "click .delete": "remove"
    "click": "zoom"
    "click button.up": "up"
    "click button.down": "down"

    "dragstop": "saveEdit"
    "resizestop": "saveEdit"



  up: ->
    @model.trigger "pushup", @model

  down: ->
    @model.trigger "pushdown", @model


  zoom: requireMode("presentation") ->
    $(@el).zoomTo()


  _offClick: (e) ->
    @settings.set activeBox: null

    if @settings.get("mode") is "edit"
      @startDrag()
      @saveEdit()

    if @settings.get("mode") is "presentation"
      $("body").zoomTo
        targetSize: 1.0


  startEdit: requireMode("edit") ->
    @_endDrag()
    # @edit.bind "halloactivated", -> console.log "ACTIVEW"
    # @edit.attr "contenteditable", true
    # alert 23234
    # @edit.hallo
    #   editable: true
    #   plugins:
    #     halloformat: {}

    $("span", @el).hallo
      editable: true
      plugins:
        halloformat: {}

    @edit.focus()

    @$el.addClass "editing"

  _endEdit: ->
    # @edit.removeAttr "contenteditable"
    # @edit.hallo editable: false
    @edit.blur()
    $("span", @el).hallo
      editable: false
      plugins:
        halloformat: {}

    @$el.removeClass "editing"

  startDrag: requireMode("edit") ->
    @_endEdit()


    @$el.draggable
      cursor: "pointer"
      # zIndex: @model.get "zIndex"



  saveEdit: ->
    @model.set
      left: @$el.css "left"
      top: @$el.css "top"
      width: @$el.css "width"
      height: @$el.css "height"
      text: @$(".content span").html()
    ,
      silent: true

    @model.save()


  _endDrag: ->
    @$el.draggable "destroy"

  render: ->

    @$el.resizable "destroy"

    $(@el).html @template @model.toJSON()

    $(@el).css
      left: @model.get "left"
      top: @model.get "top"
      width: @model.get "width"
      height: @model.get "height"

    @edit = @$(".content span")

    $(@el).css "z-index",  @model.get "zIndex"
    # $(@el).draggable "option", "zIndex", @model.get("zIndex")
    # console.log "Setting #{ @model.get("name") } zIndex to #{ @model.get("zIndex") }"

    @$el.resizable()



