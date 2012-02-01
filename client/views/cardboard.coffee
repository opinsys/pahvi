
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


  imageBoxFromFile: (file, options) ->
    if not allowedTypes[file.type]
      console.log "Unkown file type '#{ file.type }'. Ignoring this file drop."
      return

    options.imgSrc = "/img/loadingimage.png"
    box = @collection.createBox "image", options

    # Small image. Show it immediately in browser
    if file.size < 1400000
      reader = new FileReader()
      reader.onload = =>
        box.set imgSrc: reader.result, { local: true }
        @uploadImage
          file: file
          box: box
          delayDisplay: true

      reader.readAsDataURL file
    else
      # Huge images can chrash the browser. Send it first to server
      console.log "Big image! #{ file.size }"
      @uploadImage
        file: file
        box: box
        delayDisplay: false

  uploadImage: ({ file, box, delayDisplay }) ->
    fd = new FormData
    fd.append "imagedata", file
    xhr = new XMLHttpRequest

    xhr.upload.onprogress = (e) =>
      console.log "Uploading image: #{ e.loaded } / #{ e.totalSize }"

    xhr.onreadystatechange = (e) =>
      if xhr.readyState is xhr.DONE
        res = JSON.parse xhr.response
        if res.error
          alert "Error while saving image: #{ res.error }"
        else
          if delayDisplay
            helpers.loadImage res.url, (err) ->
              throw err if err
              box.set imgSrc: res.url
          else
            box.set imgSrc: res.url

    xhr.open "POST", "/upload"
    xhr.send fd


  render: ->
    @$el.droppable()



