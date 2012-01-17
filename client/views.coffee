
models = NS "Example.models"
views = NS "Example.views"


requireMode = (mode) -> (method) -> ->
  if @settings.get("mode") is mode
    return method.apply @, arguments
  else
    undefined


class views.Layers extends Backbone.View

  className: "layers"

  constructor: ({@settings}) ->
    super
    source  = $("#layersTemplate").html()
    @template = Handlebars.compile source

    @collection.bind "add", =>

      @updateZIndexes @collection.map (box) -> box.cid


    @collection.bind "pushdown", (box) =>
      console.log "push DOWN", box
      @move box, -1

    @collection.bind "pushup", (box) =>
      console.log "push UP", box
      @move box, 1

    @settings.bind "change:hoverBox", =>
      @$(".layersSortable li").removeClass "hovering"
      if cid = @settings.get "hoverBox"
        console.log cid, @$(".layersSortable li##{ cid }").addClass "hovering"



  events:
    "sortupdate": "updateFromSortable"
    "hover li": "updateHover"

  updateHover: (e) ->
    @settings.set hoverBox: $(e.target).attr "id"

  move: (box, offset) ->

    currentIndex = @collection.indexOf box
    newIndex = currentIndex + offset * -1

    orderedCids = @collection.map (box) -> box.cid

    console.log "#{ box.get "name" } moving from #{ currentIndex } to #{ newIndex }"
    console.log "Before", JSON.stringify orderedCids

    tmp = orderedCids[newIndex]
    orderedCids[newIndex] = box.cid

    orderedCids[currentIndex] = tmp if tmp

    console.log "After", JSON.stringify orderedCids

    orderedCids.reverse()
    @updateZIndexes orderedCids


  updateFromSortable: ->
    console.log "SORT update"
    orderedCids = @sortable.sortable "toArray"
    orderedCids.reverse()
    @updateZIndexes orderedCids


  updateZIndexes: (orderedCids) ->

    for cid, index in orderedCids
      if model = @collection.getByCid cid
        model.set zIndex: index + 100

    @collection.sort()
    @render()



  updateZIndexes: (orderedCids) ->

    for cid, index in orderedCids
      if model = @collection.getByCid cid
        model.set zIndex: index + 100

    @collection.sort()
    @render()


  render: ->
    $(@el).html @template
      boxes: @collection.map (m) ->
        cid: m.cid
        name: m.get "name"
        zIndex: m.get "zIndex"

    console.log "SORT RENDER"


    @sortable = @$("ul").sortable()







class views.TextBox extends Backbone.View


  className: "box textBox"

  constructor: ({@settings}, position) ->
    super
    @$el = $ @el

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


    $(@el).click => @settings.set hoverBox: @model.cid

    @settings.bind "change:hoverBox", =>
      if @settings.get("hoverBox") is @model.cid
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



  up: ->
    @model.trigger "pushup", @model

  down: ->
    @model.trigger "pushdown", @model


  zoom: requireMode("presentation") ->
    $(@el).zoomTo()


  _offClick: (e) ->

    @settings.set hoverBox: null

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

    # @$el.resizable()
    @$el.draggable
      cursor: "pointer"
      # zIndex: @model.get "zIndex"



  saveEdit: ->
    @model.set
      left: $(@el).css "left"
      top: $(@el).css "top"
      text: @$(".content span").html()
    ,
      silent: true

    @model.save()


  _endDrag: ->
    @$el.draggable "destroy"
    # @$el.resizable "destroy"
    $(@el).draggable("destroy")

  render: ->

    $(@el).html @template @model.toJSON()

    $(@el).css
      left: @model.get "left"
      top: @model.get "top"

    @edit = @$(".content span")

    $(@el).css "z-index",  @model.get "zIndex"
    # $(@el).draggable "option", "zIndex", @model.get("zIndex")
    # console.log "Setting #{ @model.get("name") } zIndex to #{ @model.get("zIndex") }"





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



