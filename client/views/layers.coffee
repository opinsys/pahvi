
views = NS "Pahvi.views"


class views.Layers extends Backbone.View

  className: "bb-layers"

  constructor: ({@settings}) ->
    super
    @$el = $ @el

    @collection.bind [
      "add"
      "destroy"
      "change:name"
      "change:zIndex"
      "change:visible"
    ].join(" "), => @render()

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
    "click .visible input": "onVisibleClick"


  onVisibleClick: (e) ->
    model = @collection.get @boxIdFromParent e.target
    model.set visible: $(e.target).prop "checked"

  addUniqueClass: (id, className) ->
    return if not @items
    @items.removeClass(className)
    if id
      selected = @items.filter(-> $(this).data("id") is id)
      selected.addClass className


  delete: (e, ui) ->
    model = @collection.get @boxIdFromParent e.target
    model.destroy()

  boxIdFromParent: (elem) ->
    $(elem).parents("li").first().data("id")

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
    @collection.updateZIndexes orderedIds


  updateFromSortable: ->
    orderedIds = @sortable.find("li").toArray().map (e) ->
      $(e).data("id")

    orderedIds.reverse()
    @collection.updateZIndexes orderedIds


  render: ->

    boxes = @collection.filter( (m) -> m.id ).map (m) ->
      id: m.id
      name: m.get "name"
      type: m.type
      zIndex: m.get "zIndex"
      visible: m.get "visible"

     # Make sure that the order is correct
    boxes.sort (a, b) -> b.zIndex - a.zIndex

    @$el.html @renderTemplate "layers", boxes: boxes

    @sortable = @$("ul").sortable()

    # Remove orphan tooltips if any
    $(".layersTooltip").remove()

    tipsy = @$(".fancyTooltip").tipsy
      gravity: "e"
      opacity: 1
      className: "layersTooltip"

    @items = @$(".layersSortable li")




