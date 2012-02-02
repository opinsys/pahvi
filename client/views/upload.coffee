
views = NS "Pahvi.views"
helpers = NS "Pahvi.helpers"


class views.Upload extends Backbone.View

  className: "uploadStatus"

  @allowedTypes = 
    "image/jpeg": true
    "image/png": true

  constructor: (options) ->
    super
    @$el = $ @el
    {@file} = options
    @status = "starting"

    @bind "uploaddone", => @remove()


  start: ->

    # Small image. Show it immediately in browser
    if @file.size < 1400000
      reader = new FileReader()
      reader.onload = =>
        @model.set imgSrc: reader.result, { local: true }
        @_upload true
      reader.readAsDataURL @file
    else
      # Huge images can chrash the browser. Send it first to server
      console.log "Huge image! #{ @file.size }"
      @_upload false

  _upload: (delaySet) ->
    fd = new FormData
    fd.append "imagedata", @file
    xhr = new XMLHttpRequest

    started = Date.now()
    @status = "uploading"

    xhr.upload.onprogress = (e) =>
      @loaded = e.loaded / 1024
      @total = e.totalSize / 1024
      @speed = e.loaded / ((Date.now() - started) / 1000) / 1024

      # If upload is done but we have no response. This means that server is
      # resizing the image
      if e.loaded >= e.totalSize - 1
        @status = "Resizing"

      console.log "Uploading image: #{ e.loaded } / #{ e.totalSize }", @speed

      @updateProgress()

    xhr.onreadystatechange = (e) =>
      if xhr.readyState is xhr.DONE
        res = JSON.parse xhr.response
        if res.error
          alert "Error while saving image: #{ res.error }"
          @error = res.error
          @status = "error: #{ @error }"
          @trigger "uploaderror", @model, res.error, xhr
        else
          @status = "done"
          @trigger "uploaddone", @model, res.url
          if delaySet
            helpers.loadImage res.url,  =>
              @model.set imgSrc: res.url
          else
            @model.set imgSrc: res.url

    xhr.open "POST", "/upload"
    xhr.send fd

  render: ->
    @$el.html """
    <div class=progressBar></div>
    <div class=messages></div>
    """
    @messages = @$(".messages")
    @progressBar = @$(".progressBar")


    @progressBar.progressbar
      value: 0

  updateProgress: ->
    @progressBar.progressbar "value", parseInt @loaded / @total * 100
    @messages.html @renderTemplate "upload",
      loaded: helpers.roundNumber @loaded, 2
      total: helpers.roundNumber @total, 2
      speed: helpers.roundNumber @speed, 2
      error: @error
      status: @status

  renderToBody: ->
    @render()
    @$el.appendTo "body"
    @$el.dialog
      title: "Image upload status"
      resizable: false

