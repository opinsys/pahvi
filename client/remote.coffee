
views = NS "Pahvi.views"
models = NS "Pahvi.models"
helpers = NS "Pahvi.helpers"

class RemoteItem extends Backbone.View

  className: "remoteItem"

  constructor: ({@boardProperties}) ->
    super
    @$el = $ @el

    @model.bind "destroy", => @remove()

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


Pahvi.init (err, settings, boxes, boardProperties) ->

  boxes.bind "disconnect", ->
    helpers.showFatalError "Server disconnected. Please reload page."

  boxes.bind "syncerror", (model, method, err) ->
    if err is "forbidden"
      return helpers.showFatalError "Your authentication key is bad. Please check the URL bar and reload this page."
    helpers.showFatalError "Data synchronization error: '#{ err }'."

  boxes.forEach (model) ->
    console.log model.id, model.get "name"
    ri = new RemoteItem
      model: model
      boardProperties: boardProperties
    ri.render()
    $("body").append ri.el


