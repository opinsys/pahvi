
views = NS "Pahvi.views"
models = NS "Pahvi.models"
configureViews = NS "Pahvi.views.configure"

class views.Cardboard extends Backbone.View



  constructor: ({@settings}) ->
    super
    @$el = $ @el


    @collection.bind "add", (boxModel) =>

      View = @collection.getView boxModel.type

      boxView = new View
        settings: @settings
        model: boxModel

      boxView.loadAssets =>
        @$el.append boxView.el
        boxView.render()

      @settings.set activeBox: boxModel.id

  events:
    "drop": "dropped"

  dropped: (e, ui) ->
    type = ui.draggable.data("boxtype")
    if type
      @collection.createBox type,
        # TODO: fix initial position
        left: ui.offset.left + "px"
        top: ui.offset.top + "px"


  render: ->
    @$el.droppable()



