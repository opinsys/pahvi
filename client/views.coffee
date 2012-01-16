
views = NS "Example.views"

class views.TextBox extends Backbone.View


  events:
    "click .edit": "startEdit"
    "click .delete": "remove"
    "click": "zoom"

  constructor: ({@name, @settings}) ->
    super

    $(@el).addClass "box"
    $(@el).addClass "textBox"

    source  = $("#textboxTemplate").html()
    @template = Handlebars.compile source


    $(window).click (e) =>
      if $(e.target).has(@el).size() > 0
        @_offClick(e)


  zoom: ->
    return unless @settings.get("mode") is "presentation"
    $(@el).zoomTo()


  _offClick: (e) ->
    console.log "off"
    if @settings.get("mode") is "edit"
      @startDrag()

    if @settings.get("mode") is "presentation"
      $("body").zoomTo
        targetSize: 1.0


  startEdit: ->
    @_endDrag()
    @edit.attr "contenteditable", true
    @edit.focus()
    console.log "Start edit"

  startDrag: ->
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


  # update: ->
  #   console.log "editor: updating model"
  #   @model.set text: @input.val()

