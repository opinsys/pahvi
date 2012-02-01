
views = NS "Pahvi.views"
models = NS "Pahvi.models"
configureViews = NS "Pahvi.views.configure"

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
    $(document).bind "dragleave", (e) =>
      e.preventDefault()
    $(document).bind "dragend", (e) =>
      e.preventDefault()
      dragInfo.hide()

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

    options =
      left: e.originalEvent.offsetX + "px"
      top: e.originalEvent.offsetY + "px"

    if type = ui?.draggable.data("boxtype")
      @collection.createBox type, options
    else if file = e.originalEvent?.dataTransfer?.files?[0]
      @imageBoxFromFile file, options

  allowedTypes =
    "image/jpeg": true
    "image/png": true

  imageBoxFromFile: (file, options) ->
    if not allowedTypes[file.type]
      console.log "Unkown file type '#{ file.type }'. Ignoring this file drop."
      return

    if file.size > 2746288
      # TODO: blocking confirm dialog is bad...
      if not confirm "This image is huge. It might crash your browser. Ok?"
        return

    options.imgSrc = "/img/loadingimage.png"

    box = @collection.createBox "image", options

    reader = new FileReader()
    reader.onload = =>
      box.set imgSrc: reader.result, { local: true }
      @uploadImage file, box
    reader.readAsDataURL file

  uploadImage: (file, box, cb=->) ->
    fd = new FormData
    fd.append "imagedata", file
    xhr = new XMLHttpRequest
    xhr.onreadystatechange = (e) =>
      if xhr.readyState is xhr.DONE
        res = JSON.parse xhr.response
        if res.error
          alert "Error while saving image: #{ res.error }"
        else
          box.set imgSrc: res.url
    xhr.open "POST", "/upload"
    xhr.send fd


  render: ->
    @$el.droppable()



