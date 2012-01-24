
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
        @doc.submitOp([{ p:[], oi:[] }])

      @doc.on 'remoteop', (op) =>
        console.log "Cardboard event: remoteop"
        console.log op
        alreadyBoxes = @collection.map (box) =>
          box.get('id')

        for box in @doc.snapshot
          if not _.include(alreadyBoxes, box['id'])
            {Model} = Cardboard.types[box['type']]
            boxModel = new Model id: box['id']
            do (boxModel) =>
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



