

views = NS "Pahvi.views"
models = NS "Pahvi.models"
helpers = NS "Pahvi.helpers"


# Init models and ShareJS
Pahvi.init = (start) -> $ ->

  window.settings = new models.Settings
    id: "settings"

  window.boxes = new models.Boxes [],
    collectionId: "boxes"
    typeMapping: Pahvi.typeMapping
    modelClasses: (Model for __, Model of models when Model::?.type)


  miscCollection = new Backbone.SharedCollection [],
    collectionId: "miscCollection"


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

    async.forEachSeries [miscCollection, boxes], (collection, cb) ->
      console.log "Loading #{ collection.collectionId }"
      collection.fetch
        sharejsDoc: doc
        success: -> cb()
        error: (err) -> cb
          message: "Failed to connect to #{ collection.collectionId } collection"
          error: err
    , (err) ->
        settings.set activeBox: null

        if not boardProperties = miscCollection.get "boardProperties"
          boardProperties = new Backbone.Model
            id: "boardProperties"
          miscCollection.add boardProperties

        console.log "All loaded. Starting app"
        start err, settings, boxes, boardProperties


