
views = NS "Example.views"

class views.TextBox extends Backbone.View


  events:
    "click .edit": "startEdit"
    "click .delete": "remove"

  constructor: ({name}) ->
    super
    @name = name
    $(@el).addClass "textBox"

    source  = $("#textboxTemplate").html()
    @template = Handlebars.compile source


    $(window).click (e) =>
      if $(e.target).has(@el).size() > 0
        @_offClick(e)

    @_startDrag()

  _offClick: (e) ->
    console.log "off"
    @endEdit()

  startEdit: ->
    @_endDrag()
    @edit.attr "contenteditable", true
    @edit.focus()
    console.log "Start edit"

  endEdit: ->
    @edit.removeAttr "contenteditable"
    @_startDrag()
    console.log "End edit"


  _startDrag: ->
    $(@el).draggable
      cursor: "pointer"

    console.log "Dragging"

  _endDrag: ->
    $(@el).draggable("destroy")
    console.log "end drag"

  render: ->

    $(@el).html @template()

    @edit = @$(".content span")


  # update: ->
  #   console.log "editor: updating model"
  #   @model.set text: @input.val()

