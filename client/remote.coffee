
views = NS "Pahvi.views"
models = NS "Pahvi.models"
helpers = NS "Pahvi.helpers"



class RemoteItem extends Backbone.View

  className: "remoteItem"

  constructor: ({@boardProperties}) ->
    super
    @$el = $ @el

    @model.bind "destroy", => @remove()
    @model.bind "change", => @render()

    @$el.addClass @model.type

    @boardProperties.bind "change:remoteSelect", =>
      if @model.id is @boardProperties.get "remoteSelect"
        @$el.addClass "selected"
      else
        @$el.removeClass "selected"


  events:
    "click": "_onSelect"



  _onSelect: ->
    console.log "Setting remoteSelect to #{ @model.id }"

    if @model.id is @boardProperties.get "remoteSelect"
      @boardProperties.set remoteSelect: null
    else
      @boardProperties.set remoteSelect: @model.id

  render: ->
    @$el.html @renderTemplate "remote_item",
      name: @model.get "name"
      previewHtml: @model.getPreviewHtml()

    @$("img.imageBoxThumbnail").forceImageSize 100


class Remote extends Backbone.View

  constructor: ({@boardProperties}) ->
    super
    @$el = $ @el
    @collection.bind "add", => @render()

  render: ->
    @$el.empty()
    @collection.forEach (model) =>
      console.log model.id, model.get "name"
      ri = new RemoteItem
        model: model
        boardProperties: @boardProperties
      ri.render()
      @$el.append ri.el

Pahvi.init (err, settings, boxes, boardProperties) ->

  $("a.pahviLink").attr "href", settings.getAdminURL()

  # Open all links in a new window
  $("a").click (e) ->
    e.preventDefault()
    window.open @href

  remote = new Remote
    boardProperties: boardProperties
    collection: boxes
    el: ".remote"

  remote.render()

  if not helpers.isMobile
    setTimeout ->
      helpers.showNotification "Pro Tip: Open this page on your mobile phone #{ settings.getRemoteURL() }"
    , 1000

  boxes.bind "disconnect", ->
    scroll(0,0)
    helpers.showFatalError "Server disconnected. Please reload page."

  for e in [boxes, boardProperties] then do (e) ->
    e.bind "syncerror", (model, method, err) ->
      if err is "forbidden"
        return helpers.showFatalError "Your authentication key is bad. Please check the URL bar and reload this page."
      helpers.showFatalError "Data synchronization error: '#{ err }'."



