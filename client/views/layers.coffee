
views = NS "Pahvi.views"


class views.Layers extends Backbone.View

  className: "layers"

  constructor: ({@settings}) ->
    super
    @$el = $ @el
    source  = $("#layersTemplate").html()
    @template = Handlebars.compile source

    @collection.bind "add", =>
      @updateZIndexes @collection.map (box) -> box.cid
      @render()

    @collection.bind "destroy", (box) =>
      @render()


    @collection.bind "pushdown", (box) =>
      console.log "push DOWN", box
      @move box, -1

    @collection.bind "pushup", (box) =>
      console.log "push UP", box
      @move box, 1


    @settings.bind "change:activeBox", =>
      @$(".layersSortable li").removeClass "selected"
      if cid = @settings.get "activeBox"
        @$(".layersSortable li##{ cid }").addClass "selected"



  events:
    "sortupdate": "updateFromSortable"
    "hover li": "updateHover"
    "click button.delete": "delete"

  delete: (e, ui) ->
    cid = $(e.target).parent("li").attr("id")
    model = @collection.getByCid cid
    model.destroy()

  updateHover: (e) ->
    @settings.set activeBox: $(e.target).attr "id"

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


  render: ->
    $(@el).html @template
      boxes: @collection.map (m) ->
        cid: m.cid
        name: m.get "name"
        zIndex: m.get "zIndex"

    console.log "SORT RENDER"


    @sortable = @$("ul").sortable()

