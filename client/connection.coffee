

Pahvi = NS "Pahvi"
views = NS "Pahvi.views"
models = NS "Pahvi.models"
helpers = NS "Pahvi.helpers"


# Init models and ShareJS
Pahvi.createConnection = (start) -> $ ->

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


    async.forEachSeries [miscCollection, boxes], (collection, cb) ->
      console.log "Loading #{ collection.collectionId }"
      collection.fetch
        sharejsDoc: doc
        success: -> cb()
        error: (err) -> cb
          message: "Failed to connect to #{ collection.collectionId } collection"
          error: err
    , (err) ->
        return start err if err

        settings.set activeBox: null

        if not boardProperties = miscCollection.get "boardProperties"
          boardProperties = new Backbone.Model
            id: "boardProperties"
          miscCollection.add boardProperties

        console.log "All loaded. Starting app"
        start null, settings, boxes, boardProperties


