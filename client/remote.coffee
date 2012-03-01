
views = NS "Pahvi.views"
models = NS "Pahvi.models"
helpers = NS "Pahvi.helpers"

class RemoteItem extends Backbone.View

  className: "remoteItem"


  constructor: ({@boardProperties}) ->
    super
    @$el = $ @el

  events:
    "click": "_onTouch"

  _onTouch: ->
    console.log "Setting remoteSelect to #{ @model.id }"
    @boardProperties.set remoteSelect: @model.id

  render: ->
    @$el.html @renderTemplate "remote_item", @model.toJSON()


Pahvi.init (err, settings, boxes, boardProperties) ->

  boxes.forEach (model) ->
    console.log model.id, model.get "name"
    ri = new RemoteItem
      model: model
      boardProperties: boardProperties
    ri.render()
    $("body").append ri.el
