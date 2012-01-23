
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

    @collection.bind "pushdown", (box) => @move box, -1
    @collection.bind "pushup", (box) => @move box, 1


    @settings.bind "change:activeBox", =>
      @$(".layersSortable li").removeClass "selected"
      if id = @settings.get "activeBox"
        @$(".layersSortable li").filter( ->
          $(this).data("id") is id
        ).addClass "selected"


    @settings.bind "change:hoveredBox", =>
      @$(".layersSortable li").removeClass "hovering"
      if id = @settings.get "hoveredBox"
        @$(".layersSortable li").filter( ->
          $(this).data("id") is id
        ).addClass "hovering"



  events:
    "sortupdate": "updateFromSortable"
    "hover li": "onHoverLayer"
    "click li": "onClickLayer"
    "click button.delete": "delete"

  delete: (e, ui) ->
    id = $(e.target).parent("li").attr("id")
    model = @collection.get id
    model.destroy()

  onClickLayer: (e) ->
    @settings.set activeBox: $(e.target).data "id"

  onHoverLayer: (e) ->
    @settings.set hoveredBox: $(e.target).data "id"

  move: (box, offset) ->

    currentIndex = @collection.indexOf box
    newIndex = currentIndex + offset * -1

    orderedIds = @collection.map (box) -> box.id

    console.log "#{ box.get "id" } moving from #{ currentIndex } to #{ newIndex }"
    console.log "Before", JSON.stringify orderedIds

    tmp = orderedIds[newIndex]
    orderedIds[newIndex] = box.id

    orderedIds[currentIndex] = tmp if tmp

    console.log "After", JSON.stringify orderedIds

    orderedIds.reverse()
    @updateZIndexes orderedIds


  updateFromSortable: ->
    console.log "SORT update"
    orderedIds = @sortable.sortable "toArray"
    orderedIds.reverse()
    @updateZIndexes orderedIds


  updateZIndexes: (orderedIds) ->

    for id, index in orderedIds
      if model = @collection.get id
        model.set zIndex: index + 100

    @collection.sort()


  render: ->
    $(@el).html @template
      boxes: @collection.map (m) ->
        id: m.id
        zIndex: m.get "zIndex"

    console.log "SORT RENDER"


    @sortable = @$("ul").sortable()

