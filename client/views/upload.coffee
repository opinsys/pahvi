
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

    source  = $("#uploadTemplate").html()
    @template = Handlebars.compile source

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

    xhr.upload.onprogress = (e) =>
      console.log "Uploading image: #{ e.loaded } / #{ e.totalSize }"
      @loadedBytes = e.loaded
      @totalBytes = e.totalSize
      @render()

    xhr.onreadystatechange = (e) =>
      if xhr.readyState is xhr.DONE
        res = JSON.parse xhr.response
        if res.error
          alert "Error while saving image: #{ res.error }"
          @error = res.error
          @trigger "uploaderror", @model, res.error, xhr
        else
          @trigger "uploaddone", @model, res.url
          if delaySet
            helpers.loadImage res.url, (err) =>
              throw err if err
              @model.set imgSrc: res.url
          else
            @model.set imgSrc: res.url

    xhr.open "POST", "/upload"
    xhr.send fd

  render: ->
    @$el.html @template
      loadedBytes: @loadedBytes
      totalBytes: @totalBytes
      error: @error

  renderToBody: ->
    @render()
    @$el.appendTo "body"


