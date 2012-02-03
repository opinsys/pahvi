
views = NS "Pahvi.views"
models = NS "Pahvi.models"
helpers = NS "Pahvi.helpers"

class views.Cardboard extends Backbone.View

  constructor: ({@settings}) ->
    super
    @$el = $ @el



    $(document).bind "dragenter", (e) =>
      e.preventDefault()
      console.log "User is dragging something"
      e.originalEvent.dataTransfer.dropEffect = 'copy'
    $(document).bind "dragover", (e) =>
      e.preventDefault()
      e.originalEvent.dataTransfer.dropEffect = 'copy'
    $(document).bind "dragleave", (e) => e.preventDefault()
    $(document).bind "dragend", (e) => e.preventDefault()

    @collection.bind "syncload", (collection, count) =>

      async.forEach @collection.toArray(), (boxModel, cb) =>
        @_createView boxModel, cb
      , =>
        @trigger "viewsloaded"
        @collection.bind "add", (boxModel) => @_createView boxModel


  _createView: (boxModel, cb=->) ->
    View = @collection.getView boxModel.type

    boxView = new View
      settings: @settings
      model: boxModel

    boxView.loadAssets =>
      @$el.append boxView.el
      boxView.render()
      cb()

    @settings.set activeBox: boxModel.id

  events:
    "drop": "dropped"

  dropped: (e, ui) ->

    options =
      left: e.originalEvent.offsetX + "px"
      top: e.originalEvent.offsetY + "px"

    if type = ui?.draggable.data("boxtype")
      @collection.createBox type, options
    else if file = e.originalEvent?.dataTransfer?.files?[0]
      @imageBoxFromFile file, options


  imageBoxFromFile: (file, options) ->

    options.imgSrc = "/img/loadingimage.gif"
    options.width = 66
    options.height = 66
    box = new models.ImageBox options

    upload = new views.Upload
      model: box
      file: file
    upload.renderToBody()

    if upload.validateFile()
      @collection.add box
      upload.start()



  render: ->
    @$el.droppable()



