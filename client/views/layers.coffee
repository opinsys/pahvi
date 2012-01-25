
views = NS "Pahvi.views"


class views.Layers extends Backbone.View

  className: "layers"

  constructor: ({@settings}) ->
    super
    @$el = $ @el
    source  = $("#layersTemplate").html()
    @template = Handlebars.compile source

    @collection.bind "add", =>
      @updateZIndexes @collection.map (box) -> box.id
      @render()

    @collection.bind "destroy", (box) => @render()
    @collection.bind "change:name", (box) => @render()

    @collection.bind "pushdown", (box) => @move box, -1
    @collection.bind "pushup", (box) => @move box, 1


    @settings.bind "change:activeBox", =>
      @addUniqueClass @settings.get("activeBox"), "selected"

    @settings.bind "change:hoveredBox", =>
      @addUniqueClass @settings.get("hoveredBox"), "hovering"




  events:
    "sortupdate": "updateFromSortable"
    "click button.delete": "delete"
    "click .layersSortable li": "onClickItem"
    "mouseenter .layersSortable li": "onMouseEnterItem"
    "mouseleave .layersSortable li": "onMouseLeaveItem"


  addUniqueClass: (id, className) ->
    return if not @items
    @items.removeClass(className)
    if id
      selected = @items.filter(-> $(this).data("id") is id)
      selected.addClass className


  delete: (e, ui) ->
    id = $(e.target).parent("li").data("id")
    model = @collection.get id
    model.destroy()


  onMouseEnterItem: (e) ->
    @settings.set hoveredBox: $(e.target).data "id"

  onMouseLeaveItem: (e) ->
    @settings.set hoveredBox: null


  onClickItem: (e) ->
    @settings.set activeBox: $(e.target).data "id"


  move: (box, offset) ->

    currentIndex = @collection.indexOf box
    newIndex = currentIndex + offset * -1

    orderedIds = @collection.map (box) -> box.id

    tmp = orderedIds[newIndex]
    orderedIds[newIndex] = box.id

    orderedIds[currentIndex] = tmp if tmp

    orderedIds.reverse()
    @updateZIndexes orderedIds


  updateFromSortable: ->
    orderedIds = @sortable.find("li").toArray().map (e) ->
      $(e).data("id")

    orderedIds.reverse()
    @updateZIndexes orderedIds


  updateZIndexes: (orderedIds) ->

    for id, index in orderedIds
      if model = @collection.get id
        model.set zIndex: index + 100

    @collection.sort()


  render: ->
    $(@el).html @template
      boxes: @collection.filter( (m) -> m.id ).map (m) ->
        id: m.id
        name: m.get "name"
        type: m.get "type"
        zIndex: m.get "zIndex"

    @sortable = @$("ul").sortable()
    @items = @$(".layersSortable li")




