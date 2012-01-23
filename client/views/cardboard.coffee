
views = NS "Pahvi.views"
models = NS "Pahvi.models"
configureViews = NS "Pahvi.views.configure"

class views.Cardboard extends Backbone.View



  constructor: ({@settings}) ->
    super
    @$el = $ @el

    # Deselect boxes when changing mode
    @settings.bind "change:mode", =>
      @settings.set activeBox: null


    @collection.bind "add", (boxModel) =>

      View = @collection.getView boxModel.type

      boxView = new View
        settings: @settings
        model: boxModel

      @$el.append boxView.el

      boxView.render()

      @settings.set activeBox: boxModel.id



  open: (cb) ->
    sharejs.open 'pahvi', 'json', (err, doc) =>
      console.log "Create new doc for Cardboard"
      @doc = doc
      if @doc.snapshot == null
        @doc.submitOp([{p:[], od:null, oi:{}}])
      else
        console.log "Create boxes by sharejs"

      @doc.on 'remoteop', (op) =>
        console.log "Cardboard event: remoteop"
        console.log op
        {Model} = Cardboard.types[@doc.snapshot["boxModel"]["type"]]
        boxModel = new Model name: @doc.snapshot["boxModel"]["name"]
        boxModel.open (err) =>
          throw err if err
          @collection.add boxModel

      cb err

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



