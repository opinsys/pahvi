
views = NS "Pahvi.views"
models = NS "Pahvi.models"
helpers = NS "Pahvi.helpers"

class RemoteItem extends Backbone.View

  className: "remoteItem"


  constructor: ->
    super
    @$el = $ @el

  events:
    "click": "_onTouch"

  _onTouch: ->
    console.log "Setting remoteSelect to #{ @mode.id }"
    @model.set remoteSelect: @model.id

  render: ->
    @$el.html @renderTemplate "remote_item", @model.toJSON()

$ ->
  window.settings = new models.Settings
    id: "settings"

  window.boxes = new models.Boxes [],
    collectionId: "boxes"
    typeMapping: Pahvi.typeMapping
    modelClasses: (Model for __, Model of models when Model::?.type)

  boxes.bind "syncerror", (model, method, err) ->
    if err is "forbidden"
      return helpers.showFatalError "Your authentication key is bad. Please check the URL bar and reload this page."

    helpers.showFatalError "Data synchronization error: '#{ err }'."

  sharejs.open settings.pahviId, "json", (err, doc) =>

    if err
      helpers.showFatalError msg = "Failed to connect synchronization server: #{ err.message }"
      console.log msg, err
      return

    # TODO: remove
    if not doc.connection
      helpers.showWarning "Notice for Pahvi devs: Running on bad ShareJS version. Check the docs."
    else
      doc.connection.on "disconnect", ->
        helpers.showFatalError "Server disconnected. Please reload page."

    boxes.fetch
      sharejsDoc: doc
      success: ->
        settings.set activeBox: null
        boxes.forEach (model) ->
          ri = new RemoteItem
            model: model
          ri.render()
          $("body").append ri.el

      error: ->
        alert "Failed to connect"
